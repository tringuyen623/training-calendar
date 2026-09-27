import Foundation

public struct CachedWorkouts: Equatable, Sendable {
    public let days: [WorkoutDay]
    public let timestamp: Date

    public init(days: [WorkoutDay], timestamp: Date) {
        self.days = days
        self.timestamp = timestamp
    }
}

public protocol WorkoutsStore {
    func retrieve() async throws -> CachedWorkouts?
}
