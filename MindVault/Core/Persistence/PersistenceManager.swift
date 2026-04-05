import CoreData
import Foundation

protocol PersistenceManaging {
    var container: NSPersistentContainer { get }
    var viewContext: NSManagedObjectContext { get }
    func newBackgroundContext() -> NSManagedObjectContext
    func save(context: NSManagedObjectContext) throws
    func fetchEntries(on date: Date?) throws -> [JournalEntryEntity]
    func fetchAllEntries() throws -> [JournalEntryEntity]
    func fetchStickyNotes(for date: Date?) throws -> [StickyNoteEntity]
    func fetchEntryCount() -> Int
    func destroyAllData() async throws
}

final class PersistenceManager: PersistenceManaging {
    let container: NSPersistentContainer

    var viewContext: NSManagedObjectContext { container.viewContext }

    init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "MindVaultModel", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Failed to load store: \(error.localizedDescription)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.undoManager = nil
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.undoManager = nil
        return context
    }

    func save(context: NSManagedObjectContext) throws {
        guard context.hasChanges else { return }
        try context.save()
    }

    func fetchEntries(on date: Date?) throws -> [JournalEntryEntity] {
        let request = JournalEntryEntity.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \JournalEntryEntity.isPinned, ascending: false),
            NSSortDescriptor(keyPath: \JournalEntryEntity.updatedAt, ascending: false)
        ]
        if let date {
            let start = Calendar.current.startOfDay(for: date)
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
            request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt < %@", start as NSDate, end as NSDate)
        }
        return try viewContext.fetch(request)
    }

    func fetchAllEntries() throws -> [JournalEntryEntity] {
        let request = JournalEntryEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntryEntity.updatedAt, ascending: false)]
        return try viewContext.fetch(request)
    }

    func fetchStickyNotes(for date: Date?) throws -> [StickyNoteEntity] {
        let request = StickyNoteEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StickyNoteEntity.createdAt, ascending: false)]
        if let date {
            let start = Calendar.current.startOfDay(for: date)
            let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
            request.predicate = NSPredicate(format: "linkedDate >= %@ AND linkedDate < %@", start as NSDate, end as NSDate)
        }
        return try viewContext.fetch(request)
    }

    func fetchEntryCount() -> Int {
        let request = JournalEntryEntity.fetchRequest()
        return (try? viewContext.count(for: request)) ?? 0
    }

    func destroyAllData() async throws {
        let coordinator = container.persistentStoreCoordinator
        for store in coordinator.persistentStores {
            guard let url = store.url else { continue }
            let storeType = NSPersistentStore.StoreType(rawValue: store.type)
            try coordinator.destroyPersistentStore(at: url, type: storeType)
            _ = try coordinator.addPersistentStore(type: storeType, at: url)
        }
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entry = NSEntityDescription()
        entry.name = "JournalEntryEntity"
        entry.managedObjectClassName = NSStringFromClass(JournalEntryEntity.self)
        entry.properties = [
            makeAttribute("id", type: .UUIDAttributeType),
            makeAttribute("title", type: .stringAttributeType),
            makeAttribute("bodyText", type: .stringAttributeType),
            makeAttribute("createdAt", type: .dateAttributeType),
            makeAttribute("updatedAt", type: .dateAttributeType),
            makeAttribute("mood", type: .stringAttributeType),
            makeAttribute("tagsRaw", type: .stringAttributeType),
            makeAttribute("colorHex", type: .stringAttributeType),
            makeAttribute("isPinned", type: .booleanAttributeType)
        ]

        let note = NSEntityDescription()
        note.name = "StickyNoteEntity"
        note.managedObjectClassName = NSStringFromClass(StickyNoteEntity.self)
        note.properties = [
            makeAttribute("id", type: .UUIDAttributeType),
            makeAttribute("text", type: .stringAttributeType),
            makeAttribute("colorHex", type: .stringAttributeType),
            makeAttribute("createdAt", type: .dateAttributeType),
            makeAttribute("x", type: .doubleAttributeType),
            makeAttribute("y", type: .doubleAttributeType),
            makeAttribute("rotation", type: .doubleAttributeType),
            makeAttribute("linkedDate", type: .dateAttributeType, optional: true),
            makeAttribute("entryID", type: .UUIDAttributeType, optional: true)
        ]

        model.entities = [entry, note]
        return model
    }

    private static func makeAttribute(_ name: String, type: NSAttributeType, optional: Bool = false) -> NSAttributeDescription {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = type
        attribute.isOptional = optional
        return attribute
    }
}
