import AppKit
import ClipboardHistory
import SwiftUI

@main
struct PasteToolsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Floating ball + history panel are AppKit panels owned by AppDelegate.
        // Settings keeps a SwiftUI scene so the process stays an app.
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var session: PasteToolsSession!
    private var windows: FloatingWindowsController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = support.appendingPathComponent("PasteTools", isDirectory: true)
        let storeURL = directory.appendingPathComponent("clipboard-history.json")
        let history = ClipboardHistory(store: FileClipboardHistoryStore(fileURL: storeURL))

        let session = PasteToolsSession(history: history)
        self.session = session
        session.start()

        let windows = FloatingWindowsController(session: session)
        self.windows = windows
        windows.showFloatingBall()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
