import AppKit
import ApplicationServices

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarManager: StatusBarManager?

    func applicationDidFinishLaunching(_ notification: Notification) {
        promptAccessibilityIfNeeded()
        statusBarManager = StatusBarManager()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            AccessibilityPrompt.showIfUntrustedOnLaunch()
        }
    }

    private func promptAccessibilityIfNeeded() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
