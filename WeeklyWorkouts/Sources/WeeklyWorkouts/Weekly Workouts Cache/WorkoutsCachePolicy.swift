import Foundation

enum WorkoutsCachePolicy {
    static func validate(_ timestamp: Date, against date: Date, in calendar: Calendar) -> Bool {
        MondayFirstWeek.start(of: timestamp, in: calendar) == MondayFirstWeek.start(of: date, in: calendar)
    }
}
