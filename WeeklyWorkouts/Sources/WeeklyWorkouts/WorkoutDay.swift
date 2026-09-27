public struct WorkoutDay: Equatable {
    public let id: String
    public let day: Int
    public let workouts: [Workout]

    public init(id: String, day: Int, workouts: [Workout]) {
        self.id = id
        self.day = day
        self.workouts = workouts
    }
}

public struct Workout: Equatable {
    public enum Status: Equatable {
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
}
