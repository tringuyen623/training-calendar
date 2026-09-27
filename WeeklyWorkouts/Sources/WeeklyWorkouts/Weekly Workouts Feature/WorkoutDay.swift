public struct WorkoutDay: Equatable, Sendable {
    public let id: String
    public let day: Int
    public let workouts: [Workout]

    public init(id: String, day: Int, workouts: [Workout]) {
        self.id = id
        self.day = day
        self.workouts = workouts
    }
}

public struct Workout: Equatable, Sendable {
    public enum Status: Equatable, Sendable {
        case assigned
        case missed
        case completed
    }

    public let id: String
    public let title: String
    public let status: Status
    public let exerciseCount: Int

    public init(id: String, title: String, status: Status, exerciseCount: Int) {
        self.id = id
        self.title = title
        self.status = status
        self.exerciseCount = exerciseCount
    }

    var isCompleted: Bool {
        status == .completed
    }
}

extension Array where Element == WorkoutDay {
    // Generated with Claude. Adjusted to handle a "not completed" mark on a workout the server reports as completed.
    // Marks are looked up by workout ID, so marks for workouts not in the week are never used.
    /// The week with the local completion marks applied: a mark wins over the server status; unmarked workouts keep it.
    func applying(_ marks: [String: Bool]) -> [WorkoutDay] {
        map { day in
            WorkoutDay(id: day.id, day: day.day, workouts: day.workouts.map { workout in
                guard let isCompleted = marks[workout.id] else { return workout }
                return Workout(
                    id: workout.id,
                    title: workout.title,
                    status: isCompleted ? .completed : .assigned,
                    exerciseCount: workout.exerciseCount
                )
            })
        }
    }
}
