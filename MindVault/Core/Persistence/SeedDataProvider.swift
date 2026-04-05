import CoreData
import Foundation

protocol SeedDataProviding {
    func seedIfNeeded() async throws
    func forceSeed() throws
}

final class SeedDataProvider: SeedDataProviding {
    private let persistenceManager: PersistenceManaging
    private let defaults: UserDefaults

    init(persistenceManager: PersistenceManaging, defaults: UserDefaults = .standard) {
        self.persistenceManager = persistenceManager
        self.defaults = defaults
    }

    func seedIfNeeded() async throws {
        guard defaults.bool(forKey: AppStorageKey.hasSeededData) == false else { return }
        try forceSeed()
        defaults.set(true, forKey: AppStorageKey.hasSeededData)
    }

    func forceSeed() throws {
        let context = persistenceManager.newBackgroundContext()
        try context.performAndWait {
            let calendar = Calendar.current
            let moods = ["Focused", "Calm", "Grateful", "Reflective", "Joyful"]
            let palettes = ["#F2EDE4", "#E5F3EE", "#F5E8E4", "#E7ECF8", "#F7F1D9"]
            let titles = [
                "Morning Reset",
                "A Quiet Win",
                "Gratitude Snapshot",
                "Design Notes",
                "Sunday Reflection"
            ]
            let bodies = [
                "Started the day with a slow coffee and a short walk. The mind felt less crowded once I stopped trying to solve everything at once.",
                "Progress felt invisible until I looked back at the week. Small habits are starting to compound.",
                "The strongest feeling today was relief. Things did not become easier, but I became steadier.",
                "Noticed how much atmosphere matters. Softer colors and intentional spacing make writing feel less like work.",
                "I want the next week to feel lighter, not just busier. Protecting margin might be the real goal."
            ]
            let tags = [
                "Morning,Intentional",
                "Momentum,Work",
                "Gratitude,Life",
                "Product,Ideas",
                "Weekly,Reflection"
            ]

            for index in 0..<5 {
                let entry = JournalEntryEntity(context: context)
                let date = calendar.date(byAdding: .day, value: -index, to: .now) ?? .now
                entry.id = UUID()
                entry.title = titles[index]
                entry.bodyText = bodies[index]
                entry.createdAt = date
                entry.updatedAt = date
                entry.mood = moods[index]
                entry.tagsRaw = tags[index]
                entry.colorHex = palettes[index]
                entry.isPinned = index == 0
            }

            let note = StickyNoteEntity(context: context)
            note.id = UUID()
            note.text = "Check in with one kind thought before bed."
            note.colorHex = "#F6E27F"
            note.createdAt = .now
            note.x = 40
            note.y = 90
            note.rotation = -4
            note.linkedDate = calendar.startOfDay(for: .now)
            note.entryID = nil

            try self.persistenceManager.save(context: context)
        }
    }
}
