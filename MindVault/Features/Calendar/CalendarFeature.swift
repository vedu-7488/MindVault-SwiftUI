import SwiftUI

protocol CalendarManaging {
    func monthGrid(for date: Date) -> [CalendarDay]
    func monthOffset(from date: Date, value: Int) -> Date
    func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool
}

struct CalendarDay: Identifiable {
    let id = UUID()
    let date: Date
    let isWithinDisplayedMonth: Bool
}

final class CalendarManager: CalendarManaging {
    private let calendar = Calendar.current

    func monthGrid(for date: Date) -> [CalendarDay] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: date),
            let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
            let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end.addingTimeInterval(-1))
        else {
            return []
        }

        var days: [CalendarDay] = []
        var cursor = firstWeek.start
        while cursor < lastWeek.end {
            days.append(CalendarDay(date: cursor, isWithinDisplayedMonth: calendar.isDate(cursor, equalTo: date, toGranularity: .month)))
            cursor = calendar.date(byAdding: .day, value: 1, to: cursor) ?? cursor
        }
        return days
    }

    func monthOffset(from date: Date, value: Int) -> Date {
        calendar.date(byAdding: .month, value: value, to: date) ?? date
    }

    func isSameDay(_ lhs: Date, _ rhs: Date) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }
}

struct CustomCalendarView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var themeManager: ThemeManager
    let selectedDate: Date
    let entryDates: Set<Date>
    let onDateSelected: (Date) -> Void
    let onDateDoubleTapped: (Date) -> Void

    @State private var displayedMonth = Date()

    var body: some View {
        PremiumCard {
            VStack(spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Calendar")
                            .font(themeManager.font(.headline, weight: .semibold))
                            .foregroundStyle(themeManager.secondaryTextColor)
                        Text(displayedMonth.monthTitle)
                            .font(themeManager.font(.title3, weight: .bold))
                            .foregroundStyle(themeManager.primaryTextColor)
                    }
                    Spacer()
                    monthButton("chevron.left", offset: -1)
                    monthButton("chevron.right", offset: 1)
                }

                HStack {
                    ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                        Text(day)
                            .font(themeManager.font(.caption, weight: .medium))
                            .foregroundStyle(themeManager.secondaryTextColor)
                            .frame(maxWidth: .infinity)
                    }
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 7), spacing: 12) {
                    ForEach(container.calendarManager.monthGrid(for: displayedMonth)) { day in
                        dayCell(day)
                    }
                }
            }
        }
        .onAppear {
            displayedMonth = selectedDate
        }
    }

    private func monthButton(_ systemImage: String, offset: Int) -> some View {
        Button {
            withAnimation(.interactiveSpring(response: 0.38, dampingFraction: 0.82)) {
                displayedMonth = container.calendarManager.monthOffset(from: displayedMonth, value: offset)
            }
        } label: {
            Image(systemName: systemImage)
                .font(themeManager.font(.headline, weight: .semibold))
                .foregroundStyle(themeManager.primaryTextColor)
                .frame(width: 34, height: 34)
                .background(themeManager.elevatedFillColor, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func dayCell(_ day: CalendarDay) -> some View {
        let isSelected = container.calendarManager.isSameDay(day.date, selectedDate)
        let hasEntries = entryDates.contains(day.date.strippedToDay())

        return VStack(spacing: 6) {
            Text(day.date.formatted(.dateTime.day()))
                .font(themeManager.font(.subheadline, weight: isSelected ? .bold : .medium))
            Circle()
                .fill(hasEntries ? Color.accentColor : .clear)
                .frame(width: 5, height: 5)
        }
        .foregroundStyle(
            day.isWithinDisplayedMonth
                ? (isSelected ? Color.white : themeManager.primaryTextColor)
                : themeManager.secondaryTextColor.opacity(0.35)
        )
        .frame(maxWidth: .infinity, minHeight: 42)
        .background(isSelected ? Color.accentColor : .clear, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .scaleEffect(isSelected ? 1.03 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.82)) {
                onDateSelected(day.date)
            }
        }
        .onTapGesture(count: 2) {
            withAnimation(.interactiveSpring(response: 0.32, dampingFraction: 0.82)) {
                onDateSelected(day.date)
            }
            onDateDoubleTapped(day.date)
        }
    }
}
