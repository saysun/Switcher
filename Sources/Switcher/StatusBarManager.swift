import AppKit

final class StatusBarManager {
    private let statusItem: NSStatusItem
    private let spaceManager = SpaceManager.shared
    private let store = SpaceNameStore.shared

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
            let renameParent = NSMenuItem(title: "Rename Desktop", action: nil, keyEquivalent: "")
            let renameSub = NSMenu()
            for (i, sid) in spaceIDs.enumerated() {
                let pos = i + 1
                let sub = NSMenuItem(
                    title: "\(pos). \(store.name(forSpaceID: sid, position: pos))",
                    action: #selector(handleRename(_:)),
                    keyEquivalent: ""
                )
                sub.target = self
                sub.tag = pos
                renameSub.addItem(sub)
            }
            renameParent.submenu = renameSub
            menu.addItem(renameParent)
            menu.addItem(.separator())
        }

        let quit = NSMenuItem(title: "Quit Switcher", action: #selector(handleQuit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func handleSwitch(_ sender: NSMenuItem) {
        spaceManager.switchTo(desktopIndex: sender.tag)
    }

    @objc private func handleRename(_ sender: NSMenuItem) {
        let pos = sender.tag
        let spaceIDs = spaceManager.desktopSpaceIDs()
        guard pos >= 1, pos <= spaceIDs.count else { return }
        let spaceID = spaceIDs[pos - 1]
        let currentName = store.name(forSpaceID: spaceID, position: pos)

        let alert = NSAlert()
        alert.messageText = "Rename Desktop \(pos)"
        alert.informativeText = "Enter a new name for this desktop:"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = currentName
        field.placeholderString = "Desktop \(pos)"
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        NSApp.activate(ignoringOtherApps: true)

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        store.setName(field.stringValue, forSpaceID: spaceID, position: pos)
        syncAndRefresh()
    }

    @objc private func handleQuit() {
        NSApp.terminate(nil)
    }

    @objc private func spaceChanged(_ note: Notification) {
        syncAndRefresh()
    }
}
