import Foundation
import WeeklyWorkouts

func uniqueDays() -> (models: [WorkoutDay], local: [LocalWorkoutDay]) {
    let mondayID = UUID().uuidString
    let fridayID = UUID().uuidString
    let assignedID = UUID().uuidString
    let missedID = UUID().uuidString
    let completedID = UUID().uuidString
    let models = [
        WorkoutDay(id: mondayID, day: 0, workouts: [
            Workout(id: assignedID, title: "any title", status: .assigned, exerciseCount: 5),
            Workout(id: missedID, title: "another title", status: .missed, exerciseCount: 3),
            Workout(id: completedID, title: "a third title", status: .completed, exerciseCount: 8),
        ]),
        WorkoutDay(id: fridayID, day: 4, workouts: []),
    ]
    let local = [
        LocalWorkoutDay(id: mondayID, day: 0, workouts: [
            LocalWorkout(id: assignedID, title: "any title", status: .assigned, exerciseCount: 5),
            LocalWorkout(id: missedID, title: "another title", status: .missed, exerciseCount: 3),
            LocalWorkout(id: completedID, title: "a third title", status: .completed, exerciseCount: 8),
        ]),
        LocalWorkoutDay(id: fridayID, day: 4, workouts: []),
    ]
    return (models, local)
}

func anyNSError() -> NSError {
    NSError(domain: "any error", code: 0)
}

func uniqueCache(savedAt timestamp: Date) -> (models: [WorkoutDay], local: CachedWorkouts) {
    let days = uniqueDays()
    return (days.models, CachedWorkouts(days: days.local, timestamp: timestamp))
}

/// The cached form of `days`, for tests that build or check what the store holds.
/// The cache use case tests pin this mapping with the explicit pairs of `uniqueDays()`.
func local(_ days: [WorkoutDay]) -> [LocalWorkoutDay] {
    days.map { day in
        LocalWorkoutDay(id: day.id, day: day.day, workouts: day.workouts.map { workout in
            LocalWorkout(id: workout.id, title: workout.title, status: local(workout.status), exerciseCount: workout.exerciseCount)
        })
    }
}

private func local(_ status: Workout.Status) -> LocalWorkout.Status {
    switch status {
    case .assigned: .assigned
    case .missed: .missed
    case .completed: .completed
    }
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
