import Foundation

final class SpaceNameStore {
    static let shared = SpaceNameStore()

    private let fileURL: URL
    private var namesBySpaceID: [String: String] = [:]
    private var lastKnownOrder: [String] = []

    private init() {
        let dir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/switcher")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("spaces.json")
        load()
    }

    /// Look up a desktop's custom name by its Space ID; fall back to "Desktop <position>".
    func name(forSpaceID spaceID: Int, position: Int) -> String {
        namesBySpaceID[String(spaceID)] ?? "Desktop \(position)"
    }

    /// Assign a custom name to a Space ID.
    func setName(_ newName: String, forSpaceID spaceID: Int, position: Int) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || trimmed == "Desktop \(position)" {
            namesBySpaceID.removeValue(forKey: String(spaceID))
        } else {
            namesBySpaceID[String(spaceID)] = trimmed
        }
        save()
    }

    /// Call on launch and whenever the space list changes.
    /// Keeps the positional snapshot current and migrates names after a reboot
    /// (when macOS assigns fresh Space IDs).
    func syncOrder(_ currentSpaceIDs: [Int]) {
        let currentKeys = Set(currentSpaceIDs.map { String($0) })
        let savedKeys = Set(namesBySpaceID.keys)

        if !savedKeys.isEmpty && savedKeys.isDisjoint(with: currentKeys) {
            var migrated: [String: String] = [:]
            for (i, oldKey) in lastKnownOrder.enumerated() {
                if let name = namesBySpaceID[oldKey], i < currentSpaceIDs.count {
                    migrated[String(currentSpaceIDs[i])] = name
                }
            }
            namesBySpaceID = migrated
        }

        lastKnownOrder = currentSpaceIDs.map { String($0) }
        save()
    }

    // MARK: - Persistence

    private struct Storage: Codable {
        var names: [String: String]
        var order: [String]
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let storage = try? JSONDecoder().decode(Storage.self, from: data)
        else { return }
        namesBySpaceID = storage.names
        lastKnownOrder = storage.order
    }

    private func save() {
        let storage = Storage(names: namesBySpaceID, order: lastKnownOrder)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(storage) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
