public final class LocalWorkoutsLoader: WorkoutsLoader {
    private let store: WorkoutsStore

    public init(store: WorkoutsStore) {
        self.store = store
    }

    public func load() async throws -> [WorkoutDay] {
        _ = try await store.retrieve()
        return []
    }
}
