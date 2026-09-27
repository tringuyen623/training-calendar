import Foundation

public final class LocalWorkoutsLoader: WorkoutsLoader {
    private let store: WorkoutsStore
    private let calendar: Calendar
    private let currentDate: () -> Date

    public init(store: WorkoutsStore, calendar: Calendar, currentDate: @escaping () -> Date) {
        self.store = store
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
}
