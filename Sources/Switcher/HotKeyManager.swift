import Carbon

private enum HotKeyRegistrationID: UInt32 {
    case menu = 1
    case tileLeft = 2
    case tileRight = 3
    case tileTop = 4
    case tileBottom = 5
    case tileMaximize = 6
    case tileQuarterTopLeft = 7
    case tileQuarterTopRight = 8
    case tileQuarterBottomLeft = 9
    case tileQuarterBottomRight = 10
}

private func hotKeyCallback(
    _: EventHandlerCallRef?,
    event: EventRef?,
    _: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event = event else { return noErr }
    var hkID = EventHotKeyID()
    let err = GetEventParameter(
        event,
        UInt32(kEventParamDirectObject),
        UInt32(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hkID
    )
    guard err == noErr else { return noErr }
    HotKeyManager.shared.dispatch(hotKeyID: hkID.id)
    return noErr
}

final class HotKeyManager {
    static let shared = HotKeyManager()

    private var handlerRef: EventHandlerRef?
    private var hotKeyRefs: [EventHotKeyRef] = []
    private var handlerInstalled = false

    var onMenuTrigger: (() -> Void)?
    var onTile: ((WindowTileRegion) -> Void)?

    private init() {}

    /// Registers menu + window-tile shortcuts from persisted config.
    func registerFromPersistedConfig() {
        clearRegisteredHotKeys()
        ensureHandlerInstalled()

        let menu = ConfigStore.shared.shortcut
        let tiles = ConfigStore.shared.windowTileShortcuts

        registerHotKey(id: HotKeyRegistrationID.menu.rawValue, shortcut: menu)
        registerHotKey(id: HotKeyRegistrationID.tileLeft.rawValue, shortcut: tiles.left)
        registerHotKey(id: HotKeyRegistrationID.tileRight.rawValue, shortcut: tiles.right)
        registerHotKey(id: HotKeyRegistrationID.tileTop.rawValue, shortcut: tiles.top)
        registerHotKey(id: HotKeyRegistrationID.tileBottom.rawValue, shortcut: tiles.bottom)
        registerHotKey(id: HotKeyRegistrationID.tileMaximize.rawValue, shortcut: tiles.maximize)
        registerHotKey(id: HotKeyRegistrationID.tileQuarterTopLeft.rawValue, shortcut: tiles.quarterTopLeft)
        registerHotKey(id: HotKeyRegistrationID.tileQuarterTopRight.rawValue, shortcut: tiles.quarterTopRight)
        registerHotKey(id: HotKeyRegistrationID.tileQuarterBottomLeft.rawValue, shortcut: tiles.quarterBottomLeft)
        registerHotKey(id: HotKeyRegistrationID.tileQuarterBottomRight.rawValue, shortcut: tiles.quarterBottomRight)
    }

    private func registerHotKey(id: UInt32, shortcut sc: ShortcutConfig) {
        guard sc.modifiers != 0 else { return }
        var ref: EventHotKeyRef?
        let hid = EventHotKeyID(signature: OSType(0x53575448), id: id)
        let st = RegisterEventHotKey(
            sc.keyCode,
            sc.modifiers,
            hid,
            GetEventDispatcherTarget(),
            0,
            &ref
        )
        if st == noErr, let r = ref {
            hotKeyRefs.append(r)
        } else {
            NSLog("[Switcher] RegisterEventHotKey failed: %d (id %u key %u mods %u)", st, id, sc.keyCode, sc.modifiers)
        }
    }

    func dispatch(hotKeyID id: UInt32) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch id {
            case HotKeyRegistrationID.menu.rawValue:
                self.onMenuTrigger?()
            case HotKeyRegistrationID.tileLeft.rawValue:
                self.onTile?(.left)
            case HotKeyRegistrationID.tileRight.rawValue:
                self.onTile?(.right)
            case HotKeyRegistrationID.tileTop.rawValue:
                self.onTile?(.top)
            case HotKeyRegistrationID.tileBottom.rawValue:
                self.onTile?(.bottom)
            case HotKeyRegistrationID.tileMaximize.rawValue:
                self.onTile?(.maximize)
            case HotKeyRegistrationID.tileQuarterTopLeft.rawValue:
                self.onTile?(.quarterTopLeft)
            case HotKeyRegistrationID.tileQuarterTopRight.rawValue:
                self.onTile?(.quarterTopRight)
            case HotKeyRegistrationID.tileQuarterBottomLeft.rawValue:
                self.onTile?(.quarterBottomLeft)
            case HotKeyRegistrationID.tileQuarterBottomRight.rawValue:
                self.onTile?(.quarterBottomRight)
            default:
                break
            }
        }
    }

    private func clearRegisteredHotKeys() {
        for ref in hotKeyRefs {
            UnregisterEventHotKey(ref)
        }
        hotKeyRefs.removeAll()
    }

    private func ensureHandlerInstalled() {
        guard !handlerInstalled else { return }
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

    /// Removes all global hotkeys and the Carbon handler (e.g. while rename panel is key).
    func unregister() {
        clearRegisteredHotKeys()
        if let ref = handlerRef {
            RemoveEventHandler(ref)
            handlerRef = nil
            handlerInstalled = false
        }
    }
}
