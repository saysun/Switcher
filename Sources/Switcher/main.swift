import AppKit

let delegate = AppDelegate()

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
app.delegate = delegate

withExtendedLifetime(delegate) {
    app.run()
}
