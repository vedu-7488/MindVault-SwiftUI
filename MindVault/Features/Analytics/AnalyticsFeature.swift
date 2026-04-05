import Combine
import SwiftUI

@MainActor
final class AnalyticsViewModel: ObservableObject {
    @Published private(set) var totalEntries = 0
    @Published private(set) var pinnedEntries = 0
    @Published private(set) var topMood = "Calm"
    @Published private(set) var streak = 0

    private let persistenceManager: PersistenceManaging

    init(persistenceManager: PersistenceManaging) {
        self.persistenceManager = persistenceManager
        refresh()
    }

    func refresh() {
        let entries = (try? persistenceManager.fetchAllEntries()) ?? []
        totalEntries = entries.count
        pinnedEntries = entries.filter(\.isPinned).count
        topMood = Dictionary(grouping: entries, by: \.mood)
            .max(by: { $0.value.count < $1.value.count })?.key ?? "Calm"

        let sortedDates = Set(entries.map { $0.createdAt.strippedToDay() }).sorted(by: >)
        var runningStreak = 0
        var cursor = Date().strippedToDay()
        for date in sortedDates where Calendar.current.isDate(date, inSameDayAs: cursor) {
            runningStreak += 1
            cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        streak = runningStreak
    }
}

struct AnalyticsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject var viewModel: AnalyticsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                metricCard(title: "Entries", value: "\(viewModel.totalEntries)", subtitle: "Captured reflections")
                metricCard(title: "Pinned", value: "\(viewModel.pinnedEntries)", subtitle: "Important moments")
                metricCard(title: "Top Mood", value: viewModel.topMood, subtitle: "Most common emotional tone")
                metricCard(title: "Current Streak", value: "\(viewModel.streak) days", subtitle: "Consecutive writing days")
            }
            .padding()
        }
        .navigationTitle("Insights")
    }

    private func metricCard(title: String, value: String, subtitle: String) -> some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(themeManager.font(.headline, weight: .semibold))
                    .foregroundStyle(themeManager.secondaryTextColor)
                Text(value)
                    .font(themeManager.font(.largeTitle, weight: .bold))
                    .foregroundStyle(themeManager.primaryTextColor)
                Text(subtitle)
                    .font(themeManager.font(.callout))
                    .foregroundStyle(themeManager.secondaryTextColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
