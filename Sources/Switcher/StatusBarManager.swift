import AppKit

final class StatusBarManager: NSObject, NSTextViewDelegate {
    private let statusItem: NSStatusItem
    private let spaceManager = SpaceManager.shared
    private let store = SpaceNameStore.shared
    private let config = ConfigStore.shared
    private var renamePanel: RenamePanel?
    private var shortcutPanel: ShortcutPanel?
    private let desktopLabel = DesktopLabel()
    /// Last desktop Space ID order we rendered; used to detect add/remove without switching.
    private var lastSpaceSnapshot: [Int] = []
    private var spacePollTimer: Timer?

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
        startSpaceListPolling()
    }

    /// macOS does not post a notification when desktops are added or removed—only when you switch.
    private func startSpaceListPolling() {
        spacePollTimer?.invalidate()
        let timer = Timer(timeInterval: 1.25, repeats: true) { [weak self] _ in
            self?.pollSpaceListIfChanged()
        }
        timer.tolerance = 0.35
        RunLoop.main.add(timer, forMode: .common)
        spacePollTimer = timer
    }

    private func pollSpaceListIfChanged() {
        let current = spaceManager.desktopSpaceIDs()
        guard current != lastSpaceSnapshot else { return }
        syncAndRefresh()
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
        lastSpaceSnapshot = spaceIDs
    }

    // MARK: - Title

    private static let appDisplayName = "Switcher"

    private static var appMarketingVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "dev"
    }

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
            updateDesktopLabel(text: Self.appDisplayName)
            return
        }
        let spaceID = spaceIDs[index - 1]
        let name = menuBarLabel(forSpaceID: spaceID, position: index)
        statusItem.button?.title = name
        updateDesktopLabel(text: "\(index). \(name)")
    }

    private func updateDesktopLabel(text: String) {
        if config.showDesktopLabel {
            desktopLabel.update(text: text)
        } else {
            desktopLabel.hide()
        }
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

        let labelToggle = NSMenuItem(
            title: config.showDesktopLabel ? "Hide Desktop Label" : "Show Desktop Label",
            action: #selector(handleToggleLabel),
            keyEquivalent: ""
        )
        labelToggle.target = self
        menu.addItem(labelToggle)
        menu.addItem(.separator())

        let aboutItem = NSMenuItem(title: "About Switcher", action: #selector(handleAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
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

    @objc private func handleToggleLabel() {
        config.setShowDesktopLabel(!config.showDesktopLabel)
        syncAndRefresh()
    }

    @objc private func handleAbout() {
        let alert = NSAlert()
        alert.messageText = "Switcher"
        alert.informativeText = ""
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")

        let contentWidth: CGFloat = 320
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: contentWidth, height: 148))
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.borderType = .noBorder
        scroll.drawsBackground = false

        let tv = NSTextView(frame: scroll.bounds)
        tv.autoresizingMask = [.width, .height]
        tv.isEditable = false
        tv.isSelectable = true
        tv.drawsBackground = false
        tv.textContainerInset = NSSize(width: 2, height: 4)
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.textContainer?.widthTracksTextView = true
        tv.textContainer?.containerSize = NSSize(width: contentWidth - 8, height: 10_000)
        tv.linkTextAttributes = [
            .foregroundColor: NSColor.linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
        tv.delegate = self

        let font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let para = NSMutableParagraphStyle()
        para.lineBreakMode = .byWordWrapping
        let base: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: para,
            .foregroundColor: NSColor.labelColor,
        ]

        let paypalURL = URL(string: "https://paypal.me/sunayong")!
        let body = NSMutableAttributedString()
        body.append(NSAttributedString(string: "Version \(Self.appMarketingVersion)\n\n", attributes: base))
        body.append(NSAttributedString(string: "A lightweight menu bar utility for naming and switching between macOS desktop Spaces.\n\n", attributes: base))
        body.append(NSAttributedString(string: "If Switcher makes your Spaces less chaotic, a coffee would brighten my day ☕\n", attributes: base))
        var linkAttrs = base
        linkAttrs[.link] = paypalURL
        linkAttrs[.foregroundColor] = NSColor.linkColor
        linkAttrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
        body.append(NSAttributedString(string: "https://paypal.me/sunayong", attributes: linkAttrs))

        tv.textStorage?.setAttributedString(body)
        scroll.documentView = tv
        alert.accessoryView = scroll

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

    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        guard let url = link as? URL else { return false }
        NSWorkspace.shared.open(url)
        return true
    }
}
