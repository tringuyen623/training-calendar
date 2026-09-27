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
        try await store.retrieve()?.days ?? []
    }
}
