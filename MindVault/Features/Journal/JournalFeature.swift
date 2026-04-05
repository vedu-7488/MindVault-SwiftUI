import Combine
import CoreData
import SwiftUI

struct JournalEntryDraft: Identifiable {
    let id: UUID
    var title: String
    var bodyText: String
    var mood: String
    var tagsText: String
    var isPinned: Bool
    var colorHex: String
    var createdAt: Date

    init(entity: JournalEntryEntity) {
        id = entity.id
        title = entity.title
        bodyText = entity.bodyText
        mood = entity.mood
        tagsText = entity.tagsRaw
        isPinned = entity.isPinned
        colorHex = entity.colorHex
        createdAt = entity.createdAt
    }

    init(date: Date) {
        id = UUID()
        title = ""
        bodyText = ""
        mood = "Calm"
        tagsText = "Personal"
        isPinned = false
        colorHex = "#F2EDE4"
        createdAt = date
    }
}

struct StickyNoteDraft: Identifiable {
    let id: NSManagedObjectID
    var text: String
    var colorHex: String
}

@MainActor
final class JournalViewModel: ObservableObject {
    @Published private(set) var entries: [JournalEntryEntity] = []
    @Published private(set) var stickyNotes: [StickyNoteEntity] = []
    @Published var activeDraft: JournalEntryDraft?
    @Published var activeStickyNoteDraft: StickyNoteDraft?

    private let persistenceManager: PersistenceManaging

    init(persistenceManager: PersistenceManaging) {
        self.persistenceManager = persistenceManager
    }

    func load(for date: Date) {
        entries = (try? persistenceManager.fetchEntries(on: date)) ?? []
        stickyNotes = (try? persistenceManager.fetchStickyNotes(for: date)) ?? []
    }

    func presentComposer(for date: Date) {
        activeDraft = JournalEntryDraft(date: date)
    }

    func presentEditor(for entity: JournalEntryEntity) {
        activeDraft = JournalEntryDraft(entity: entity)
    }

    func saveDraft(_ draft: JournalEntryDraft) {
        let context = persistenceManager.viewContext
        let request = JournalEntryEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", draft.id as CVarArg)

        let entry = (try? context.fetch(request).first) ?? JournalEntryEntity(context: context)
        entry.id = draft.id
        entry.title = draft.title.isEmpty ? "Untitled Thought" : draft.title
        entry.bodyText = draft.bodyText
        entry.createdAt = draft.createdAt
        entry.updatedAt = .now
        entry.mood = draft.mood
        entry.tagsRaw = draft.tagsText
        entry.isPinned = draft.isPinned
        entry.colorHex = draft.colorHex
        try? persistenceManager.save(context: context)
        load(for: draft.createdAt)
        activeDraft = nil
    }

    func togglePinned(_ entity: JournalEntryEntity, selectedDate: Date) {
        entity.isPinned.toggle()
        entity.updatedAt = .now
        try? persistenceManager.save(context: persistenceManager.viewContext)
        load(for: selectedDate)
    }

    func deleteEntry(_ draft: JournalEntryDraft) {
        let request = JournalEntryEntity.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", draft.id as CVarArg)
        if let entry = try? persistenceManager.viewContext.fetch(request).first {
            persistenceManager.viewContext.delete(entry)
            try? persistenceManager.save(context: persistenceManager.viewContext)
        }
        activeDraft = nil
        load(for: draft.createdAt)
    }

    func addStickyNote(text: String, date: Date) {
        let note = StickyNoteEntity(context: persistenceManager.viewContext)
        note.id = UUID()
        note.text = text
        note.colorHex = "#F6E27F"
        note.createdAt = .now
        note.x = 50
        note.y = 110
        note.rotation = Double.random(in: -5...5)
        note.linkedDate = date.strippedToDay()
        note.entryID = nil
        try? persistenceManager.save(context: persistenceManager.viewContext)
        load(for: date)
    }

    func updateStickyNote(_ note: StickyNoteEntity, offset: CGSize, date: Date) {
        note.x = offset.width
        note.y = offset.height
        try? persistenceManager.save(context: persistenceManager.viewContext)
        load(for: date)
    }

    func presentStickyNoteEditor(_ note: StickyNoteEntity) {
        activeStickyNoteDraft = StickyNoteDraft(
            id: note.objectID,
            text: note.text,
            colorHex: note.colorHex
        )
    }

    func saveStickyNote(_ draft: StickyNoteDraft, date: Date) {
        guard let note = try? persistenceManager.viewContext.existingObject(with: draft.id) as? StickyNoteEntity else { return }
        note.text = draft.text
        note.colorHex = draft.colorHex
        try? persistenceManager.save(context: persistenceManager.viewContext)
        activeStickyNoteDraft = nil
        load(for: date)
    }

