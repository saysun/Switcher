import Foundation

final class SpaceNameStore {
    static let shared = SpaceNameStore()

    private let fileURL: URL
    private var names: [String: String] = [:]

    private init() {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/switcher")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("spaces.json")
        load()
    }

    func name(for desktopIndex: Int) -> String {
        names[String(desktopIndex)] ?? "Desktop \(desktopIndex)"
    }

    func setName(_ newName: String, for desktopIndex: Int) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "Desktop \(desktopIndex)" {
            names.removeValue(forKey: String(desktopIndex))
        } else {
            names[String(desktopIndex)] = trimmed
        }
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        else { return }
        names = decoded
    }

    private func save() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(names) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}