import AppKit
import Carbon

final class WindowTileShortcutPanel: NSObject {
    private enum TileSlot: Int, CaseIterable {
        case left, right, top, bottom
        case quarterTopLeft, quarterTopRight, quarterBottomLeft, quarterBottomRight
        case maximize

        var title: String {
            switch self {
            case .left: return "Left half"
            case .right: return "Right half"
            case .top: return "Top half"
            case .bottom: return "Bottom half"
            case .quarterTopLeft: return "Top-left quarter"
            case .quarterTopRight: return "Top-right quarter"
            case .quarterBottomLeft: return "Bottom-left quarter"
            case .quarterBottomRight: return "Bottom-right quarter"
            case .maximize: return "Maximize"
            }
        }

        var glyphKind: TileLayoutGlyphView.Kind {
            switch self {
            case .left: return .leftHalf
            case .right: return .rightHalf
            case .top: return .topHalf
            case .bottom: return .bottomHalf
            case .quarterTopLeft: return .quarterTopLeft
            case .quarterTopRight: return .quarterTopRight
            case .quarterBottomLeft: return .quarterBottomLeft
            case .quarterBottomRight: return .quarterBottomRight
            case .maximize: return .maximize
            }
        }
    }

    private let panel: NSPanel
    private let config = ConfigStore.shared
    private var localMonitor: Any?
    private var recordingSlot: TileSlot?
    var onChange: (() -> Void)?

    private var displayBySlot: [TileSlot: NSTextField] = [:]
    private var setButtonBySlot: [TileSlot: NSButton] = [:]

    override init() {
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 540, height: 640),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Window Tile Shortcuts"
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.level = .modalPanel
        panel.isMovableByWindowBackground = true

        super.init()

        let tiles = config.windowTileShortcuts
        let initial: [TileSlot: ShortcutConfig] = [
            .left: tiles.left, .right: tiles.right, .top: tiles.top, .bottom: tiles.bottom,
            .quarterTopLeft: tiles.quarterTopLeft, .quarterTopRight: tiles.quarterTopRight,
            .quarterBottomLeft: tiles.quarterBottomLeft, .quarterBottomRight: tiles.quarterBottomRight,
            .maximize: tiles.maximize,
        ]

        let titleField = NSTextField(labelWithString: "Resize the focused window within the visible screen. Click Set…, then press a shortcut.")
        titleField.font = .systemFont(ofSize: 12)
        titleField.textColor = .secondaryLabelColor
        titleField.maximumNumberOfLines = 3
        titleField.cell?.lineBreakMode = .byWordWrapping
        titleField.preferredMaxLayoutWidth = 480
        titleField.translatesAutoresizingMaskIntoConstraints = false

        let hintField = NSTextField(labelWithString: "Each shortcut needs a modifier and must be unique (including the menu shortcut).")
        hintField.font = .systemFont(ofSize: 11)
        hintField.textColor = .secondaryLabelColor
        hintField.maximumNumberOfLines = 2
        hintField.cell?.lineBreakMode = .byWordWrapping
        hintField.preferredMaxLayoutWidth = 480
        hintField.translatesAutoresizingMaskIntoConstraints = false

