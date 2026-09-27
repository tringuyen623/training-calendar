public final class CompletionMarksApplier {
    private let marksStore: CompletionMarksStore

    public init(marksStore: CompletionMarksStore) {
        self.marksStore = marksStore
    }

    public func apply(to days: [WorkoutDay]) async throws -> [WorkoutDay] {
        let marks = try await marksStore.retrieveAllMarks()
        return days.map { day in
            WorkoutDay(id: day.id, day: day.day, workouts: day.workouts.map { workout in
                Workout(
                    id: workout.id,
                    title: workout.title,
                    status: marks[workout.id] == true ? .completed : workout.status,
                    exerciseCount: workout.exerciseCount
                )
            })
        }
    }
}
