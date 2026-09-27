import Foundation
import SwiftData

@ModelActor
public actor SwiftDataWorkoutsStore: WorkoutsStore {
    public static let models: [any PersistentModel.Type] = [ManagedCache.self, ManagedDay.self, ManagedWorkout.self]

    public func retrieve() async throws -> CachedWorkouts? {
        try modelContext.fetch(FetchDescriptor<ManagedCache>()).first.map { $0.local }
    }

    public func deleteCachedWorkouts() async throws {}

    public func insert(_ days: [WorkoutDay], timestamp: Date) async throws {
        for cache in try modelContext.fetch(FetchDescriptor<ManagedCache>()) {
            modelContext.delete(cache)
        }
        modelContext.insert(ManagedCache(timestamp: timestamp, days: days.enumerated().map(ManagedDay.init)))
        try modelContext.save()
    }
}

@Model
private final class ManagedCache {
    var timestamp: Date
    @Relationship(deleteRule: .cascade) var days: [ManagedDay]

    init(timestamp: Date, days: [ManagedDay]) {
        self.timestamp = timestamp
        self.days = days
    }

    var local: CachedWorkouts {
        CachedWorkouts(days: days.sorted { $0.position < $1.position }.map(\.local), timestamp: timestamp)
    }
}

@Model
private final class ManagedDay {
    var position: Int
    var id: String
    var day: Int
    @Relationship(deleteRule: .cascade) var workouts: [ManagedWorkout]

    init(position: Int, day: WorkoutDay) {
        self.position = position
        self.id = day.id
        self.day = day.day
        self.workouts = day.workouts.enumerated().map(ManagedWorkout.init)
    }

    var local: WorkoutDay {
        WorkoutDay(id: id, day: day, workouts: workouts.sorted { $0.position < $1.position }.map(\.local))
    }
}

@Model
private final class ManagedWorkout {
    var position: Int
    var id: String
    var title: String
    var status: Int
    var exerciseCount: Int

    init(position: Int, workout: Workout) {
        self.position = position
        self.id = workout.id
        self.title = workout.title
        self.status = switch workout.status {
        case .assigned: 0
        case .missed: 1
        case .completed: 2
        }
        self.exerciseCount = workout.exerciseCount
    }

    var local: Workout {
        Workout(id: id, title: title, status: status == 0 ? .assigned : status == 1 ? .missed : .completed, exerciseCount: exerciseCount)
    }
}
