//
//  BlockingProcess.swift
//  Ejectify
//
//  Created by Codex on 03/03/2026.
//

import Foundation

/// Represents a process that is preventing a volume from being unmounted.
struct BlockingProcess: Identifiable, Hashable {
    /// System process identifier.
    let pid: pid_t

    /// Executable name as reported by the system (e.g. "Terminal", "mds_stores").
    let name: String

    /// Bundle identifier of the process when available (e.g. "com.apple.Terminal").
    let bundleIdentifier: String?

    var id: pid_t { pid }
}
