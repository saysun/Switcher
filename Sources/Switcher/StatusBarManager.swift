import AppKit

final class StatusBarManager {
    private let statusItem: NSStatusItem
    private let spaceManager = SpaceManager.shared
    private let store = SpaceNameStore.shared

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        }

        updateTitle()
        rebuildMenu()

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
    }

    // MARK: - Title

    private func updateTitle() {
        guard let index = spaceManager.activeDesktopIndex() else {
            statusItem.button?.title = "◆ —"
            return
        }
        statusItem.button?.title = "◆ \(store.name(for: index))"
    }

    // MARK: - Menu

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let spaceIDs = spaceManager.desktopSpaceIDs()
        let activeID = spaceManager.activeSpaceID()

        if spaceIDs.isEmpty {
            let item = NSMenuItem(title: "No desktops detected", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            for (i, sid) in spaceIDs.enumerated() {
                let idx = i + 1
                let label = "\(idx). \(store.name(for: idx))"
                let item = NSMenuItem(
                    title: label,
                    action: #selector(handleSwitch(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.tag = idx
                item.state = (sid == activeID) ? .on : .off
                if idx > 9 {
                    item.isEnabled = false
                    item.toolTip = "Direct switching supports desktops 1–9"
                }
                menu.addItem(item)
            }
        }

        menu.addItem(.separator())

        // Rename submenu
        if !spaceIDs.isEmpty {
            let renameParent = NSMenuItem(title: "Rename Desktop", action: nil, keyEquivalent: "")
            let renameSub = NSMenu()
            for i in 0..<spaceIDs.count {
                let idx = i + 1
                let sub = NSMenuItem(
                    title: "\(idx). \(store.name(for: idx))",
                    action: #selector(handleRename(_:)),
                    keyEquivalent: ""
                )
                sub.target = self
                sub.tag = idx
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
        let idx = sender.tag
        let currentName = store.name(for: idx)

        let alert = NSAlert()
        alert.messageText = "Rename Desktop \(idx)"
        alert.informativeText = "Enter a new name for this desktop:"
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .informational

        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
        field.stringValue = currentName
        field.placeholderString = "Desktop \(idx)"
        alert.accessoryView = field
        alert.window.initialFirstResponder = field

        NSApp.activate(ignoringOtherApps: true)

        guard alert.runModal() == .alertFirstButtonReturn else { return }
        store.setName(field.stringValue, for: idx)
        updateTitle()
        rebuildMenu()
    }

    @objc private func handleQuit() {
        NSApp.terminate(nil)
    }

    @objc private func spaceChanged(_ note: Notification) {
        updateTitle()
        rebuildMenu()
    }
}
