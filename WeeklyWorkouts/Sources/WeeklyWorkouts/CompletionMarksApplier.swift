public final class CompletionMarksApplier {
    private let marksStore: CompletionMarksStore

    public init(marksStore: CompletionMarksStore) {
        self.marksStore = marksStore
    }

    public func apply(to days: [WorkoutDay]) async throws -> [WorkoutDay] {
        let marks = try await marksStore.retrieveAllMarks()
        return days.map { day in
            WorkoutDay(id: day.id, day: day.day, workouts: day.workouts.map { workout in
                guard let isCompleted = marks[workout.id] else {
                    return workout
                }
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