        var gridRows: [[NSView]] = []
        for slot in TileSlot.allCases {
            let glyph = TileLayoutGlyphView(kind: slot.glyphKind)
            glyph.toolTip = "Preview: \(slot.title)"
            glyph.setAccessibilityElement(true)
            glyph.setAccessibilityRole(.image)
            glyph.setAccessibilityLabel("\(slot.title) layout")

            let name = NSTextField(labelWithString: slot.title)
            name.font = .systemFont(ofSize: 13, weight: .medium)
            name.alignment = .left
            name.translatesAutoresizingMaskIntoConstraints = false

            let field = NSTextField(labelWithString: initial[slot]!.displayString)
            field.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
            field.alignment = .center
            field.drawsBackground = true
            field.backgroundColor = .controlBackgroundColor
            field.isBordered = true
            field.isBezeled = true
            field.bezelStyle = .roundedBezel
            field.translatesAutoresizingMaskIntoConstraints = false
            field.widthAnchor.constraint(greaterThanOrEqualToConstant: 168).isActive = true

            let btn = NSButton(title: "Set…", target: self, action: #selector(setClicked(_:)))
            btn.bezelStyle = .rounded
            btn.tag = slot.rawValue
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.setContentHuggingPriority(.required, for: .horizontal)

            displayBySlot[slot] = field
            setButtonBySlot[slot] = btn

            gridRows.append([glyph, name, field, btn])
        }

        let grid = NSGridView(views: gridRows)
        grid.translatesAutoresizingMaskIntoConstraints = false
        grid.rowSpacing = 10
        grid.columnSpacing = 14
        grid.yPlacement = .center

        if grid.numberOfColumns > 0 {
            grid.column(at: 0).width = 44
            grid.column(at: 0).xPlacement = .center
            grid.column(at: 1).xPlacement = .leading
            grid.column(at: 2).xPlacement = .center
            grid.column(at: 3).xPlacement = .trailing
        }

        let resetBtn = NSButton(title: "Reset Defaults", target: self, action: #selector(resetClicked))
        resetBtn.bezelStyle = .rounded
        resetBtn.translatesAutoresizingMaskIntoConstraints = false

        let doneBtn = NSButton(title: "Done", target: self, action: #selector(doneClicked))
        doneBtn.bezelStyle = .rounded
        doneBtn.keyEquivalent = "\r"
        doneBtn.translatesAutoresizingMaskIntoConstraints = false

        let footerSpacer = NSView()
        footerSpacer.translatesAutoresizingMaskIntoConstraints = false
        footerSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let footerStack = NSStackView(views: [resetBtn, footerSpacer, doneBtn])
        footerStack.orientation = .horizontal
        footerStack.spacing = 12
        footerStack.distribution = .fill
        footerStack.translatesAutoresizingMaskIntoConstraints = false

        let mainStack = NSStackView(views: [titleField, hintField, grid, footerStack])
        mainStack.orientation = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 12
        mainStack.setCustomSpacing(6, after: titleField)
        mainStack.setCustomSpacing(14, after: hintField)
        mainStack.setCustomSpacing(18, after: grid)
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        let content = NSView(frame: .zero)
        content.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 22),
            mainStack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -22),
            mainStack.topAnchor.constraint(equalTo: content.topAnchor, constant: 18),
            mainStack.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -18),
            grid.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            titleField.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            hintField.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            footerStack.widthAnchor.constraint(equalTo: mainStack.widthAnchor),
            content.widthAnchor.constraint(equalToConstant: 540),
        ])

        panel.contentView = content
    }

    func show() {
        stopRecording()
        refreshAllDisplays()
        panel.contentView?.layoutSubtreeIfNeeded()
        let fitting = panel.contentView?.fittingSize ?? NSSize(width: 540, height: 640)
        panel.setContentSize(NSSize(width: max(540, fitting.width), height: max(620, fitting.height)))
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func refreshAllDisplays() {
        let t = config.windowTileShortcuts
        displayBySlot[.left]?.stringValue = t.left.displayString
        displayBySlot[.right]?.stringValue = t.right.displayString
        displayBySlot[.top]?.stringValue = t.top.displayString
        displayBySlot[.bottom]?.stringValue = t.bottom.displayString
        displayBySlot[.quarterTopLeft]?.stringValue = t.quarterTopLeft.displayString
        displayBySlot[.quarterTopRight]?.stringValue = t.quarterTopRight.displayString
        displayBySlot[.quarterBottomLeft]?.stringValue = t.quarterBottomLeft.displayString
        displayBySlot[.quarterBottomRight]?.stringValue = t.quarterBottomRight.displayString
        displayBySlot[.maximize]?.stringValue = t.maximize.displayString
    }

    @objc private func setClicked(_ sender: NSButton) {
        guard let slot = TileSlot(rawValue: sender.tag) else { return }
        recordingSlot = slot
        for (s, btn) in setButtonBySlot {
            btn.title = (s == slot) ? "Press keys…" : "Set…"
        }
        startRecording()
    }

    private func startRecording() {
        stopRecording()
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, let slot = self.recordingSlot else { return event }
            let mods = Self.carbonModifiers(from: event.modifierFlags)
            guard mods != 0 else { return event }

            let sc = ShortcutConfig(keyCode: UInt32(event.keyCode), modifiers: mods)
            var tiles = self.config.windowTileShortcuts
            switch slot {
            case .left: tiles.left = sc
            case .right: tiles.right = sc
            case .top: tiles.top = sc
            case .bottom: tiles.bottom = sc
            case .quarterTopLeft: tiles.quarterTopLeft = sc
            case .quarterTopRight: tiles.quarterTopRight = sc
            case .quarterBottomLeft: tiles.quarterBottomLeft = sc
            case .quarterBottomRight: tiles.quarterBottomRight = sc
            case .maximize: tiles.maximize = sc
            }

            if self.config.setWindowTileShortcuts(tiles) {
                self.displayBySlot[slot]?.stringValue = sc.displayString
                self.finishRecordingSlot()
                self.onChange?()
            } else {
                NSSound.beep()
            }
            return nil
        }
    }

    private func finishRecordingSlot() {
        recordingSlot = nil
        for (_, btn) in setButtonBySlot {
            btn.title = "Set…"
        }
        stopRecording()
    }

    private func stopRecording() {
        if let m = localMonitor {
            NSEvent.removeMonitor(m)
            localMonitor = nil
        }
    }

    @objc private func resetClicked() {
        finishRecordingSlot()
        if config.setWindowTileShortcuts(.default) {
            refreshAllDisplays()
            onChange?()
        } else {
            NSSound.beep()
        }
    }

    @objc private func doneClicked() {
        finishRecordingSlot()
        panel.close()
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var c: UInt32 = 0
        if flags.contains(.control) { c |= UInt32(controlKey) }
        if flags.contains(.option) { c |= UInt32(optionKey) }
        if flags.contains(.shift) { c |= UInt32(shiftKey) }
        if flags.contains(.command) { c |= UInt32(cmdKey) }
        return c
    }
}
