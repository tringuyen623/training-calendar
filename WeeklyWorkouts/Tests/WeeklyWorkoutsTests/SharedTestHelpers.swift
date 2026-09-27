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
