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
        guard let cache = try await store.retrieve(), isInCurrentWeek(cache.timestamp) else {
            return []
        }
        return cache.days
    }

    private func isInCurrentWeek(_ timestamp: Date) -> Bool {
        var calendar = calendar
        calendar.firstWeekday = 2
        return calendar.isDate(timestamp, equalTo: currentDate(), toGranularity: .weekOfYear)
    }
}
