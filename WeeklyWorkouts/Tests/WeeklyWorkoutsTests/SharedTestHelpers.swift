import Foundation
import WeeklyWorkouts

func uniqueDays() -> [WorkoutDay] {
    [
        WorkoutDay(id: UUID().uuidString, day: 0, workouts: [
            Workout(id: UUID().uuidString, title: "any title", status: .assigned, exerciseCount: 5),
        ]),
        WorkoutDay(id: UUID().uuidString, day: 4, workouts: []),
    ]
}

func anyNSError() -> NSError {
    NSError(domain: "any error", code: 0)
}

func uniqueCache(savedAt timestamp: Date) -> CachedWorkouts {
    CachedWorkouts(days: uniqueDays(), timestamp: timestamp)
}

func makeCalendar() -> Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
    calendar.firstWeekday = 2
    return calendar
}

func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0) -> Date {
    makeCalendar().date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))!
}
