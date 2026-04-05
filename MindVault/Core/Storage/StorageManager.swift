import Foundation

protocol StorageManaging {
    func clearAllData() async throws
}

enum StorageError: LocalizedError {
    case missingBundleIdentifier

    var errorDescription: String? {
        switch self {
        case .missingBundleIdentifier:
            return "The app bundle identifier could not be resolved."
        }
    }
}

final class StorageManager: StorageManaging {
    private let persistenceManager: PersistenceManaging
    private let fileManager: FileManager
    private let defaults: UserDefaults

    init(
        persistenceManager: PersistenceManaging,
        fileManager: FileManager = .default,
        defaults: UserDefaults = .standard
    ) {
        self.persistenceManager = persistenceManager
        self.fileManager = fileManager
        self.defaults = defaults
    }

    func clearAllData() async throws {
        try await persistenceManager.destroyAllData()
        try clearLocalFiles()
        try clearDefaults()
    }

    private func clearLocalFiles() throws {
        let directories: [FileManager.SearchPathDirectory] = [.applicationSupportDirectory, .documentDirectory, .cachesDirectory]
        for directory in directories {
            let url = try fileManager.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: true)
            let items = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
            for item in items where item.lastPathComponent != "Snapshots" {
                try? fileManager.removeItem(at: item)
            }
        }
    }

    private func clearDefaults() throws {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            throw StorageError.missingBundleIdentifier
        }
        defaults.removePersistentDomain(forName: bundleID)
        defaults.synchronize()
    }
}
