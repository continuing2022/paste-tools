import Foundation
import Testing
@testable import ClipboardHistory

@Suite("ClipboardHistory")
struct ClipboardHistoryTests {
    @Test("capturing plain text adds a clipboard entry")
    func capturingPlainTextAddsClipboardEntry() {
        let history = ClipboardHistory(store: InMemoryClipboardHistoryStore())
        history.observe(.text("hello"))
        #expect(history.entries.map(\.content) == [.text("hello")])
    }

    @Test("capturing an image adds a clipboard entry")
    func capturingImageAddsClipboardEntry() {
        let image = Data([0x89, 0x50, 0x4E, 0x47])
        let history = ClipboardHistory(store: InMemoryClipboardHistoryStore())
        history.observe(.image(image))
        #expect(history.entries.map(\.content) == [.image(image)])
    }

    @Test("ignorable observations are not recorded")
    func ignorableObservationsAreNotRecorded() {
        let history = ClipboardHistory(store: InMemoryClipboardHistoryStore())
        history.observe(.ignorable)
        #expect(history.entries.isEmpty)
    }

    @Test("empty and whitespace-only text are not recorded")
    func emptyAndWhitespaceOnlyTextAreNotRecorded() {
        let history = ClipboardHistory(store: InMemoryClipboardHistoryStore())
        history.observe(.text(""))
        history.observe(.text("   \n\t  "))
        #expect(history.entries.isEmpty)
    }

    @Test("when text and image arrive together only the image is kept")
    func whenTextAndImageArriveTogetherOnlyImageIsKept() {
        let image = Data([0x01, 0x02])
        let history = ClipboardHistory(store: InMemoryClipboardHistoryStore())
        history.observe(.normalized(text: "caption", imageData: image))
        #expect(history.entries.map(\.content) == [.image(image)])
    }

    @Test("file URL clipboard changes are ignorable even when a path string is present")
    func fileURLClipboardChangesAreIgnorableEvenWhenPathStringIsPresent() {
        let history = ClipboardHistory(store: InMemoryClipboardHistoryStore())
        history.observe(
            .normalized(text: "/Users/me/Documents/report.pdf", imageData: nil, containsFileURL: true)
        )
        #expect(history.entries.isEmpty)
    }

    @Test("consecutive duplicate content refreshes the newest entry instead of adding")
    func consecutiveDuplicateRefreshesNewestInsteadOfAdding() {
        let history = ClipboardHistory(store: InMemoryClipboardHistoryStore())
        history.observe(.text("a"))
        history.observe(.text("b"))
        let idBefore = history.entries[0].id
        history.observe(.text("b"))
        #expect(history.entries.map(\.content) == [.text("b"), .text("a")])
        #expect(history.entries[0].id == idBefore)
        #expect(history.entries.count == 2)
    }

    @Test("the 21st entry drops the oldest by FIFO")
    func twentyFirstEntryDropsOldestByFIFO() {
        let history = ClipboardHistory(store: InMemoryClipboardHistoryStore())
        for i in 1...20 {
            history.observe(.text("item-\(i)"))
        }
        history.observe(.text("item-21"))
        #expect(history.entries.count == 20)
        #expect(history.entries.first?.content == .text("item-21"))
        #expect(history.entries.last?.content == .text("item-2"))
        #expect(!history.entries.contains { $0.content == .text("item-1") })
    }

    @Test("delete entry removes only that clipboard entry")
    func deleteEntryRemovesOnlyThatClipboardEntry() {
        let history = ClipboardHistory(store: InMemoryClipboardHistoryStore())
        history.observe(.text("keep"))
        history.observe(.text("drop"))
        let dropId = history.entries[0].id
        history.deleteEntry(id: dropId)
        #expect(history.entries.map(\.content) == [.text("keep")])
    }

    @Test("clear history removes every clipboard entry")
    func clearHistoryRemovesEveryClipboardEntry() {
        let history = ClipboardHistory(store: InMemoryClipboardHistoryStore())
        history.observe(.text("a"))
        history.observe(.text("b"))
        history.clearHistory()
        #expect(history.entries.isEmpty)
    }

    @Test("persistence round-trip restores clipboard history")
    func persistenceRoundTripRestoresClipboardHistory() throws {
        let store = InMemoryClipboardHistoryStore()
        let history = ClipboardHistory(store: store)
        history.observe(.text("persisted"))
        let image = Data([0xAA])
        history.observe(.image(image))

        let restored = ClipboardHistory(store: store)
        #expect(restored.entries.map(\.content) == [.image(image), .text("persisted")])
    }

    @Test("re-observing the newest clipboard entry does not add another entry")
    func reObservingNewestClipboardEntryDoesNotAddAnotherEntry() {
        let history = ClipboardHistory(store: InMemoryClipboardHistoryStore())
        history.observe(.text("first"))
        history.observe(.text("chosen"))
        #expect(history.entries.count == 2)
        history.observe(.text("chosen"))
        #expect(history.entries.count == 2)
        #expect(history.entries.map(\.content) == [.text("chosen"), .text("first")])
    }

    @Test("refreshing an older clipboard entry as newest preserves count and identity")
    func refreshingOlderClipboardEntryAsNewestPreservesCountAndIdentity() {
        let history = ClipboardHistory(store: InMemoryClipboardHistoryStore())
        history.observe(.text("a"))
        history.observe(.text("b"))
        history.observe(.text("c"))
        let olderId = history.entries[1].id
        history.refreshAsNewest(id: olderId)
        #expect(history.entries.count == 3)
        #expect(history.entries.map(\.content) == [.text("b"), .text("c"), .text("a")])
        #expect(history.entries[0].id == olderId)

        history.observe(.text("b"))
        #expect(history.entries.count == 3)
        #expect(history.entries.map(\.content) == [.text("b"), .text("c"), .text("a")])
        #expect(history.entries[0].id == olderId)
    }
}
