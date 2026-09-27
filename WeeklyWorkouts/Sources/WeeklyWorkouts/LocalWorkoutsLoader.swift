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
        guard let cache = try await store.retrieve(),
              WorkoutsCachePolicy.validate(cache.timestamp, against: currentDate(), in: calendar) else {
            return []
        }
        return cache.days
    }

    public func save(_ days: [WorkoutDay]) async throws {
        try await store.deleteCachedWorkouts()
        try await store.insert(days, timestamp: currentDate())
    }

    public func validateCache() async throws {
        do {
            _ = try await store.retrieve()
        } catch {
            try await store.deleteCachedWorkouts()
        }
    }
}
