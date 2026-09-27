public final class WorkoutCompletionToggler {
    private let marksStore: CompletionMarksStore

    public init(marksStore: CompletionMarksStore) {
        self.marksStore = marksStore
    }

    public func toggle(workoutID: String, isCompleted: Bool) async throws -> Bool {
        try await marksStore.insertMark(!isCompleted, for: workoutID)
        return isCompleted
    }
}
