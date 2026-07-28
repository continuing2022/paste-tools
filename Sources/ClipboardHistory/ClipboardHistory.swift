import Foundation

public enum ClipboardObservation: Equatable, Sendable {
    case text(String)
    case image(Data)
    case ignorable

    /// Normalizes a single clipboard change: file URLs are ignored; image wins over text.
    public static func normalized(
        text: String?,
        imageData: Data?,
        containsFileURL: Bool = false
    ) -> ClipboardObservation {
        if containsFileURL {
            return .ignorable
        }
        if let imageData {
            return .image(imageData)
        }
        if let text {
            return .text(text)
        }
        return .ignorable
    }
}

public enum ClipboardEntryContent: Equatable, Sendable {
    case text(String)
    case image(Data)
}

public struct ClipboardEntry: Equatable, Identifiable, Sendable {
    public let id: UUID
    public let content: ClipboardEntryContent

    public init(id: UUID = UUID(), content: ClipboardEntryContent) {
        self.id = id
        self.content = content
    }
}

public protocol ClipboardHistoryStore: Sendable {
    func load() throws -> [ClipboardEntry]
    func save(_ entries: [ClipboardEntry]) throws
}

public final class InMemoryClipboardHistoryStore: ClipboardHistoryStore, @unchecked Sendable {
    private var entries: [ClipboardEntry]

    public init(entries: [ClipboardEntry] = []) {
        self.entries = entries
    }

    public func load() throws -> [ClipboardEntry] {
        entries
    }

    public func save(_ entries: [ClipboardEntry]) throws {
        self.entries = entries
    }
}

public final class ClipboardHistory: @unchecked Sendable {
    public static let maxEntries = 20

    private let store: any ClipboardHistoryStore
    private var _entries: [ClipboardEntry]

    public var entries: [ClipboardEntry] { _entries }

    public init(store: any ClipboardHistoryStore) {
        self.store = store
        self._entries = (try? store.load()) ?? []
    }

    public func observe(_ observation: ClipboardObservation) {
        switch observation {
        case .ignorable:
            return
        case .text(let value):
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            prepend(content: .text(value))
        case .image(let data):
            prepend(content: .image(data))
        }
    }

    public func deleteEntry(id: UUID) {
        _entries.removeAll { $0.id == id }
        persist()
    }

    public func clearHistory() {
        _entries = []
        persist()
    }

    /// Moves an existing clipboard entry to newest without changing its identity.
    /// Used so a 回贴 write-back observation hits consecutive dedup instead of inserting.
    public func refreshAsNewest(id: UUID) {
        guard let index = _entries.firstIndex(where: { $0.id == id }) else { return }
        let entry = _entries.remove(at: index)
        _entries.insert(entry, at: 0)
        persist()
    }

    private func prepend(content: ClipboardEntryContent) {
        if let newest = _entries.first, newest.content == content {
            _entries.removeFirst()
            _entries.insert(ClipboardEntry(id: newest.id, content: content), at: 0)
        } else {
            _entries.insert(ClipboardEntry(content: content), at: 0)
            if _entries.count > Self.maxEntries {
                _entries = Array(_entries.prefix(Self.maxEntries))
            }
        }
        persist()
    }

    private func persist() {
        try? store.save(_entries)
    }
}
