import CoreData

@objc(JournalEntryEntity)
final class JournalEntryEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var title: String
    @NSManaged var bodyText: String
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    @NSManaged var mood: String
    @NSManaged var tagsRaw: String
    @NSManaged var colorHex: String
    @NSManaged var isPinned: Bool
}

extension JournalEntryEntity {
    @nonobjc static func fetchRequest() -> NSFetchRequest<JournalEntryEntity> {
        NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
    }

    var tags: [String] {
        tagsRaw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }
}

@objc(StickyNoteEntity)
final class StickyNoteEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var text: String
    @NSManaged var colorHex: String
    @NSManaged var createdAt: Date
    @NSManaged var x: Double
    @NSManaged var y: Double
    @NSManaged var rotation: Double
    @NSManaged var linkedDate: Date?
    @NSManaged var entryID: UUID?
}

extension StickyNoteEntity {
    @nonobjc static func fetchRequest() -> NSFetchRequest<StickyNoteEntity> {
        NSFetchRequest<StickyNoteEntity>(entityName: "StickyNoteEntity")
    }
}
