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
    // Generated with Claude. Adjusted to handle a Sunday-first calendar and a time of day in `now`: days are compared at their start in the calendar's time zone.
    public static func days(for days: [WorkoutDay], now: Date, calendar: Calendar) -> [ScheduledDay] {
        let monday = MondayFirstWeek.start(of: now, in: calendar)
        let today = calendar.startOfDay(for: now)
        return (0..<7).map { index in
            let date = calendar.date(byAdding: .day, value: index, to: monday)!
            let workouts = days.first { $0.day == index }?.workouts ?? []
            return ScheduledDay(
                date: date,
                isToday: date == today,
                workouts: workouts.map { scheduled($0, on: date, today: today) }
            )
        }
    }

    private static func scheduled(_ workout: Workout, on date: Date, today: Date) -> ScheduledWorkout {
        ScheduledWorkout(
            id: workout.id,
            title: workout.title,
            exerciseCount: workout.exerciseCount,
            status: status(of: workout, on: date, today: today)
        )
    }

    private static func status(of workout: Workout, on date: Date, today: Date) -> ScheduledWorkout.Status {
        if workout.isCompleted { return .completed }
        if date < today { return .missed }
        if date > today { return .upcoming }
        return .assigned
    }
}
