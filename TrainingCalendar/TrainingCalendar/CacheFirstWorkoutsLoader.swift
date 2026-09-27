import WeeklyWorkouts

/// Delivers the cached week with its completion marks right away and refreshes it from remote in the background.
/// With nothing cached, it waits for remote, so a remote failure reaches the caller.
final class CacheFirstWorkoutsLoader: WorkoutsLoader {
    private let local: LocalWorkoutsLoader
    private let remote: WorkoutsLoader
    private let marksApplier: CompletionMarksApplier

    init(local: LocalWorkoutsLoader, remote: WorkoutsLoader, marksApplier: CompletionMarksApplier) {
        self.local = local
        self.remote = remote
        self.marksApplier = marksApplier
    }

    // Explicitly main-actor: otherwise the witness is inferred nonisolated to match the protocol,
    // and it couldn't use the loaders it stores.
    @MainActor func load() async throws -> [WorkoutDay] {
        let cached = try await marksApplier.apply(to: local.load())
        guard cached.isEmpty else {
            // A failed refresh keeps the cached week on screen without an error; a successful one reaches the
            // screen through the store's change notification.
            Task { _ = try? await refresh() }
            return cached
        }
        return try await marksApplier.apply(to: refresh())
    }

    private func refresh() async throws -> [WorkoutDay] {
        let days = try await remote.load()
        try await local.save(days)
        return days
    }
}
