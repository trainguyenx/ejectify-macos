//
//  BlockingProcessAlertWindowController.swift
//  Ejectify
//
//  Created by Codex on 03/03/2026.
//

import AppKit
import SwiftUI
import OSLog
import IOKit.pwr_mgt

/// Presents a floating window listing processes that blocked automatic unmounting.
@MainActor
final class BlockingProcessAlertWindowController: NSWindowController, NSWindowDelegate {

    private static let logger = Logger(
        subsystem: LoggingConfiguration.subsystem,
        category: String(describing: BlockingProcessAlertWindowController.self)
    )

    /// Auto-dismiss delay in seconds.
    private static let autoDismissDelay: TimeInterval = 30

    private let hostingView: NSHostingView<BlockingProcessAlertView>
    private var autoDismissTask: Task<Void, Never>?

    /// Callback invoked after the window has closed.
    private let onWindowWillClose: () -> Void

    init(
        failedVolumeNames: [String],
        blockingProcesses: [BlockingProcess],
        onWindowWillClose: @escaping () -> Void
    ) {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: NSZeroSize),
            styleMask: [.closable],
            backing: .buffered,
            defer: false
        )

        self.onWindowWillClose = onWindowWillClose
        self.hostingView = NSHostingView(rootView: BlockingProcessAlertView(
            failedVolumeNames: failedVolumeNames,
            blockingProcesses: blockingProcesses,
            dismissAction: {}     // placeholder, set below
        ))

        super.init(window: window)

        window.isOpaque = false
        window.backgroundColor = .clear
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.delegate = self

        // Rebuild rootView with real actions that reference self
        hostingView.rootView = BlockingProcessAlertView(
            failedVolumeNames: failedVolumeNames,
            blockingProcesses: blockingProcesses,
            dismissAction: { [weak self] in
                self?.window?.close()
            }
        )

        window.contentView = hostingView
        updateWindowSize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Shows the floating window near the top-right of the screen.
    func showFloating() {
        // Wake the screen if it was sleeping
        var assertionID: IOPMAssertionID = 0
        IOPMAssertionDeclareUserActivity("Ejectify Alert" as CFString, kIOPMUserActiveLocal, &assertionID)
        
        guard let window, let screen = NSScreen.main else { return }
        updateWindowSize()

        // Position near top-right, below menu bar
        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size
        let origin = NSPoint(
            x: screenFrame.maxX - windowSize.width - 16,
            y: screenFrame.maxY - windowSize.height - 16
        )
        window.setFrameOrigin(origin)

        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)

        scheduleAutoDismiss()
        Self.logger.log("Blocking process alert shown")
    }

    func windowWillClose(_ notification: Notification) {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        onWindowWillClose()
    }

    private func updateWindowSize() {
        guard let window else { return }
        hostingView.layoutSubtreeIfNeeded()
        let contentSize = hostingView.fittingSize
        window.setContentSize(contentSize)
        window.contentMinSize = contentSize
        window.contentMaxSize = contentSize
    }

    private func scheduleAutoDismiss() {
        autoDismissTask?.cancel()
        autoDismissTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .seconds(Int(Self.autoDismissDelay)))
            } catch {
                return
            }
            self?.window?.close()
        }
    }
}
