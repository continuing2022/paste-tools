import SwiftUI
import ClipboardHistory

@main
struct PasteToolsApp: App {
    private let history: ClipboardHistory

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = support.appendingPathComponent("PasteTools", isDirectory: true)
        let storeURL = directory.appendingPathComponent("clipboard-history.json")
        history = ClipboardHistory(store: FileClipboardHistoryStore(fileURL: storeURL))
    }

    var body: some Scene {
        WindowGroup("Paste Tools") {
            ContentView(entryCount: history.entries.count)
        }
        .defaultSize(width: 320, height: 200)
    }
}

struct ContentView: View {
    let entryCount: Int

    var body: some View {
        VStack(spacing: 12) {
            Text("Paste Tools")
                .font(.title)
            Text("剪贴板历史骨架")
                .foregroundStyle(.secondary)
            Text("当前条目：\(entryCount)")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
