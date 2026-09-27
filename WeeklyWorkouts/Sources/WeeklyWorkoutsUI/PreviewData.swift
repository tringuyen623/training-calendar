import WeeklyWorkouts

/// The design's sample week: Monday 20 to Sunday 26, Friday is today.
enum PreviewData {
    static let missed = WorkoutCardViewData(id: "mon-1", title: "Legs day", statusText: "Missed", exerciseCount: "5 exercises", status: .missed)
    static let completed = WorkoutCardViewData(id: "tue-1", title: "Full warm up workout", statusText: "Completed", exerciseCount: "8 exercises", status: .completed)
    static let missedLongTitle = WorkoutCardViewData(id: "thu-1", title: "Chest and shoulder workout", statusText: "Missed", exerciseCount: "9 exercises", status: .missed)
    static let assigned = WorkoutCardViewData(id: "fri-1", title: "Legs day", statusText: nil, exerciseCount: "7 exercises", status: .assigned)
    static let assignedSecond = WorkoutCardViewData(id: "fri-2", title: "HIIT Tabata 20:10 8x8", statusText: nil, exerciseCount: "15 exercises", status: .assigned)
    static let upcoming = WorkoutCardViewData(id: "sun-1", title: "Squat, press, power clean", statusText: nil, exerciseCount: "6 exercises", status: .upcoming)

    static let completedUpcoming = WorkoutCardViewData(id: "sun-2", title: "Squat, press, power clean", statusText: "Completed", exerciseCount: "6 exercises", status: .completed)
    static let singleExercise = WorkoutCardViewData(id: "sat-1", title: "Mobility", statusText: nil, exerciseCount: "1 exercise", status: .assigned)
    static let veryLongTitle = "Full body strength and conditioning with a very long title"

    static let week: [DayViewData] = [
        DayViewData(id: 0, weekday: "Mon", dayNumber: "20", isToday: false, workouts: [missed]),
        DayViewData(id: 1, weekday: "Tue", dayNumber: "21", isToday: false, workouts: [completed]),
        DayViewData(id: 2, weekday: "Wed", dayNumber: "22", isToday: false, workouts: []),
        DayViewData(id: 3, weekday: "Thu", dayNumber: "23", isToday: false, workouts: [missedLongTitle]),
        DayViewData(id: 4, weekday: "Fri", dayNumber: "24", isToday: true, workouts: [assigned, assignedSecond]),
        DayViewData(id: 5, weekday: "Sat", dayNumber: "25", isToday: false, workouts: []),
        DayViewData(id: 6, weekday: "Sun", dayNumber: "26", isToday: false, workouts: [upcoming]),
    ]

    static let emptyWeek: [DayViewData] = week.map {
        DayViewData(id: $0.id, weekday: $0.weekday, dayNumber: $0.dayNumber, isToday: $0.isToday, workouts: [])
    }

    static func card(_ card: WorkoutCardViewData, title: String) -> WorkoutCardViewData {
        WorkoutCardViewData(id: card.id, title: title, statusText: card.statusText, exerciseCount: card.exerciseCount, status: card.status)
    }
}
