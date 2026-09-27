public final class WorkoutCompletionToggler {
    private let marksStore: CompletionMarksStore

    public init(marksStore: CompletionMarksStore) {
        self.marksStore = marksStore
    }

    public func toggle(workoutID: String, isCompleted: Bool) async throws -> Bool {
        let newCompletion = !isCompleted
        try await marksStore.insertMark(newCompletion, for: workoutID)
        return newCompletion
    }
}
