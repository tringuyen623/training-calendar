public final class CompletionMarksApplier {
    private let marksStore: CompletionMarksStore

    public init(marksStore: CompletionMarksStore) {
        self.marksStore = marksStore
    }

    public func apply(to days: [WorkoutDay]) async throws -> [WorkoutDay] {
        _ = try await marksStore.retrieveAllMarks()
        return days
    }
}
