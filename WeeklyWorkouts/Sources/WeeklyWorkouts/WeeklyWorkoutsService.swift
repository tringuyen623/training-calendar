import Foundation

public typealias WeeklyWorkoutsStore = WorkoutsStore & CompletionMarksStore

@MainActor
public final class WeeklyWorkoutsService {
    private let url: URL
    private let client: HTTPClient
    private let store: WeeklyWorkoutsStore
    private let local: LocalWorkoutsLoader

    public enum Error: Swift.Error, Equatable {
        case requestFailure
    }

    public init(url: URL, client: HTTPClient, store: WeeklyWorkoutsStore, calendar: Calendar, currentDate: @escaping () -> Date) {
        self.url = url
        self.client = client
        self.store = store
        self.local = LocalWorkoutsLoader(store: store, marksStore: store, calendar: calendar, currentDate: currentDate)
    }

    public func loadWeek() async throws -> [WorkoutDay] {
        _ = try await fetch()
        return []
    }

    private func fetch() async throws -> (Data, HTTPURLResponse) {
        do {
            return try await client.get(from: url)
        } catch {
            throw Error.requestFailure
        }
    }
}
