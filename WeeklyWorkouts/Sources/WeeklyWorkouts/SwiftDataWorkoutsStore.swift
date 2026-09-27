import Foundation
import SwiftData

@ModelActor
public actor SwiftDataWorkoutsStore: WorkoutsStore {
    public static let models: [any PersistentModel.Type] = [ManagedCache.self]

    public func retrieve() async throws -> CachedWorkouts? {
        nil
    }

    public func deleteCachedWorkouts() async throws {}

    public func insert(_ days: [WorkoutDay], timestamp: Date) async throws {}
}

@Model
private final class ManagedCache {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
