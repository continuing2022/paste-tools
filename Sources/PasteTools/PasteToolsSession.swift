import ClipboardHistory
import Combine
import Foundation

@MainActor
final class PasteToolsSession: ObservableObject {
    @Published private(set) var entries: [ClipboardEntry]
    @Published private(set) var isHistoryPanelOpen = false

    private let history: ClipboardHistory
    private var monitor: SystemClipboardMonitor?

    init(history: ClipboardHistory) {
        self.history = history
        self.entries = history.entries
    }

    func start() {
        let monitor = SystemClipboardMonitor { [weak self] observation in
            self?.handle(observation)
        }
        self.monitor = monitor
        monitor.start()
    }

    func toggleHistoryPanel() {
        isHistoryPanelOpen.toggle()
    }

    func setHistoryPanelOpen(_ open: Bool) {
        isHistoryPanelOpen = open
    }

    /// 回贴: write entry → system clipboard → paste → close history panel.
    /// Entry is refreshed as newest first so the write-back observation hits consecutive dedup.
    func repaste(_ entry: ClipboardEntry) {
        history.refreshAsNewest(id: entry.id)
        entries = history.entries

        do {
            try Repaste.writeToSystemClipboard(entry.content)
        } catch {
            Repaste.presentWriteFailureGuidance()
            return
        }

        do {
            try Repaste.postPasteKeystroke()
            setHistoryPanelOpen(false)
        } catch RepasteError.accessibilityPermissionRequired {
            Repaste.presentAccessibilityGuidance()
        } catch {
            // Keystroke posting failed for a non-permission reason; content is already on the clipboard.
            setHistoryPanelOpen(false)
        }
    }

    private func handle(_ observation: ClipboardObservation) {
        history.observe(observation)
        entries = history.entries
    }
}
