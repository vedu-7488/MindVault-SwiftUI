import SwiftUI

struct CalendarHubView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject var viewModel: JournalViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                CustomCalendarView(
                    selectedDate: session.selectedDate,
                    entryDates: viewModel.entryDates,
                    onDateSelected: { session.selectedDate = $0.strippedToDay() },
                    onDateDoubleTapped: { date in
                        session.selectedDate = date.strippedToDay()
                        viewModel.presentComposer(for: date.strippedToDay())
                    }
                )

                PremiumCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected Day")
                            .font(themeManager.font(.headline, weight: .semibold))
                            .foregroundStyle(themeManager.primaryTextColor)
                        Text(session.selectedDate.dayTitle)
                            .font(themeManager.font(.title3, weight: .bold))
                            .foregroundStyle(themeManager.primaryTextColor)
                        Text("\(viewModel.entries.count) entries and \(viewModel.stickyNotes.count) sticky notes")
                            .font(themeManager.font(.callout))
                            .foregroundStyle(themeManager.secondaryTextColor)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                ForEach(viewModel.entries, id: \.id) { entry in
                    PremiumCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(entry.title)
                                .font(themeManager.font(.headline, weight: .semibold))
                                .foregroundStyle(themeManager.primaryTextColor)
                            Text(entry.bodyText)
                                .font(themeManager.font(.body))
                                .foregroundStyle(themeManager.secondaryTextColor)
                                .lineLimit(3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Calendar")
        .foregroundStyle(themeManager.primaryTextColor)
        .task(id: session.selectedDate) {
            viewModel.load(for: session.selectedDate)
        }
        .fullScreenCover(item: $viewModel.activeDraft) { draft in
            JournalEditorView(draft: draft) { savedDraft in
                viewModel.saveDraft(savedDraft)
                session.activeTab = .journal
            } onDelete: { deletingDraft in
                viewModel.deleteEntry(deletingDraft)
                session.activeTab = .journal
            }
        }
    }
}
