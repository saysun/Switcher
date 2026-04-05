import Carbon
import Foundation

struct ShortcutConfig: Codable, Equatable {
    var keyCode: UInt32
    var modifiers: UInt32

    static let `default` = ShortcutConfig(
        keyCode: UInt32(kVK_ANSI_W),
        modifiers: UInt32(cmdKey | shiftKey)
    )

    var displayString: String {
        var parts: [String] = []
        if modifiers & UInt32(controlKey) != 0 { parts.append("⌃") }
        if modifiers & UInt32(optionKey)  != 0 { parts.append("⌥") }
        if modifiers & UInt32(shiftKey)   != 0 { parts.append("⇧") }
        if modifiers & UInt32(cmdKey)     != 0 { parts.append("⌘") }
        parts.append(Self.keyName(for: keyCode))
        return parts.joined()
    }

    private static func keyName(for code: UInt32) -> String {
        let map: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "↩",
            37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
            44: "/", 45: "N", 46: "M", 47: ".", 48: "⇥", 49: "Space",
            51: "⌫", 53: "⎋",
            96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
            103: "F11", 105: "F13", 107: "F14", 109: "F10", 111: "F12",
            113: "F15", 115: "Home", 116: "PgUp", 117: "⌦", 118: "F4",
            119: "End", 120: "F2", 121: "PgDn", 122: "F1",
            123: "←", 124: "→", 125: "↓", 126: "↑",
        ]
        return map[code] ?? "Key\(code)"
    }
}

struct WindowTileShortcuts: Codable, Equatable {
    var left: ShortcutConfig
    var right: ShortcutConfig
    var top: ShortcutConfig
    var bottom: ShortcutConfig
    var quarterTopLeft: ShortcutConfig
    var quarterTopRight: ShortcutConfig
    var quarterBottomLeft: ShortcutConfig
    var quarterBottomRight: ShortcutConfig
    var maximize: ShortcutConfig

    /// Halves/maximize: ⌃⌘ + arrows / ↩. Quarters: ⌃⌥⌘ + 1–4 (distinct from halves and ⌘⇧W menu default).
    static let `default` = WindowTileShortcuts(
        left: ShortcutConfig(keyCode: 123, modifiers: UInt32(controlKey | cmdKey)),
        right: ShortcutConfig(keyCode: 124, modifiers: UInt32(controlKey | cmdKey)),
        top: ShortcutConfig(keyCode: 126, modifiers: UInt32(controlKey | cmdKey)),
        bottom: ShortcutConfig(keyCode: 125, modifiers: UInt32(controlKey | cmdKey)),
        quarterTopLeft: ShortcutConfig(keyCode: 18, modifiers: UInt32(controlKey | optionKey | cmdKey)),
        quarterTopRight: ShortcutConfig(keyCode: 19, modifiers: UInt32(controlKey | optionKey | cmdKey)),
        quarterBottomLeft: ShortcutConfig(keyCode: 20, modifiers: UInt32(controlKey | optionKey | cmdKey)),
        quarterBottomRight: ShortcutConfig(keyCode: 21, modifiers: UInt32(controlKey | optionKey | cmdKey)),
        maximize: ShortcutConfig(keyCode: 36, modifiers: UInt32(controlKey | cmdKey))
    )

    enum CodingKeys: String, CodingKey {
        case left, right, top, bottom
        case quarterTopLeft, quarterTopRight, quarterBottomLeft, quarterBottomRight
        case maximize
    }

