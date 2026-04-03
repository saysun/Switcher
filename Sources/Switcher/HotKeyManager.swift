import Carbon

private func hotKeyCallback(
    _: EventHandlerCallRef?,
    _: EventRef?,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    HotKeyManager.shared.trigger()
    return noErr
}

final class HotKeyManager {
    static let shared = HotKeyManager()

    private var handlerRef: EventHandlerRef?
    private var hotKeyRef: EventHotKeyRef?
    private var handlerInstalled = false
    var onTrigger: (() -> Void)?

    private init() {}

    /// Register (or re-register) the global hotkey.
    func register(keyCode: UInt32, modifiers: UInt32) {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }

        if !handlerInstalled {
            var eventType = EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            )
            let installStatus = InstallEventHandler(
                GetEventDispatcherTarget(),
                hotKeyCallback,
                1,
                &eventType,
                nil,
                &handlerRef
            )
            if installStatus != noErr {
                NSLog("[Switcher] InstallEventHandler failed: %d", installStatus)
            }
            handlerInstalled = true
        }

        let hotKeyID = EventHotKeyID(signature: OSType(0x53575448), id: 1)
        let regStatus = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        if regStatus != noErr {
            NSLog("[Switcher] RegisterEventHotKey failed: %d (key %u mods %u)", regStatus, keyCode, modifiers)
        }
    }

    func trigger() {
        DispatchQueue.main.async { [weak self] in
            self?.onTrigger?()
        }
    }

    func unregister() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        if let ref = handlerRef {
            RemoveEventHandler(ref)
            handlerRef = nil
            handlerInstalled = false
        }
    }
}
