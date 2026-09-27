import Foundation

public final class LocalWorkoutsLoader: WorkoutsLoader {
    private let store: WorkoutsStore
    private let marksStore: CompletionMarksStore
    private let calendar: Calendar
    private let currentDate: () -> Date

    public init(store: WorkoutsStore, marksStore: CompletionMarksStore, calendar: Calendar, currentDate: @escaping () -> Date) {
        self.store = store
        self.marksStore = marksStore
        self.calendar = calendar
        self.currentDate = currentDate
    }

    public func load() async throws -> [WorkoutDay] {
        guard let cache = try await store.retrieve(), isFromCurrentWeek(cache) else {
            return []
        }
        return cache.days
    }

    public func save(_ days: [WorkoutDay]) async throws {
        try await store.deleteCachedWorkouts()
        try await store.insert(days, timestamp: currentDate())
    }

    public func validateCache() async throws {
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
