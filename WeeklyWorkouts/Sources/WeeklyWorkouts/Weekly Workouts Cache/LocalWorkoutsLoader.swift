import Foundation

final class LocalWorkoutsLoader {
    private let store: WorkoutsStore
    private let marksStore: CompletionMarksStore
    private let calendar: Calendar
    private let currentDate: () -> Date

    init(store: WorkoutsStore, marksStore: CompletionMarksStore, calendar: Calendar, currentDate: @escaping () -> Date) {
        self.store = store
        self.marksStore = marksStore
        self.calendar = calendar
        self.currentDate = currentDate
    }

    func load() async throws -> [WorkoutDay] {
        guard let cache = try await store.retrieve(), isFromCurrentWeek(cache) else {
            return []
        }
        return cache.days.toModels()
    }

    func save(_ days: [WorkoutDay]) async throws {
        try await store.deleteCachedWorkouts()
        try await store.insert(days.toLocal(), timestamp: currentDate())
    }

    func validateCache() async throws {
        if try await hasExpiredCache() {
            try await deleteExpiredCache()
        }
    }

    private func hasExpiredCache() async throws -> Bool {
        guard let cache = try await store.retrieve() else {
            return false
        }
        return !isFromCurrentWeek(cache)
    }

    // Marks go first: if deleting them fails, the expired cache stays, so the next validation retries both.
    private func deleteExpiredCache() async throws {
        try await marksStore.deleteAllMarks()
        try await store.deleteCachedWorkouts()
    }

    private func isFromCurrentWeek(_ cache: CachedWorkouts) -> Bool {
        WorkoutsCachePolicy.validate(cache.timestamp, against: currentDate(), in: calendar)
    }
}

private extension Array where Element == WorkoutDay {
    func toLocal() -> [LocalWorkoutDay] {
        map { day in
            LocalWorkoutDay(id: day.id, day: day.day, workouts: day.workouts.map { workout in
                LocalWorkout(id: workout.id, title: workout.title, status: workout.status.toLocal(), exerciseCount: workout.exerciseCount)
            })
        }
    }
}

private extension Array where Element == LocalWorkoutDay {
    func toModels() -> [WorkoutDay] {
        map { day in
            WorkoutDay(id: day.id, day: day.day, workouts: day.workouts.map { workout in
                Workout(id: workout.id, title: workout.title, status: workout.status.toModel(), exerciseCount: workout.exerciseCount)
            })
        }
    }
}

private extension Workout.Status {
    func toLocal() -> LocalWorkout.Status {
        switch self {
        case .assigned: .assigned
        case .missed: .missed
        case .completed: .completed
        }
    }
}

private extension LocalWorkout.Status {
    func toModel() -> Workout.Status {
        switch self {
        case .assigned: .assigned
        case .missed: .missed
        case .completed: .completed
        }
    }
}
