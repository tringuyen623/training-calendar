/// Saves the inverted completion as the workout's mark and delivers it.
@MainActor
public protocol CompletionToggler {
    func toggle(workoutID: String, isCompleted: Bool) async throws -> Bool
}
