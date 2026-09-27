import Foundation

enum MondayFirstWeek {
    private static let monday = 2

    // Generated with Claude. Adjusted to handle Sunday-first calendars, weeks spanning the year boundary and the calendar's time zone.
    static func start(of date: Date, in calendar: Calendar) -> Date {
        var calendar = calendar
        calendar.firstWeekday = monday
        return calendar.dateInterval(of: .weekOfYear, for: date)!.start
    }
}