    init(
        left: ShortcutConfig,
        right: ShortcutConfig,
        top: ShortcutConfig,
        bottom: ShortcutConfig,
        quarterTopLeft: ShortcutConfig,
        quarterTopRight: ShortcutConfig,
        quarterBottomLeft: ShortcutConfig,
        quarterBottomRight: ShortcutConfig,
        maximize: ShortcutConfig
    ) {
        self.left = left
        self.right = right
        self.top = top
        self.bottom = bottom
        self.quarterTopLeft = quarterTopLeft
        self.quarterTopRight = quarterTopRight
        self.quarterBottomLeft = quarterBottomLeft
        self.quarterBottomRight = quarterBottomRight
        self.maximize = maximize
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = Self.default
        left = try c.decodeIfPresent(ShortcutConfig.self, forKey: .left) ?? d.left
        right = try c.decodeIfPresent(ShortcutConfig.self, forKey: .right) ?? d.right
        top = try c.decodeIfPresent(ShortcutConfig.self, forKey: .top) ?? d.top
        bottom = try c.decodeIfPresent(ShortcutConfig.self, forKey: .bottom) ?? d.bottom
        quarterTopLeft = try c.decodeIfPresent(ShortcutConfig.self, forKey: .quarterTopLeft) ?? d.quarterTopLeft
        quarterTopRight = try c.decodeIfPresent(ShortcutConfig.self, forKey: .quarterTopRight) ?? d.quarterTopRight
        quarterBottomLeft = try c.decodeIfPresent(ShortcutConfig.self, forKey: .quarterBottomLeft) ?? d.quarterBottomLeft
        quarterBottomRight = try c.decodeIfPresent(ShortcutConfig.self, forKey: .quarterBottomRight) ?? d.quarterBottomRight
        maximize = try c.decodeIfPresent(ShortcutConfig.self, forKey: .maximize) ?? d.maximize
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(left, forKey: .left)
        try c.encode(right, forKey: .right)
        try c.encode(top, forKey: .top)
        try c.encode(bottom, forKey: .bottom)
        try c.encode(quarterTopLeft, forKey: .quarterTopLeft)
        try c.encode(quarterTopRight, forKey: .quarterTopRight)
        try c.encode(quarterBottomLeft, forKey: .quarterBottomLeft)
        try c.encode(quarterBottomRight, forKey: .quarterBottomRight)
        try c.encode(maximize, forKey: .maximize)
    }
}

private struct PersistedConfig: Codable {
    var shortcut: ShortcutConfig?
    var showDesktopLabel: Bool?
    var windowTileShortcuts: WindowTileShortcuts?
}

final class ConfigStore {
    static let shared = ConfigStore()

    private let fileURL: URL
    private(set) var shortcut: ShortcutConfig = .default
    private(set) var showDesktopLabel: Bool = true
    private(set) var windowTileShortcuts: WindowTileShortcuts = .default

    private init() {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/switcher")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("config.json")
        load()
    }

    @discardableResult
    func setShortcut(_ config: ShortcutConfig) -> Bool {
        guard Self.isValidShortcut(config),
              Self.areTileShortcutsValid(windowTileShortcuts, menu: config) else { return false }
        shortcut = config
        save()
        return true
    }

    func setShowDesktopLabel(_ show: Bool) {
        showDesktopLabel = show
        save()
    }

    /// Returns `false` if any shortcut is duplicated (menu + all tile shortcuts must all differ).
    @discardableResult
    func setWindowTileShortcuts(_ tiles: WindowTileShortcuts) -> Bool {
        guard Self.areTileShortcutsValid(tiles, menu: shortcut) else { return false }
        windowTileShortcuts = tiles
        save()
        return true
    }

    private static func areTileShortcutsValid(_ tiles: WindowTileShortcuts, menu: ShortcutConfig) -> Bool {
        guard isValidShortcut(tiles.left), isValidShortcut(tiles.right),
              isValidShortcut(tiles.top), isValidShortcut(tiles.bottom),
              isValidShortcut(tiles.quarterTopLeft), isValidShortcut(tiles.quarterTopRight),
              isValidShortcut(tiles.quarterBottomLeft), isValidShortcut(tiles.quarterBottomRight),
              isValidShortcut(tiles.maximize) else { return false }
        let all = [
            menu,
            tiles.left, tiles.right, tiles.top, tiles.bottom,
            tiles.quarterTopLeft, tiles.quarterTopRight, tiles.quarterBottomLeft, tiles.quarterBottomRight,
            tiles.maximize,
        ]
        var seen = Set<UInt64>()
        for sc in all {
            let key = (UInt64(sc.keyCode) << 32) | UInt64(sc.modifiers)
            if seen.contains(key) { return false }
            seen.insert(key)
        }
        return true
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }

        if let full = try? JSONDecoder().decode(PersistedConfig.self, from: data) {
            if let sc = full.shortcut, Self.isValidShortcut(sc) {
                shortcut = sc
            }
            if let show = full.showDesktopLabel {
                showDesktopLabel = show
            }
            if let tiles = full.windowTileShortcuts, Self.areTileShortcutsValid(tiles, menu: shortcut) {
                windowTileShortcuts = tiles
            }
            return
        }

        if let sc = try? JSONDecoder().decode(ShortcutConfig.self, from: data),
           Self.isValidShortcut(sc) {
            shortcut = sc
            save()
        }
    }

    /// Carbon requires at least one modifier for a typical global hotkey.
    private static func isValidShortcut(_ sc: ShortcutConfig) -> Bool {
        sc.modifiers != 0
    }

    private func save() {
        let persisted = PersistedConfig(
            shortcut: shortcut,
            showDesktopLabel: showDesktopLabel,
            windowTileShortcuts: windowTileShortcuts
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(persisted) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
