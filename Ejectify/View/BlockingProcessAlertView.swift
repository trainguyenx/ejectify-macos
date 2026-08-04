//
//  BlockingProcessAlertView.swift
//  Ejectify
//
//  Created by Codex on 03/03/2026.
//

import SwiftUI
import AppKit

/// Floating alert showing processes that blocked automatic unmounting.
struct BlockingProcessAlertView: View {

    /// Volume names that failed to unmount.
    let failedVolumeNames: [String]

    /// Processes detected as blocking the unmount.
    let blockingProcesses: [BlockingProcess]

    /// Action invoked when the user clicks "Dismiss".
    let dismissAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundStyle(.yellow)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Unmount Failed")
                        .font(.headline)
                    Text(volumeSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Process list
            if blockingProcesses.isEmpty {
                Text("Could not identify blocking processes.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                Text(failedVolumeNames.count == 1 ? LocalizedStringKey("The following processes are using this volume:") : LocalizedStringKey("The following processes are using these volumes:"))
                    .font(.callout)

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(blockingProcesses) { process in
                            HStack(spacing: 8) {
                                processIcon(for: process)
                                    .frame(width: 20, height: 20)
                                Text(process.name)
                                    .font(.callout)
                                Spacer()
                                Text("PID \(process.pid)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                .frame(maxHeight: 200)
            }

            // Actions
            HStack {
                Spacer()
                Button("Dismiss") {
                    dismissAction()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 380)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.background.opacity(0.8))
                )
        }
    }

    /// Builds a summary string of failed volume names.
    private var volumeSummary: String {
        failedVolumeNames.joined(separator: ", ")
    }

    /// Resolves a process icon from its bundle identifier or falls back to a system icon.
    @ViewBuilder
    private func processIcon(for process: BlockingProcess) -> some View {
        if let bundleIdentifier = process.bundleIdentifier,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier),
           let icon = NSWorkspace.shared.icon(forFile: appURL.path) as NSImage? {
            Image(nsImage: icon)
                .resizable()
        } else {
            Image(systemName: "gearshape.fill")
                .foregroundStyle(.secondary)
        }
    }
}
