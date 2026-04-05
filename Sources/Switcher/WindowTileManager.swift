import AppKit
import ApplicationServices

enum WindowTileRegion {
    case left, right, top, bottom
    case quarterTopLeft, quarterTopRight, quarterBottomLeft, quarterBottomRight
    case maximize
}

/// AX `kAXPosition` / `kAXSize` use a different vertical convention than `NSScreen` global rects.
/// Same transform as Rectangle/Spectacle: `y = mainScreenMaxY - rect.maxY` (self-inverse for full rects).
private extension CGRect {
    func toggledAXVerticalSpace(usingMainMaxY mainMaxY: CGFloat) -> CGRect {
        CGRect(x: origin.x, y: mainMaxY - maxY, width: width, height: height)
    }
}

final class WindowTileManager {
    static let shared = WindowTileManager()

    private init() {}

    func tileFocusedWindow(_ region: WindowTileRegion) {
        guard AXIsProcessTrusted() else {
            NSLog("[Switcher] Accessibility permission required for window tiling. Enable Switcher in Privacy & Security → Accessibility.")
            return
        }

        guard let mainMaxY = NSScreen.screens.first?.frame.maxY else { return }

        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        let pid = app.processIdentifier
        let axApp = AXUIElementCreateApplication(pid)
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &focused) == .success,
              let windowCF = focused,
              CFGetTypeID(windowCF) == AXUIElementGetTypeID() else { return }
        let axWindow = windowCF as! AXUIElement

        guard let currentAX = Self.axFrame(of: axWindow) else { return }
        let currentNSScreen = currentAX.toggledAXVerticalSpace(usingMainMaxY: mainMaxY)
        let center = CGPoint(x: currentNSScreen.midX, y: currentNSScreen.midY)
        let screen = NSScreen.screens.first { $0.frame.contains(center) } ?? NSScreen.main
        guard let scr = screen else { return }
        let vf = scr.visibleFrame
        let hw = vf.width / 2
        let hh = vf.height / 2

        let targetNSScreen: CGRect
        switch region {
        case .left:
            targetNSScreen = CGRect(x: vf.minX, y: vf.minY, width: hw, height: vf.height)
        case .right:
            targetNSScreen = CGRect(x: vf.minX + hw, y: vf.minY, width: hw, height: vf.height)
        case .bottom:
            targetNSScreen = CGRect(x: vf.minX, y: vf.minY, width: vf.width, height: hh)
        case .top:
            targetNSScreen = CGRect(x: vf.minX, y: vf.minY + hh, width: vf.width, height: hh)
        case .quarterTopLeft:
            targetNSScreen = CGRect(x: vf.minX, y: vf.minY + hh, width: hw, height: hh)
        case .quarterTopRight:
            targetNSScreen = CGRect(x: vf.minX + hw, y: vf.minY + hh, width: hw, height: hh)
        case .quarterBottomLeft:
            targetNSScreen = CGRect(x: vf.minX, y: vf.minY, width: hw, height: hh)
        case .quarterBottomRight:
            targetNSScreen = CGRect(x: vf.minX + hw, y: vf.minY, width: hw, height: hh)
        case .maximize:
            targetNSScreen = vf
        }

        let targetAX = targetNSScreen.toggledAXVerticalSpace(usingMainMaxY: mainMaxY)
        Self.setAXFrame(targetAX, for: axWindow)
    }

    private static func axFrame(of el: AXUIElement) -> CGRect? {
        var posRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(el, kAXPositionAttribute as CFString, &posRef) == .success,
              AXUIElementCopyAttributeValue(el, kAXSizeAttribute as CFString, &sizeRef) == .success else { return nil }
        var pt = CGPoint.zero
        var sz = CGSize.zero
        AXValueGetValue(posRef as! AXValue, .cgPoint, &pt)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &sz)
        return CGRect(origin: pt, size: sz)
    }

    /// Size → position → size matches Rectangle/Spectacle so the window lands correctly across displays and menu bar insets.
    private static func setAXFrame(_ rect: CGRect, for el: AXUIElement) {
        var pt = rect.origin
        var sz = rect.size
        guard let posVal = AXValueCreate(.cgPoint, &pt),
              let sizeVal = AXValueCreate(.cgSize, &sz) else { return }
        _ = AXUIElementSetAttributeValue(el, kAXSizeAttribute as CFString, sizeVal)
        _ = AXUIElementSetAttributeValue(el, kAXPositionAttribute as CFString, posVal)
        _ = AXUIElementSetAttributeValue(el, kAXSizeAttribute as CFString, sizeVal)
    }
}
