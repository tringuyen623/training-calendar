import Foundation

public typealias WeeklyWorkoutsStore = WorkoutsStore & CompletionMarksStore

/// Loads the week screen's workouts: the cached week first, refreshed from the API, with the local completion marks applied on the way out.
@MainActor
public final class WeeklyWorkoutsService {
    private let url: URL
    private let client: HTTPClient
    private let store: WeeklyWorkoutsStore
    private let local: LocalWorkoutsLoader
    /// The background refresh started by the last `loadWeek()` that delivered the cached week.
    private(set) var refreshTask: Task<Void, Never>?

    public enum Error: Swift.Error, Equatable {
        case requestFailure
        case invalidData
    }

    public init(url: URL, client: HTTPClient, store: WeeklyWorkoutsStore, calendar: Calendar, currentDate: @escaping () -> Date) {
        self.url = url
        self.client = client
        self.store = store
        self.local = LocalWorkoutsLoader(store: store, marksStore: store, calendar: calendar, currentDate: currentDate)
    }

    public func loadWeek() async throws -> [WorkoutDay] {
        let cached = await cachedWeek()
        guard cached.isEmpty else {
            let week = try await applyingMarks(to: cached)
            // A failed refresh keeps the cached week on screen without an error; a successful one
            // reaches the screen through the store's change notification.
            refreshTask = Task { _ = try? await refresh() }
            return week
        }
        return try await applyingMarks(to: refresh())
    }

    public func loadCachedWeek() async throws -> [WorkoutDay] {
        try await applyingMarks(to: local.load())
    }

    /// Whether the week must be loaded: there's no cached week for the current week, so `loadWeek()` would wait for the API.
    /// Only reads the cache, so asking never requests the API or writes.
    public func needsLoading() async -> Bool {
        await cachedWeek().isEmpty
    }

    public func validateCache() async throws {
        try await local.validateCache()
    }

    /// The cached week of the current week, or no days when there's none.
    /// An unreadable cache counts as no cached week: the API load replaces it, and its failure reaches the caller.
    private func cachedWeek() async -> [WorkoutDay] {
        (try? await local.load()) ?? []
    }

    /// Loads the week from the API and replaces the cache with it, unmarked.
    private func refresh() async throws -> [WorkoutDay] {
        let (data, response) = try await fetch()
        let days = try map(data, from: response)
        // The loaded week is still delivered when saving fails: the next load saves it again.
        try? await local.save(days)
        return days
    }

    private func fetch() async throws -> (Data, HTTPURLResponse) {
        do {
            return try await client.get(from: url)
        } catch let cancellation as CancellationError {
            throw cancellation
        } catch {
            throw Error.requestFailure
        }
    }

    private func map(_ data: Data, from response: HTTPURLResponse) throws -> [WorkoutDay] {
        do {
            return try WorkoutDaysMapper.map(data, from: response)
        } catch {
            throw Error.invalidData
        }
    }

    /// Marks are applied only on the way out, so they never reach the cache.
    private func applyingMarks(to days: [WorkoutDay]) async throws -> [WorkoutDay] {
        days.applying(try await store.retrieveAllMarks())
    }
}
