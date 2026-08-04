//
//  BlockingProcessInspector.swift
//  Ejectify
//
//  Created by Codex on 03/03/2026.
//

import AppKit
import Foundation
import OSLog
import Darwin // For proc_pidpath

/// Detects processes holding open files on a volume that prevent unmounting.
enum BlockingProcessInspector {

    private static let logger = Logger(
        subsystem: LoggingConfiguration.subsystem,
        category: String(describing: BlockingProcessInspector.self)
    )

    /// Background queue for lsof execution.
    private static let inspectionQueue = DispatchQueue(
        label: "nl.nielsmouthaan.Ejectify.BlockingProcessInspection",
        qos: .userInitiated
    )

    /// Inspects blocking processes locally (user-level lsof).
    static func inspectLocally(
        volumePath: String,
        completion: @escaping @MainActor ([BlockingProcess]) -> Void
    ) {
        inspectionQueue.async {
            let processes = runLsofAndParse(volumePath: volumePath)
            DispatchQueue.main.async {
                completion(processes)
            }
        }
    }

    /// Runs lsof and parses output into BlockingProcess array.
    /// Shared by local app path and privileged helper.
    static func runLsofAndParse(volumePath: String) -> [BlockingProcess] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/lsof")
        process.arguments = ["-t", volumePath]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            logger.error("Failed to run lsof: \(error.localizedDescription, privacy: .public)")
            return []
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }

        let ownPID = ProcessInfo.processInfo.processIdentifier

        let pids: [pid_t] = output
            .components(separatedBy: .newlines)
            .compactMap { line -> pid_t? in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty, let pid = Int32(trimmed) else { return nil }
                return pid
            }
            .filter { $0 != ownPID }

        let uniquePIDs = Array(Set(pids))

        return uniquePIDs.compactMap { pid in
            resolveProcess(pid: pid)
        }
    }

    /// Resolves a PID to a BlockingProcess using proc_pidpath and NSRunningApplication.
    private static func resolveProcess(pid: pid_t) -> BlockingProcess? {
        // Get executable path via proc_pidpath
        let pathBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: Int(MAXPATHLEN))
        defer { pathBuffer.deallocate() }
        let pathLength = proc_pidpath(pid, pathBuffer, UInt32(MAXPATHLEN))
        guard pathLength > 0 else {
            return nil
        }
        let executablePath = String(cString: pathBuffer)
        let name = (executablePath as NSString).lastPathComponent

        // Try to get bundle identifier from NSRunningApplication
        // Note: NSRunningApplication is only available in AppKit, which can be linked in the helper too.
        let bundleIdentifier = NSRunningApplication(processIdentifier: pid)?.bundleIdentifier

        return BlockingProcess(pid: pid, name: name, bundleIdentifier: bundleIdentifier)
    }
}
