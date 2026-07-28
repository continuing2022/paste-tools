import AppKit
import Combine
import SwiftUI

@MainActor
final class FloatingWindowsController {
    private let session: PasteToolsSession
    private var ballPanel: NSPanel?
    private var historyPanel: NSPanel?
    private var historyPanelDelegate: HistoryPanelDelegate?
    private var cancellables = Set<AnyCancellable>()
    /// Ball frame origin at the start of the current drag (AppKit coords).
    private var ballDragOrigin: NSPoint?

    init(session: PasteToolsSession) {
        self.session = session
    }

    func showFloatingBall() {
        if ballPanel == nil {
            ballPanel = makeBallPanel()
        }
        ballPanel?.orderFrontRegardless()
        observeSession()
        syncHistoryPanelVisibility()
        refreshHistoryContent()
    }

    private func observeSession() {
        guard cancellables.isEmpty else { return }

        session.$isHistoryPanelOpen
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncHistoryPanelVisibility()
            }
            .store(in: &cancellables)

        session.$entries
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshHistoryContent()
            }
            .store(in: &cancellables)
    }

    private func syncHistoryPanelVisibility() {
        if session.isHistoryPanelOpen {
            if historyPanel == nil {
                historyPanel = makeHistoryPanel()
            }
            positionHistoryPanelNearBall()
            refreshHistoryContent()
            historyPanel?.orderFrontRegardless()
        } else {
            historyPanel?.orderOut(nil)
        }
    }

    private func refreshHistoryContent() {
        guard let historyPanel,
              let host = historyPanel.contentView as? NSHostingView<HistoryPanelView>
        else { return }
        host.rootView = makeHistoryPanelView()
    }

    private func makeHistoryPanelView() -> HistoryPanelView {
        HistoryPanelView(
            entries: session.entries,
            onRepaste: { [weak self] entry in
                self?.session.repaste(entry)
            },
            onDeleteEntry: { [weak self] id in
                self?.session.deleteEntry(id: id)
            },
            onClearHistory: { [weak self] in
                self?.session.clearHistory()
            }
        )
    }

    private func makeBallPanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 56, height: 56),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false

        let ball = FloatingBallView(
            onTap: { [weak self] in
                self?.session.toggleHistoryPanel()
            },
            onDragTranslation: { [weak self] translation in
                self?.moveBall(bySwiftUITranslation: translation)
            },
            onDragEnded: { [weak self] in
                self?.endBallDrag()
            }
        )
        let host = NSHostingView(rootView: ball)
        host.frame = NSRect(x: 0, y: 0, width: 56, height: 56)
        panel.contentView = host

        if let screen = NSScreen.main {
            let visible = screen.visibleFrame
            let origin = NSPoint(
                x: visible.maxX - 72,
                y: visible.midY - 28
            )
            panel.setFrameOrigin(origin)
        }

        return panel
    }

    private func moveBall(bySwiftUITranslation translation: CGSize) {
        guard let ballPanel else { return }
        if ballDragOrigin == nil {
            ballDragOrigin = ballPanel.frame.origin
        }
        guard let origin = ballDragOrigin else { return }
        // SwiftUI +y is down; AppKit +y is up.
        var next = NSPoint(
            x: origin.x + translation.width,
            y: origin.y - translation.height
        )
        if let screen = ballPanel.screen ?? NSScreen.main {
            let visible = screen.visibleFrame
            let size = ballPanel.frame.size
            next.x = min(max(next.x, visible.minX), visible.maxX - size.width)
            next.y = min(max(next.y, visible.minY), visible.maxY - size.height)
        }
        ballPanel.setFrameOrigin(next)
        if session.isHistoryPanelOpen {
            positionHistoryPanelNearBall()
        }
    }

    private func endBallDrag() {
        ballDragOrigin = nil
    }

    private func makeHistoryPanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 420),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.title = "历史面板"
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titlebarAppearsTransparent = true
        panel.isReleasedWhenClosed = false

        let host = NSHostingView(rootView: makeHistoryPanelView())
        panel.contentView = host

        let delegate = HistoryPanelDelegate(onClose: { [weak self] in
            self?.session.setHistoryPanelOpen(false)
        })
        historyPanelDelegate = delegate
        panel.delegate = delegate

        return panel
    }

    private func positionHistoryPanelNearBall() {
        guard let historyPanel, let ballPanel, let screen = ballPanel.screen ?? NSScreen.main else {
            return
        }
        let ballFrame = ballPanel.frame
        let size = historyPanel.frame.size
        var origin = NSPoint(
            x: ballFrame.minX - size.width - 12,
            y: ballFrame.midY - size.height / 2
        )
        let visible = screen.visibleFrame
        origin.x = min(max(origin.x, visible.minX + 8), visible.maxX - size.width - 8)
        origin.y = min(max(origin.y, visible.minY + 8), visible.maxY - size.height - 8)
        historyPanel.setFrameOrigin(origin)
    }
}

private final class HistoryPanelDelegate: NSObject, NSWindowDelegate {
    private let onClose: () -> Void

    init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    func windowWillClose(_ notification: Notification) {
        onClose()
    }
}
