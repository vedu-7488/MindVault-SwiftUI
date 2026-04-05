import Combine
import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [JournalEntryEntity] = []

    private let persistenceManager: PersistenceManaging

    init(persistenceManager: PersistenceManaging) {
        self.persistenceManager = persistenceManager
        refresh()
    }

    func refresh() {
        let entries = (try? persistenceManager.fetchAllEntries()) ?? []
        if query.isEmpty {
            results = entries
        } else {
            results = entries.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.bodyText.localizedCaseInsensitiveContains(query) ||
                $0.tagsRaw.localizedCaseInsensitiveContains(query)
            }
        }
    }
}

struct SearchView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject var viewModel: SearchViewModel

    var body: some View {
        List(viewModel.results, id: \.id) { entry in
            VStack(alignment: .leading, spacing: 8) {
                Text(entry.title)
                    .font(themeManager.font(.headline, weight: .semibold))
                    .foregroundStyle(themeManager.primaryTextColor)
                Text(entry.bodyText)
                    .font(themeManager.font(.subheadline))
                    .foregroundStyle(themeManager.secondaryTextColor)
                    .lineLimit(2)
                Text(entry.createdAt.dayTitle)
                    .font(themeManager.font(.caption))
                    .foregroundStyle(themeManager.secondaryTextColor)
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .navigationTitle("Search")
        .searchable(text: $viewModel.query, prompt: "Search thoughts, moods, tags")
        .onChange(of: viewModel.query) { _, _ in
            viewModel.refresh()
        }
    }
}
