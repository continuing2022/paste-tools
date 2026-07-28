import AppKit
import Carbon
import Foundation

/// Registers a system-wide hotkey via Carbon (no Accessibility required for the hotkey itself).
final class GlobalHotKey: @unchecked Sendable {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private let hotKeyID: EventHotKeyID

    /// Default: ⌘⇧V — common for clipboard managers, usually free of system bindings.
    static let defaultKeyCode = UInt32(kVK_ANSI_V)
    static let defaultModifiers = UInt32(cmdKey | shiftKey)

    private static let lock = NSLock()
    /// Protected by `lock`; Carbon callbacks are not MainActor-isolated.
    nonisolated(unsafe) private static var handlers: [UInt32: () -> Void] = [:]

    private(set) var isRegistered = false

    init(onPressed: @escaping @MainActor () -> Void) {
        let id: UInt32 = 1
        self.hotKeyID = EventHotKeyID(signature: OSType(0x5054_5321), id: id) // 'PTS!'
        Self.lock.lock()
        Self.handlers[id] = {
            Task { @MainActor in
                onPressed()
            }
        }
        Self.lock.unlock()

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, _ in
                var pressedID = EventHotKeyID()
                let err = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &pressedID
                )
                guard err == noErr else { return err }
                GlobalHotKey.lock.lock()
                let handler = GlobalHotKey.handlers[pressedID.id]
                GlobalHotKey.lock.unlock()
                handler?()
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )
        guard status == noErr else { return }

        var ref: EventHotKeyRef?
        let registerStatus = RegisterEventHotKey(
            Self.defaultKeyCode,
            Self.defaultModifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &ref
        )
        if registerStatus == noErr {
            hotKeyRef = ref
            isRegistered = true
        }
    }

    @MainActor
    static func presentRegistrationFailureGuidance() {
        let alert = NSAlert()
        alert.messageText = "无法注册全局快捷键"
        alert.informativeText = """
        Paste Tools 未能注册 ⌘⇧V 用于切换历史面板。可能与其他应用的快捷键冲突。

        你仍可用悬浮球打开或关闭历史面板。
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "好")
        alert.runModal()
    }

    deinit {
        Self.lock.lock()
        Self.handlers.removeValue(forKey: hotKeyID.id)
        Self.lock.unlock()
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
}
