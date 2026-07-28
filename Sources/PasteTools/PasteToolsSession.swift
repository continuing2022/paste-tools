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

    private func handle(_ observation: ClipboardObservation) {
        history.observe(observation)
        entries = history.entries
    }
}
