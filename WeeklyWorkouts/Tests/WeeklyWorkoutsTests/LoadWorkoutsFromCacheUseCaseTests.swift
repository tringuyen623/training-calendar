import Foundation
import Testing
import WeeklyWorkouts

struct LoadWorkoutsFromCacheUseCaseTests {
    @Test func init_doesNotMessageStoreUponCreation() {
        let (_, store) = makeSUT()

        #expect(store.receivedMessages.isEmpty)
    }

    @Test func load_requestsCacheRetrieval() async {
        let (sut, store) = makeSUT()

        _ = try? await sut.load()

        #expect(store.receivedMessages == [.retrieve])
    }

    @Test func loadTwice_requestsCacheRetrievalTwice() async {
        let (sut, store) = makeSUT()

        _ = try? await sut.load()
        _ = try? await sut.load()

        #expect(store.receivedMessages == [.retrieve, .retrieve])
    }

    @Test func load_failsOnRetrievalError() async {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()
        store.stubRetrieval(with: retrievalError)

        await #expect {
            try await sut.load()
        } throws: { error in
            error as NSError == retrievalError
        }
    }

    @Test func load_deliversNoWorkoutsOnEmptyCache() async throws {
        let (sut, store) = makeSUT()
        store.stubEmptyCache()

        let days = try await sut.load()

        #expect(days.isEmpty)
    }

    @Test func load_deliversCachedWorkoutsOnCacheSavedInCurrentWeek() async throws {
        let now = date(2026, 10, 2, 9, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        let days = uniqueDays()
        store.stubRetrieval(with: CachedWorkouts(days: days, timestamp: date(2026, 9, 30, 18, 0)))

        let receivedDays = try await sut.load()

        #expect(receivedDays == days)
    }

    @Test func load_deliversNoWorkoutsOnCacheSavedAtEndOfPreviousWeek() async throws {
        let now = date(2026, 9, 28, 0, 0, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        store.stubRetrieval(with: CachedWorkouts(days: uniqueDays(), timestamp: date(2026, 9, 27, 23, 59, 59)))

        let receivedDays = try await sut.load()

        #expect(receivedDays.isEmpty)
    }

    @Test func load_deliversCachedWorkoutsOnCacheSavedAtStartOfCurrentWeek() async throws {
        let now = date(2026, 9, 30, 12, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        let days = uniqueDays()
        store.stubRetrieval(with: CachedWorkouts(days: days, timestamp: date(2026, 9, 28, 0, 0, 0)))

        let receivedDays = try await sut.load()

        #expect(receivedDays == days)
    }

    @Test func load_deliversCachedWorkoutsOnSundayForCacheSavedOnMondayOfSameWeek() async throws {
        let now = date(2026, 10, 4, 23, 59, 59)
        let (sut, store) = makeSUT(currentDate: { now })
        let days = uniqueDays()
        store.stubRetrieval(with: CachedWorkouts(days: days, timestamp: date(2026, 9, 28, 0, 0, 0)))

        let receivedDays = try await sut.load()

        #expect(receivedDays == days)
    }

    @Test func load_deliversNoWorkoutsOnCacheSavedInPreviousWeekLessThanSevenDaysAgo() async throws {
        let now = date(2026, 9, 29, 9, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        store.stubRetrieval(with: CachedWorkouts(days: uniqueDays(), timestamp: date(2026, 9, 25, 18, 0)))

        let receivedDays = try await sut.load()

        #expect(receivedDays.isEmpty)
    }

    @Test func load_deliversCachedWorkoutsOnCacheSavedInWeekSpanningYearBoundary() async throws {
        let now = date(2027, 1, 2, 9, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        let days = uniqueDays()
        store.stubRetrieval(with: CachedWorkouts(days: days, timestamp: date(2026, 12, 31, 18, 0)))

        let receivedDays = try await sut.load()

        #expect(receivedDays == days)
    }

    @Test func load_deliversNoWorkoutsOnCacheSavedInSameWeekOfPreviousYear() async throws {
        let now = date(2026, 9, 30, 12, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        let fiftyTwoWeeksEarlier = date(2025, 10, 1, 12, 0)
        store.stubRetrieval(with: CachedWorkouts(days: uniqueDays(), timestamp: fiftyTwoWeeksEarlier))

        let receivedDays = try await sut.load()

        #expect(receivedDays.isEmpty)
    }

    @Test func load_deliversCachedWorkoutsOnCacheSavedLaterInCurrentWeek() async throws {
        let now = date(2026, 9, 29, 9, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        let days = uniqueDays()
        store.stubRetrieval(with: CachedWorkouts(days: days, timestamp: date(2026, 10, 3, 18, 0)))

        let receivedDays = try await sut.load()

        #expect(receivedDays == days)
    }

    // MARK: - Helpers

    private func makeSUT(
        calendar: Calendar = makeCalendar(),
        currentDate: @escaping () -> Date = { Date(timeIntervalSince1970: 0) }
    ) -> (sut: LocalWorkoutsLoader, store: WorkoutsStoreSpy) {
        let store = WorkoutsStoreSpy()
        let sut = LocalWorkoutsLoader(store: store, calendar: calendar, currentDate: currentDate)
        return (sut, store)
    }

    private static func makeCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        calendar.firstWeekday = 2
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0, _ second: Int = 0, calendar: Calendar = makeCalendar()) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute, second: second))!
    }

    private func uniqueDays() -> [WorkoutDay] {
        [
            WorkoutDay(id: UUID().uuidString, day: 0, workouts: [
                Workout(id: UUID().uuidString, title: "any title", status: .assigned, exerciseCount: 5),
            ]),
            WorkoutDay(id: UUID().uuidString, day: 4, workouts: []),
        ]
    }

    private func anyNSError() -> NSError {
        NSError(domain: "any error", code: 0)
    }

    private final class WorkoutsStoreSpy: WorkoutsStore {
        enum Message: Equatable {
            case retrieve
        }

        private(set) var receivedMessages: [Message] = []
        private var retrievalResult: Result<CachedWorkouts?, Error> = .success(nil)

        func stubEmptyCache() {
            retrievalResult = .success(nil)
        }

        func stubRetrieval(with cache: CachedWorkouts) {
            retrievalResult = .success(cache)
        }

        func stubRetrieval(with error: Error) {
            retrievalResult = .failure(error)
        }

        func retrieve() async throws -> CachedWorkouts? {
            receivedMessages.append(.retrieve)
            return try retrievalResult.get()
        }
    }
}
