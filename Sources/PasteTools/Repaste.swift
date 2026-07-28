import AppKit
import ApplicationServices
import ClipboardHistory
import Foundation

enum RepasteError: Error {
    case accessibilityPermissionRequired
    case failedToWriteClipboard
    case failedToPostPasteKeystroke
}

@MainActor
enum Repaste {
    private static let keyCodeV: CGKeyCode = 9

    /// Writes the clipboard entry to the system pasteboard.
    static func writeToSystemClipboard(_ content: ClipboardEntryContent) throws {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        switch content {
        case .text(let text):
            guard pasteboard.setString(text, forType: .string) else {
                throw RepasteError.failedToWriteClipboard
            }
        case .image(let data):
            if let image = NSImage(data: data) {
                guard pasteboard.writeObjects([image]) else {
                    throw RepasteError.failedToWriteClipboard
                }
            } else if pasteboard.setData(data, forType: .tiff)
                || pasteboard.setData(data, forType: .png)
            {
                return
            } else {
                throw RepasteError.failedToWriteClipboard
            }
        }
    }

    /// Triggers ⌘V via a synthetic key event. Requires Accessibility trust.
    static func postPasteKeystroke() throws {
        guard AXIsProcessTrusted() else {
            throw RepasteError.accessibilityPermissionRequired
        }
        let source = CGEventSource(stateID: .hidSystemState)
        guard
            let down = CGEvent(keyboardEventSource: source, virtualKey: keyCodeV, keyDown: true),
            let up = CGEvent(keyboardEventSource: source, virtualKey: keyCodeV, keyDown: false)
        else {
            throw RepasteError.failedToPostPasteKeystroke
        }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    /// Clear in-app guidance for enabling Accessibility (辅助功能) for 回贴.
    static func presentAccessibilityGuidance() {
        let alert = NSAlert()
        alert.messageText = "需要辅助功能权限才能回贴"
        alert.informativeText = """
        回贴会写回系统剪贴板并自动发送粘贴（⌘V）。请在「系统设置 → 隐私与安全性 → 辅助功能」中允许 Paste Tools，然后再次点选剪贴板条目。

        内容已写回剪贴板时，你也可以在目标应用中手动按 ⌘V。
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "好")
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
        let opts = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    static func presentWriteFailureGuidance() {
        let alert = NSAlert()
        alert.messageText = "无法写回系统剪贴板"
        alert.informativeText = "回贴未能把该剪贴板条目写回系统剪贴板，请重试。"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "好")
        alert.runModal()
    }

    private static func openAccessibilitySettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.Settings.PrivacySecurity.extension?Privacy_Accessibility",
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
                return
            }
        }
    }
}
