import Foundation
import SwiftData

@ModelActor
public actor SwiftDataWorkoutsStore: WorkoutsStore {
    public static let models: [any PersistentModel.Type] = [ManagedCache.self, ManagedDay.self, ManagedWorkout.self, ManagedCompletionMark.self]

    private var changeObservers: [UUID: AsyncStream<Void>.Continuation] = [:]

    public func retrieve() async throws -> CachedWorkouts? {
        try modelContext.fetch(FetchDescriptor<ManagedCache>()).first.map { try $0.toModel() }
    }

    public func deleteCachedWorkouts() async throws {
        try saveOrRollback {
            try deleteCache()
        }
        notifyChange()
    }

    public func insert(_ days: [WorkoutDay], timestamp: Date) async throws {
        try saveOrRollback {
            try deleteCache()
            modelContext.insert(ManagedCache(timestamp: timestamp, days: days.enumerated().map(ManagedDay.init)))
        }
        notifyChange()
    }

    // A slow observer gets one pending notification, not one per change: it only needs to read the store again.
    public func changes() async -> AsyncStream<Void> {
        let (changes, observer) = AsyncStream.makeStream(of: Void.self, bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        changeObservers[id] = observer
        observer.onTermination = { [weak self] _ in
            Task { await self?.removeChangeObserver(id) }
        }
        return changes
    }

    private func removeChangeObserver(_ id: UUID) {
        changeObservers[id] = nil
    }

    private func notifyChange() {
        for observer in changeObservers.values {
            observer.yield()
        }
    }

    // One save per operation, so it's never half-written. On failure the context drops the unsaved changes:
    // otherwise later retrieves would see them and the next save would commit them.
    private func saveOrRollback(_ changes: () throws -> Void) throws {
        do {
            try changes()
            try modelContext.save()
        } catch {
            modelContext.rollback()
            throw error
        }
    }

    // Deletes only the cache roots: their days and workouts go with them by cascade, and other models are never touched.
    private func deleteCache() throws {
        for cache in try modelContext.fetch(FetchDescriptor<ManagedCache>()) {
            modelContext.delete(cache)
        }
    }
}

extension SwiftDataWorkoutsStore: CompletionMarksStore {
    public func deleteAllMarks() async throws {
        try saveOrRollback {
            try modelContext.delete(model: ManagedCompletionMark.self)
        }
    }

    public func insertMark(_ isCompleted: Bool, for workoutID: String) async throws {
        try saveOrRollback {
            try modelContext.delete(model: ManagedCompletionMark.self, where: #Predicate { $0.workoutID == workoutID })
            modelContext.insert(ManagedCompletionMark(workoutID: workoutID, isCompleted: isCompleted))
        }
    }

    public func retrieveAllMarks() async throws -> [String: Bool] {
        let marks = try modelContext.fetch(FetchDescriptor<ManagedCompletionMark>())
        return Dictionary(uniqueKeysWithValues: marks.map { ($0.workoutID, $0.isCompleted) })
    }
}

@Model
private final class ManagedCompletionMark {
    var workoutID: String
    var isCompleted: Bool

    init(workoutID: String, isCompleted: Bool) {
        self.workoutID = workoutID
        self.isCompleted = isCompleted
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

    func toModel() throws -> CachedWorkouts {
        CachedWorkouts(days: try days.sorted { $0.position < $1.position }.map { try $0.toModel() }, timestamp: timestamp)
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

    func toModel() throws -> WorkoutDay {
        WorkoutDay(id: id, day: day, workouts: try workouts.sorted { $0.position < $1.position }.map { try $0.toModel() })
    }
}

@Model
private final class ManagedWorkout {
    var position: Int
    var id: String
    var title: String
    var statusCode: Int
    var exerciseCount: Int

    init(position: Int, workout: Workout) {
        self.position = position
        self.id = workout.id
        self.title = workout.title
        self.statusCode = workout.status.storedCode
        self.exerciseCount = workout.exerciseCount
    }

    func toModel() throws -> Workout {
        guard let status = Workout.Status(storedCode: statusCode) else {
            throw UnknownStatusCode()
        }
        return Workout(id: id, title: title, status: status, exerciseCount: exerciseCount)
    }

    private struct UnknownStatusCode: Error {}
}

private extension Workout.Status {
    var storedCode: Int {
        switch self {
        case .assigned: 0
        case .missed: 1
        case .completed: 2
        }
    }

    init?(storedCode: Int) {
        switch storedCode {
        case 0: self = .assigned
        case 1: self = .missed
        case 2: self = .completed
        default: return nil
        }
    }
}
