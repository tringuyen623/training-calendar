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
        let cache: CachedWorkouts?
        do {
            cache = try await store.retrieve()
        } catch {
            try await store.deleteCachedWorkouts()
            return
        }

        guard let cache, !isFromCurrentWeek(cache) else {
            return
        }
        try await marksStore.deleteAllMarks()
        try await store.deleteCachedWorkouts()
    }

    private func isFromCurrentWeek(_ cache: CachedWorkouts) -> Bool {
        WorkoutsCachePolicy.validate(cache.timestamp, against: currentDate(), in: calendar)
    }
}
