import AppKit
import ClipboardHistory
import Foundation

/// Polls the system pasteboard and maps changes to `ClipboardObservation`.
@MainActor
final class SystemClipboardMonitor {
    private let onObservation: (ClipboardObservation) -> Void
    private var lastChangeCount: Int
    private var timer: Timer?

    init(onObservation: @escaping (ClipboardObservation) -> Void) {
        self.onObservation = onObservation
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    func start() {
        stop()
        let timer = Timer(timeInterval: 0.4, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func poll() {
        let pasteboard = NSPasteboard.general
        let changeCount = pasteboard.changeCount
        guard changeCount != lastChangeCount else { return }
        lastChangeCount = changeCount
        onObservation(Self.observation(from: pasteboard))
    }

    static func observation(from pasteboard: NSPasteboard) -> ClipboardObservation {
        let text = pasteboard.string(forType: .string)
        let imageData = imageData(from: pasteboard)
        // Image wins when both are present (CONTEXT.md). Image *preview* is a later ticket;
        // capturing image bytes here keeps mixed pasteboards from becoming text entries.
        return .normalized(text: text, imageData: imageData)
    }

    private static func imageData(from pasteboard: NSPasteboard) -> Data? {
        if let png = pasteboard.data(forType: .png) {
            return png
        }
        if let tiff = pasteboard.data(forType: .tiff) {
            return tiff
        }
        return nil
    }
}