    func deleteStickyNote(_ draft: StickyNoteDraft, date: Date) {
        guard let note = try? persistenceManager.viewContext.existingObject(with: draft.id) else { return }
        persistenceManager.viewContext.delete(note)
        try? persistenceManager.save(context: persistenceManager.viewContext)
        activeStickyNoteDraft = nil
        load(for: date)
    }

    var entryDates: Set<Date> {
        let allEntries = (try? persistenceManager.fetchAllEntries()) ?? []
        return Set(allEntries.map { $0.createdAt.strippedToDay() })
    }
}

struct MainTabView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        TabView(selection: $session.activeTab) {
            NavigationStack {
                JournalHomeView(viewModel: JournalViewModel(persistenceManager: container.persistenceManager))
            }
            .tabItem { Label("Journal", systemImage: "book.closed") }
            .tag(AppTab.journal)

            NavigationStack {
                SearchView(viewModel: SearchViewModel(persistenceManager: container.persistenceManager))
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }
            .tag(AppTab.search)

            NavigationStack {
                CalendarHubView(viewModel: JournalViewModel(persistenceManager: container.persistenceManager))
            }
            .tabItem { Label("Calendar", systemImage: "calendar") }
            .tag(AppTab.calendar)

            NavigationStack {
                AnalyticsView(viewModel: AnalyticsViewModel(persistenceManager: container.persistenceManager))
            }
            .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }
            .tag(AppTab.analytics)

            NavigationStack {
                SettingsView(viewModel: SettingsViewModel(session: container.session, themeManager: container.themeManager))
            }
            .tabItem { Label("Settings", systemImage: "gearshape") }
            .tag(AppTab.settings)
        }
        .tint(.accentColor)
        .font(themeManager.font(.body))
    }
}

