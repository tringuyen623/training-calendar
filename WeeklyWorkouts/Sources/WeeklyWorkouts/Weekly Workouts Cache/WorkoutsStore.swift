import Foundation

public struct CachedWorkouts: Equatable, Sendable {
    public let days: [LocalWorkoutDay]
    public let timestamp: Date

    public init(days: [LocalWorkoutDay], timestamp: Date) {
        self.days = days
        self.timestamp = timestamp
    }
}

public protocol WorkoutsStore {
    func retrieve() async throws -> CachedWorkouts?
    func deleteCachedWorkouts() async throws
    func insert(_ days: [LocalWorkoutDay], timestamp: Date) async throws

    /// Delivers a value each time the stored workouts change, until the caller stops iterating.
    func changes() async -> AsyncStream<Void>
}
