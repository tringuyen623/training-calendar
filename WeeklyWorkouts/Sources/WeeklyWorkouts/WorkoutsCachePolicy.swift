import Foundation

enum WorkoutsCachePolicy {
    private static let monday = 2

    // Generated with Claude. Adjusted to handle Sunday-first calendars, weeks spanning the year boundary and the calendar's time zone.
    static func validate(_ timestamp: Date, against date: Date, in calendar: Calendar) -> Bool {
        var calendar = calendar
        calendar.firstWeekday = monday
        return calendar.isDate(timestamp, equalTo: date, toGranularity: .weekOfYear)
    }
}
