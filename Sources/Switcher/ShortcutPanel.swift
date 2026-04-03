import AppKit
import Carbon

final class ShortcutPanel: NSObject {
    private let panel: NSPanel
    private let displayLabel: NSTextField
    private var localMonitor: Any?
    private let config = ConfigStore.shared
    var onChange: (() -> Void)?

    override init() {
        let width: CGFloat = 320
        let height: CGFloat = 190

        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: width, height: height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        panel.title = "Configure Shortcut"
        panel.isFloatingPanel = true
        panel.becomesKeyOnlyIfNeeded = false
        panel.level = .floating

        displayLabel = NSTextField(labelWithString: config.shortcut.displayString)

        super.init()

        let content = NSView(frame: NSRect(x: 0, y: 0, width: width, height: height))
        let pad: CGFloat = 20

        let title = NSTextField(labelWithString: "Press a new key combination:")
        title.frame = NSRect(x: pad, y: height - 42, width: width - pad * 2, height: 20)
        title.font = .systemFont(ofSize: 13, weight: .medium)
        content.addSubview(title)

        displayLabel.frame = NSRect(x: pad + 20, y: height - 92, width: width - pad * 2 - 40, height: 38)
        displayLabel.font = .monospacedSystemFont(ofSize: 22, weight: .medium)
        displayLabel.alignment = .center
        displayLabel.drawsBackground = true
        displayLabel.backgroundColor = .controlBackgroundColor
        displayLabel.isBordered = true
        displayLabel.isBezeled = true
        displayLabel.bezelStyle = .roundedBezel
        content.addSubview(displayLabel)

        let hint = NSTextField(labelWithString: "Use at least one modifier key (⌃ ⌥ ⇧ ⌘) with a letter or number.")
        hint.frame = NSRect(x: pad, y: height - 120, width: width - pad * 2, height: 16)
        hint.font = .systemFont(ofSize: 11)
        hint.textColor = .secondaryLabelColor
        content.addSubview(hint)

        let resetBtn = NSButton(title: "Reset Default", target: self, action: #selector(resetClicked))
        resetBtn.bezelStyle = .rounded
        resetBtn.frame = NSRect(x: pad, y: pad, width: 110, height: 32)
        content.addSubview(resetBtn)

        let doneBtn = NSButton(title: "Done", target: self, action: #selector(doneClicked))
        doneBtn.bezelStyle = .rounded
        doneBtn.keyEquivalent = "\r"
        doneBtn.frame = NSRect(x: width - 80 - pad, y: pad, width: 80, height: 32)
        content.addSubview(doneBtn)

        panel.contentView = content
    }

    func show() {
        startRecording()
        panel.center()
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Recording

    private func startRecording() {
        stopRecording()
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            let mods = Self.carbonModifiers(from: event.modifierFlags)
            guard mods != 0 else { return event }

            let sc = ShortcutConfig(keyCode: UInt32(event.keyCode), modifiers: mods)
            self.config.setShortcut(sc)
            self.displayLabel.stringValue = sc.displayString
            self.onChange?()
            return nil
        }
    }

    private func stopRecording() {
        if let m = localMonitor {
            NSEvent.removeMonitor(m)
            localMonitor = nil
        }
    }

    @objc private func resetClicked() {
        config.setShortcut(.default)
        displayLabel.stringValue = ShortcutConfig.default.displayString
        onChange?()
    }

    @objc private func doneClicked() {
        stopRecording()
        panel.close()
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var c: UInt32 = 0
        if flags.contains(.control) { c |= UInt32(controlKey) }
        if flags.contains(.option)  { c |= UInt32(optionKey)  }
        if flags.contains(.shift)   { c |= UInt32(shiftKey)   }
        if flags.contains(.command) { c |= UInt32(cmdKey)      }
        return c
    }
}
