import AppKit
import Carbon

final class StatusBarManager: NSObject, NSMenuDelegate {
    private let statusItem: NSStatusItem
    private let spaceManager = SpaceManager.shared
    private let store = SpaceNameStore.shared
    private let config = ConfigStore.shared
    private var renamePanel: RenamePanel?
    private var shortcutPanel: ShortcutPanel?
    private var menuKeyMonitor: Any?

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
            if let img = NSImage(systemSymbolName: "desktopcomputer", accessibilityDescription: "Switcher") {
                img.isTemplate = true
                button.image = img
                button.imagePosition = .imageLeading
            }
        }

        syncAndRefresh()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        HotKeyManager.shared.onTrigger = { [weak self] in
            self?.statusItem.button?.performClick(nil)
        }
        registerCurrentShortcut()
    }

    private func registerCurrentShortcut() {
        let sc = config.shortcut
        HotKeyManager.shared.register(keyCode: sc.keyCode, modifiers: sc.modifiers)
    }

    // MARK: - Sync & Refresh

    private func syncAndRefresh() {
        let spaceIDs = spaceManager.desktopSpaceIDs()
        store.syncOrder(spaceIDs)
        updateTitle(spaceIDs: spaceIDs)
        rebuildMenu(spaceIDs: spaceIDs)
    }

    // MARK: - Title

    private static let appDisplayName = "Switcher"

    /// Menu bar label: desktop name, or app name when unknown; normalize common lowercase "switcher".
    private func menuBarLabel(forSpaceID spaceID: Int, position: Int) -> String {
        let raw = store.name(forSpaceID: spaceID, position: position)
        if raw.caseInsensitiveCompare(Self.appDisplayName) == .orderedSame {
            return Self.appDisplayName
        }
        return raw
    }

    private func updateTitle(spaceIDs: [Int]) {
        guard let index = spaceManager.activeDesktopIndex(),
              index >= 1, index <= spaceIDs.count else {
            statusItem.button?.title = Self.appDisplayName
            return
        }
        let spaceID = spaceIDs[index - 1]
        statusItem.button?.title = menuBarLabel(forSpaceID: spaceID, position: index)
    }

    // MARK: - Menu

    private func rebuildMenu(spaceIDs: [Int]) {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let activeID = spaceManager.activeSpaceID()

        if spaceIDs.isEmpty {
            let item = NSMenuItem(title: "No desktops detected", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            for (i, sid) in spaceIDs.enumerated() {
                let pos = i + 1
                let label = "\(pos). \(menuBarLabel(forSpaceID: sid, position: pos))"
                let item = NSMenuItem(
                    title: label,
                    action: #selector(handleSwitch(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.tag = pos
                item.state = (sid == activeID) ? .on : .off
                if pos > 9 {
                    item.isEnabled = false
                    item.toolTip = "Direct switching supports desktops 1–9"
                }
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())

        if !spaceIDs.isEmpty {
            let renameItem = NSMenuItem(
                title: "Rename Desktops\u{2026}",
                action: #selector(handleRenameAll),
                keyEquivalent: ""
            )
            renameItem.target = self
            menu.addItem(renameItem)

            let clearItem = NSMenuItem(
                title: "Clear Desktop Names\u{2026}",
                action: #selector(handleClearAllNames),
                keyEquivalent: ""
            )
            clearItem.target = self
            menu.addItem(clearItem)
            menu.addItem(.separator())
        }

        let hint = NSMenuItem(title: "Shortcut: \(config.shortcut.displayString)", action: nil, keyEquivalent: "")
        hint.isEnabled = false
        menu.addItem(hint)

        let configItem = NSMenuItem(
            title: "Configure Shortcut\u{2026}",
            action: #selector(handleConfigureShortcut),
            keyEquivalent: ""
        )
        configItem.target = self
        menu.addItem(configItem)
        menu.addItem(.separator())

        let aboutItem = NSMenuItem(title: "About Switcher", action: #selector(handleAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Switcher", action: #selector(handleQuit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        menu.delegate = self
        statusItem.menu = menu
    }

    // MARK: - Menu keyboard (digits switch immediately)

    private func removeMenuKeyMonitorIfNeeded() {
        if let m = menuKeyMonitor {
            NSEvent.removeMonitor(m)
            menuKeyMonitor = nil
        }
    }

    /// Plain 1–9 (main keyboard or keypad) while the menu is open — switch without Enter.
    private func menuDigitIndex(from event: NSEvent) -> Int? {
        let blocked = event.modifierFlags.intersection([.command, .control, .option])
        if !blocked.isEmpty { return nil }

        if let s = event.charactersIgnoringModifiers, s.count == 1, let v = Int(s), (1 ... 9).contains(v) {
            return v
        }
        if let s = event.characters, s.count == 1, let v = Int(s), (1 ... 9).contains(v) {
            return v
        }

        switch Int(event.keyCode) {
        case kVK_ANSI_1: return 1
        case kVK_ANSI_2: return 2
        case kVK_ANSI_3: return 3
        case kVK_ANSI_4: return 4
        case kVK_ANSI_5: return 5
        case kVK_ANSI_6: return 6
        case kVK_ANSI_7: return 7
        case kVK_ANSI_8: return 8
        case kVK_ANSI_9: return 9
        default:
            let kc = Int(event.keyCode)
            if (83 ... 91).contains(kc) { return kc - 82 }
            return nil
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        removeMenuKeyMonitorIfNeeded()
        menuKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            guard self.statusItem.menu === menu else { return event }
            guard let digit = self.menuDigitIndex(from: event) else { return event }
            self.spaceManager.switchTo(desktopIndex: digit)
            menu.cancelTracking()
            return nil
        }
    }

    func menuDidClose(_ menu: NSMenu) {
        removeMenuKeyMonitorIfNeeded()
    }

    // MARK: - Actions

    @objc private func handleSwitch(_ sender: NSMenuItem) {
        spaceManager.switchTo(desktopIndex: sender.tag)
    }

    @objc private func handleRenameAll() {
        let spaceIDs = spaceManager.desktopSpaceIDs()
        renamePanel = RenamePanel(spaceIDs: spaceIDs)
        renamePanel?.onUpdate = { [weak self] in
            self?.syncAndRefresh()
        }
        renamePanel?.show()
    }

    @objc private func handleClearAllNames() {
        let alert = NSAlert()
        alert.messageText = "Clear all desktop names?"
        alert.informativeText = "Custom names will be removed. Desktops will show as Desktop 1, Desktop 2, and so on."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")

        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        store.clearAllNames()
        syncAndRefresh()
    }

    @objc private func handleConfigureShortcut() {
        shortcutPanel = ShortcutPanel()
        shortcutPanel?.onChange = { [weak self] in
            self?.registerCurrentShortcut()
            self?.syncAndRefresh()
        }
        shortcutPanel?.show()
    }

    @objc private func handleAbout() {
        let alert = NSAlert()
        alert.messageText = "Switcher"
        alert.informativeText = """
            Version 1.0.0

            A lightweight menu bar utility for naming \
            and switching between macOS desktop Spaces.

            Shortcut: \(config.shortcut.displayString)
            Config: ~/.config/switcher/
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")

        if let img = NSImage(systemSymbolName: "desktopcomputer", accessibilityDescription: nil) {
            img.isTemplate = false
            alert.icon = img
        }

        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }

    @objc private func handleQuit() {
        NSApp.terminate(nil)
    }

    @objc private func spaceChanged(_ note: Notification) {
        syncAndRefresh()
    }
}
