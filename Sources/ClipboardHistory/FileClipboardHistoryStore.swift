import Foundation

public struct FileClipboardHistoryStore: ClipboardHistoryStore, Sendable {
    private let fileURL: URL

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func load() throws -> [ClipboardEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        return try decoder.decode([CodableClipboardEntry].self, from: data).map(\.asEntry)
    }

    public func save(_ entries: [ClipboardEntry]) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(entries.map(CodableClipboardEntry.init))
        try data.write(to: fileURL, options: [.atomic])
    }
}

private struct CodableClipboardEntry: Codable {
    enum Kind: String, Codable {
        case text
        case image
    }

    let id: UUID
    let kind: Kind
    let text: String?
    let imageData: Data?

    init(_ entry: ClipboardEntry) {
        id = entry.id
        switch entry.content {
        case .text(let value):
            kind = .text
            text = value
            imageData = nil
        case .image(let data):
            kind = .image
            text = nil
            imageData = data
        }
    }

    var asEntry: ClipboardEntry {
        switch kind {
        case .text:
            return ClipboardEntry(id: id, content: .text(text ?? ""))
        case .image:
            return ClipboardEntry(id: id, content: .image(imageData ?? Data()))
        }
    }
}
