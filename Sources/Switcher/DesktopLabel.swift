import AppKit

final class DesktopLabel {
    private let window: NSWindow
    private let label: NSTextField

    private static let padding = NSEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
    private static let cornerMargin: CGFloat = 12

    init() {
        label = NSTextField(labelWithString: "")
        label.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false

        let backdrop = NSVisualEffectView()
        backdrop.material = .hudWindow
        backdrop.state = .active
        backdrop.blendingMode = .behindWindow
        backdrop.wantsLayer = true
        backdrop.layer?.cornerRadius = 6
        backdrop.layer?.masksToBounds = true

        backdrop.addSubview(label)
        let p = Self.padding
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: backdrop.topAnchor, constant: p.top),
            label.bottomAnchor.constraint(equalTo: backdrop.bottomAnchor, constant: -p.bottom),
            label.leadingAnchor.constraint(equalTo: backdrop.leadingAnchor, constant: p.left),
            label.trailingAnchor.constraint(equalTo: backdrop.trailingAnchor, constant: -p.right),
        ])

        window = NSWindow(
            contentRect: .zero,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .statusBar
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenNone]
        window.hasShadow = false
        window.contentView = backdrop
        window.alphaValue = 0.85
    }

    var isVisible: Bool { window.isVisible }

    func update(text: String) {
        label.stringValue = text
        label.sizeToFit()

        let p = Self.padding
        let contentSize = label.fittingSize
        let winW = contentSize.width + p.left + p.right
        let winH = contentSize.height + p.top + p.bottom

        guard let screen = NSScreen.main else { return }
        let vis = screen.visibleFrame
        let x = vis.maxX - winW - Self.cornerMargin
        let y = vis.minY + Self.cornerMargin

        window.setFrame(NSRect(x: x, y: y, width: winW, height: winH), display: true)
        window.orderFrontRegardless()
    }

    func hide() {
        window.orderOut(nil)
    }
}
