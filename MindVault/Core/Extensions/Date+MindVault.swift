import Foundation

extension Date {
    var monthTitle: String {
        formatted(.dateTime.month(.wide).year())
    }

    var dayTitle: String {
        formatted(.dateTime.weekday(.wide).day().month(.abbreviated))
    }

    func strippedToDay(using calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }
}
