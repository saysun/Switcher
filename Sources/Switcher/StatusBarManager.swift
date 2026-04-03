import AppKit

final class StatusBarManager {
    private let statusItem: NSStatusItem
    private let spaceManager = SpaceManager.shared
    private let store = SpaceNameStore.shared
    private let config = ConfigStore.shared
    private var renamePanel: RenamePanel?
    private var shortcutPanel: ShortcutPanel?

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

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

    private func updateTitle(spaceIDs: [Int]) {
        guard let index = spaceManager.activeDesktopIndex(),
              index >= 1, index <= spaceIDs.count else {
            statusItem.button?.title = "—"
            return
        }
        let spaceID = spaceIDs[index - 1]
        statusItem.button?.title = store.name(forSpaceID: spaceID, position: index)
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
                let label = "\(pos). \(store.name(forSpaceID: sid, position: pos))"
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

        let quit = NSMenuItem(title: "Quit Switcher", action: #selector(handleQuit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
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

    @objc private func handleConfigureShortcut() {
        shortcutPanel = ShortcutPanel()
        shortcutPanel?.onChange = { [weak self] in
            self?.registerCurrentShortcut()
            self?.syncAndRefresh()
        }
        shortcutPanel?.show()
    }

    @objc private func handleQuit() {
        NSApp.terminate(nil)
    }

    @objc private func spaceChanged(_ note: Notification) {
        syncAndRefresh()
    }
}