struct JournalHomeView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject var viewModel: JournalViewModel
    @Namespace private var composerNamespace

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if viewModel.entries.isEmpty {
                        emptyState
                    } else {
                        entryScroller
                    }
                    stickyHeader
                    StickyNotesBoardView(
                        notes: viewModel.stickyNotes,
                        onNoteMoved: { note, offset in
                            viewModel.updateStickyNote(note, offset: offset, date: session.selectedDate)
                        },
                        onNoteTapped: { note in
                            viewModel.presentStickyNoteEditor(note)
                        }
                    )
                }
                .padding()
            }

            Button {
                withAnimation(.interactiveSpring(response: 0.45, dampingFraction: 0.8)) {
                    viewModel.presentComposer(for: session.selectedDate)
                }
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(themeManager.font(.title2, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 62, height: 62)
                    .background(Color.accentColor, in: Circle())
                    .shadow(color: .black.opacity(0.22), radius: 18, y: 10)
                    .matchedGeometryEffect(id: "composerFAB", in: composerNamespace)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 20)
            .padding(.bottom, 8)
        }
        .navigationTitle("Journal")
        .fullScreenCover(item: $viewModel.activeDraft) { draft in
            JournalEditorView(draft: draft) { savedDraft in
                viewModel.saveDraft(savedDraft)
            } onDelete: { deletingDraft in
                viewModel.deleteEntry(deletingDraft)
            }
        }
        .sheet(item: $viewModel.activeStickyNoteDraft) { draft in
            StickyNoteEditorView(
                draft: draft,
                onSave: { updatedDraft in
                    viewModel.saveStickyNote(updatedDraft, date: session.selectedDate)
                },
                onDelete: { deletingDraft in
                    viewModel.deleteStickyNote(deletingDraft, date: session.selectedDate)
                }
            )
            .presentationDetents([.medium])
        }
        .task(id: session.selectedDate) {
            viewModel.load(for: session.selectedDate)
        }
        .onChange(of: session.activeTab) { _, tab in
            guard tab == .journal else { return }
            viewModel.load(for: session.selectedDate)
        }
    }

    private var header: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(session.selectedDate.dayTitle)
                    .font(themeManager.font(.title2, weight: .bold))
                    .foregroundStyle(themeManager.primaryTextColor)
                Text("Capture a thought, save a memory, or leave a note for later.")
                    .font(themeManager.font(.body))
                    .foregroundStyle(themeManager.secondaryTextColor)
                HStack {
                    moodBadge(title: viewModel.entries.first?.mood ?? "Calm")
                    Spacer()
                    Text("\(viewModel.entries.count) entries")
                        .font(themeManager.font(.subheadline, weight: .semibold))
                        .foregroundStyle(themeManager.primaryTextColor)
                }
            }
        }
    }

    private var emptyState: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Nothing written yet")
                    .font(themeManager.font(.title3, weight: .bold))
                    .foregroundStyle(themeManager.primaryTextColor)
                Text("Tap the composer button to start your first entry for this day.")
                    .font(themeManager.font(.body))
                    .foregroundStyle(themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var entryScroller: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(viewModel.entries, id: \.id) { entry in
                Button {
                    viewModel.presentEditor(for: entry)
                } label: {
                    PremiumCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.title)
                                        .font(themeManager.font(.title3, weight: .bold))
                                        .foregroundStyle(themeManager.primaryTextColor)
                                    Text(entry.updatedAt.formatted(.dateTime.hour().minute()))
                                        .font(themeManager.font(.caption))
                                        .foregroundStyle(themeManager.secondaryTextColor)
                                }
                                Spacer()
                                Menu {
                                    Button {
                                        viewModel.togglePinned(entry, selectedDate: session.selectedDate)
                                    } label: {
                                        Label(entry.isPinned ? "Unpin Entry" : "Pin Entry", systemImage: entry.isPinned ? "pin.slash" : "pin")
                                    }

                                    Button(role: .destructive) {
                                        viewModel.deleteEntry(JournalEntryDraft(entity: entry))
                                    } label: {
                                        Label("Delete Entry", systemImage: "trash")
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                        .font(themeManager.font(.headline, weight: .semibold))
                                        .foregroundStyle(themeManager.secondaryTextColor)
                                }
                                .buttonStyle(.plain)
                            }
                            Text(entry.bodyText)
                                .font(themeManager.font(.body))
                                .foregroundStyle(themeManager.secondaryTextColor)
                                .lineLimit(4)
                            HStack {
                                moodBadge(title: entry.mood)
                                ForEach(entry.tags.prefix(2), id: \.self) { tag in
                                    tagBadge(title: tag)
                                }
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var stickyHeader: some View {
        HStack {
            Text("Sticky Notes")
                .font(themeManager.font(.headline, weight: .bold))
                .foregroundStyle(themeManager.primaryTextColor)
            Spacer()
            Button {
                viewModel.addStickyNote(text: "New sticky note", date: session.selectedDate)
            } label: {
                Label("Add Sticky", systemImage: "plus")
                    .font(themeManager.font(.subheadline, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
        }
    }

    private func moodBadge(title: String) -> some View {
        Text(title)
            .font(themeManager.font(.caption, weight: .semibold))
            .foregroundStyle(themeManager.primaryTextColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.accentColor.opacity(0.15), in: Capsule())
    }

    private func tagBadge(title: String) -> some View {
        Text(title)
            .font(themeManager.font(.caption, weight: .medium))
            .foregroundStyle(themeManager.primaryTextColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(themeManager.elevatedFillColor, in: Capsule())
    }
}

struct JournalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @State var draft: JournalEntryDraft
    let onSave: (JournalEntryDraft) -> Void
    let onDelete: (JournalEntryDraft) -> Void

    private let moods = ["Calm", "Focused", "Joyful", "Reflective"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    TextField("Title", text: $draft.title)
                        .font(themeManager.font(.title2, weight: .bold))
                    TextEditor(text: $draft.bodyText)
                        .frame(minHeight: 220)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                    Picker("Mood", selection: $draft.mood) {
                        ForEach(moods, id: \.self) { mood in
                            Text(mood).tag(mood)
                        }
                    }
                    .pickerStyle(.segmented)

                    TextField("Tags", text: $draft.tagsText)
                        .textInputAutocapitalization(.words)

                    Toggle("Pin Entry", isOn: $draft.isPinned)
                }
                .padding()
            }
            .navigationTitle("Entry")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    if !draft.title.isEmpty || !draft.bodyText.isEmpty {
                        Button(role: .destructive) {
                            onDelete(draft)
                            dismiss()
                        } label: {
                            Label("Delete Entry", systemImage: "trash")
                        }
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct StickyNoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var themeManager: ThemeManager
    @State var draft: StickyNoteDraft
    let onSave: (StickyNoteDraft) -> Void
    let onDelete: (StickyNoteDraft) -> Void

    private let colors = ["#F6E27F", "#F5C4D3", "#BFE3D0", "#C9D7F8", "#F2D2A2"]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 18) {
                TextField("Sticky note", text: $draft.text, axis: .vertical)
                    .font(themeManager.font(.body))
                    .lineLimit(4...6)
                    .padding()
                    .background(themeManager.cardBackgroundColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text("Color")
                    .font(themeManager.font(.headline, weight: .semibold))
                    .foregroundStyle(themeManager.primaryTextColor)

                HStack(spacing: 14) {
                    ForEach(colors, id: \.self) { color in
                        Button {
                            draft.colorHex = color
                        } label: {
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 34, height: 34)
                                .overlay {
                                    if draft.colorHex == color {
                                        Circle().strokeBorder(themeManager.primaryTextColor.opacity(0.7), lineWidth: 2)
                                    }
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Edit Sticky")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Delete", role: .destructive) {
                        onDelete(draft)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
