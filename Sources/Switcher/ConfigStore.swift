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

private struct PersistedConfig: Codable {
    var shortcut: ShortcutConfig?
    var showDesktopLabel: Bool?
}

final class ConfigStore {
    static let shared = ConfigStore()

    private let fileURL: URL
    private(set) var shortcut: ShortcutConfig = .default
    private(set) var showDesktopLabel: Bool = true

    private init() {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/switcher")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("config.json")
        load()
    }

    func setShortcut(_ config: ShortcutConfig) {
        shortcut = config
        save()
    }

    func setShowDesktopLabel(_ show: Bool) {
        showDesktopLabel = show
        save()
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
        let persisted = PersistedConfig(shortcut: shortcut, showDesktopLabel: showDesktopLabel)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(persisted) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
