import Foundation

public struct ScheduledDay: Equatable, Sendable {
    public let date: Date
    public let isToday: Bool
    public let workouts: [ScheduledWorkout]
}

public struct ScheduledWorkout: Equatable, Sendable {
    public enum Status: Equatable, Sendable {
        case missed
        case assigned
        case completed
        case upcoming
    }

    public let id: String
    public let title: String
    public let exerciseCount: Int
    public let status: Status
}

public enum WeekSchedule {
    public static func days(for days: [WorkoutDay], now: Date, calendar: Calendar) -> [ScheduledDay] {
        let monday = MondayFirstWeek.start(of: now, in: calendar)
        return (0..<7).map { index in
            let workouts = days.first { $0.day == index }?.workouts ?? []
            return ScheduledDay(
                date: calendar.date(byAdding: .day, value: index, to: monday)!,
                isToday: false,
                workouts: workouts.map { ScheduledWorkout(id: $0.id, title: $0.title, exerciseCount: $0.exerciseCount, status: .assigned) }
            )
        }
    }
}
