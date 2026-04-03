import AppKit

final class RenamePanel: NSObject, NSTextFieldDelegate {
    private let panel: NSPanel
    private var entries: [(spaceID: Int, position: Int, field: NSTextField)] = []
    private let store = SpaceNameStore.shared
    var onUpdate: (() -> Void)?

    init(spaceIDs: [Int]) {
        let width: CGFloat = 360
        let rowHeight: CGFloat = 36
        let padding: CGFloat = 20
        let buttonHeight: CGFloat = 36
        let rows = spaceIDs.count
        let contentHeight = padding + CGFloat(rows) * rowHeight + padding + buttonHeight + padding

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: contentHeight),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Rename Desktops"
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.level = .floating

        super.init()

        let content = NSView(frame: NSRect(x: 0, y: 0, width: width, height: contentHeight))

        let labelWidth: CGFloat = 28
        let gap: CGFloat = 8
        let fieldX = padding + labelWidth + gap
        let fieldWidth = width - fieldX - padding

        var y = contentHeight - padding - rowHeight

        for (i, sid) in spaceIDs.enumerated() {
            let pos = i + 1

            let label = NSTextField(labelWithString: "\(pos).")
            label.frame = NSRect(x: padding, y: y + 4, width: labelWidth, height: 20)
            label.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
            label.alignment = .right
            content.addSubview(label)

            let field = NSTextField(frame: NSRect(x: fieldX, y: y, width: fieldWidth, height: 26))
            field.stringValue = store.name(forSpaceID: sid, position: pos)
            field.placeholderString = "Desktop \(pos)"
            field.font = NSFont.systemFont(ofSize: 13)
            field.usesSingleLineMode = true
            field.tag = i
            field.delegate = self
            content.addSubview(field)

            entries.append((spaceID: sid, position: pos, field: field))
            y -= rowHeight
        }

        let button = NSButton(title: "Done", target: self, action: #selector(doneClicked))
        button.bezelStyle = .rounded
        button.keyEquivalent = "\r"
        let buttonWidth: CGFloat = 80
        button.frame = NSRect(
            x: width - buttonWidth - padding,
            y: padding,
            width: buttonWidth,
            height: buttonHeight
        )
        content.addSubview(button)

        panel.contentView = content
    }

    func show() {
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        if let first = entries.first?.field {
            panel.makeFirstResponder(first)
        }
    }

    // MARK: - Auto-save on every edit

    func controlTextDidChange(_ obj: Notification) {
        saveAll()
    }

    // MARK: - Done

    @objc private func doneClicked() {
        saveAll()
        panel.close()
    }

    private func saveAll() {
        for e in entries {
            store.setName(e.field.stringValue, forSpaceID: e.spaceID, position: e.position)
        }
        onUpdate?()
    }
}
