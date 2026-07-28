import AppKit
import ClipboardHistory
import Foundation
import UniformTypeIdentifiers

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
        // Files are ignorable even when a path string is also present (CONTEXT.md).
        return .normalized(
            text: text,
            imageData: imageData,
            containsFileURL: containsFileURL(pasteboard)
        )
    }

    private static func containsFileURL(_ pasteboard: NSPasteboard) -> Bool {
        if pasteboard.availableType(from: [.fileURL]) != nil {
            return true
        }
        // Legacy Finder filenames pasteboard type.
        let filenamesType = NSPasteboard.PasteboardType("NSFilenamesPboardType")
        if pasteboard.propertyList(forType: filenamesType) != nil {
            return true
        }
        return false
    }

    private static let imagePasteboardTypes: [NSPasteboard.PasteboardType] = [
        .png,
        .tiff,
        NSPasteboard.PasteboardType(UTType.jpeg.identifier),
        NSPasteboard.PasteboardType(UTType.gif.identifier),
    ]

    private static func imageData(from pasteboard: NSPasteboard) -> Data? {
        for type in imagePasteboardTypes {
            if let data = pasteboard.data(forType: type), !data.isEmpty {
                return data
            }
        }
        return nil
    }
}
