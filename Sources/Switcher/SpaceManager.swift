import AppKit
import CoreGraphics

// MARK: - Private CGS API declarations

@_silgen_name("CGSMainConnectionID")
private func CGSMainConnectionID() -> Int32

@_silgen_name("CGSGetActiveSpace")
private func CGSGetActiveSpace(_ cid: Int32) -> Int

@_silgen_name("CGSCopyManagedDisplaySpaces")
private func CGSCopyManagedDisplaySpaces(_ cid: Int32) -> CFArray

// MARK: - SpaceManager

final class SpaceManager {
    static let shared = SpaceManager()

    private let connectionID: Int32

    /// Virtual key codes for number keys 1–9.
    private static let numberKeyCodes: [CGKeyCode] = [
        18, 19, 20, 21, 23, 22, 26, 28, 25
    ]

    private init() {
        connectionID = CGSMainConnectionID()
    }

    /// Ordered list of regular desktop Space IDs (excludes fullscreen app spaces).
    func desktopSpaceIDs() -> [Int] {
        guard connectionID > 0 else { return [] }

        let raw = CGSCopyManagedDisplaySpaces(connectionID)
        guard let displays = raw as NSArray as? [[String: Any]] else { return [] }

        var ids: [Int] = []
        for display in displays {
            guard let spaces = display["Spaces"] as? [[String: Any]] else { continue }
            for space in spaces {
                let type = (space["type"] as? NSNumber)?.intValue ?? -1
                guard type == 0, let sid = (space["id64"] as? NSNumber)?.intValue else { continue }
                ids.append(sid)
            }
        }
        return ids
    }

    /// The system Space ID of the currently active desktop.
    func activeSpaceID() -> Int {
        guard connectionID > 0 else { return 0 }
        return CGSGetActiveSpace(connectionID)
    }

    /// 1-based index of the active desktop among all regular desktops.
    func activeDesktopIndex() -> Int? {
        let spaces = desktopSpaceIDs()
        let active = activeSpaceID()
        guard let i = spaces.firstIndex(of: active) else { return nil }
        return i + 1
    }

    var desktopCount: Int { desktopSpaceIDs().count }

    /// Simulate Ctrl+<number> to switch to the given 1-based desktop index (1–9).
    func switchTo(desktopIndex index: Int) {
        guard index >= 1, index <= Self.numberKeyCodes.count else { return }

        let keyCode = Self.numberKeyCodes[index - 1]
        let source = CGEventSource(stateID: .hidSystemState)

        guard let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let up   = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        else { return }

        down.flags = .maskControl
        up.flags   = .maskControl
        down.post(tap: .cgSessionEventTap)
        up.post(tap: .cgSessionEventTap)
    }
}
