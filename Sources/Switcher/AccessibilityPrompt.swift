import AppKit
import ApplicationServices

enum AccessibilityPrompt {
    private static var didShowSwitchWarning = false

    /// Open System Settings → Privacy & Security → Accessibility (macOS 13+).
    static func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// After launch: if Switcher is not trusted, explain and offer to open Settings.
    static func showIfUntrustedOnLaunch() {
        guard !AXIsProcessTrusted() else { return }

        let alert = NSAlert()
        alert.messageText = "Switcher needs Accessibility"
        alert.informativeText = """
            Desktop switching simulates Ctrl+1–9. macOS only allows that for apps listed under \
            Privacy & Security → Accessibility.

            If you rebuilt Switcher or it stopped switching, turn Switcher off and on again in that list, \
            or remove it and re-add it.
            """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open Accessibility Settings")
        alert.addButton(withTitle: "OK")

        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }

    /// When a switch is attempted but the app is not trusted (once per session).
    static func warnSwitchBlockedIfNeeded() {
        guard !AXIsProcessTrusted() else { return }
        if didShowSwitchWarning { return }
        didShowSwitchWarning = true

        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([key: true] as CFDictionary)

        let alert = NSAlert()
        alert.messageText = "Cannot switch desktops"
        alert.informativeText = """
            Grant Accessibility for Switcher in System Settings → Privacy & Security → Accessibility. \
            Also ensure Keyboard → Keyboard Shortcuts → Mission Control has “Switch to Desktop 1–9” enabled.
            """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open Settings")
        alert.addButton(withTitle: "OK")

        NSApp.activate(ignoringOtherApps: true)
        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }
}
