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
        let cache = uniqueCache(savedAt: date(2026, 9, 30, 18, 0))
        store.stubRetrieval(with: cache)

        let receivedDays = try await sut.load()

        #expect(receivedDays == cache.days)
    }

    @Test func load_deliversNoWorkoutsOnCacheSavedAtEndOfPreviousWeek() async throws {
        let now = date(2026, 9, 28, 0, 0, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        store.stubRetrieval(with: uniqueCache(savedAt: date(2026, 9, 27, 23, 59, 59)))

        let receivedDays = try await sut.load()

        #expect(receivedDays.isEmpty)
    }

    @Test func load_usesCurrentDateAtLoadTime() async throws {
        var now = date(2026, 9, 30, 12, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        store.stubRetrieval(with: uniqueCache(savedAt: date(2026, 9, 30, 9, 0)))

        now = date(2026, 10, 5, 9, 0)
        let receivedDays = try await sut.load()

        #expect(receivedDays.isEmpty)
    }

    @Test func load_hasNoSideEffectsOnRetrievalError() async {
        let (sut, store) = makeSUT()
        store.stubRetrieval(with: anyNSError())

        _ = try? await sut.load()

        #expect(store.receivedMessages == [.retrieve])
    }

    @Test func load_hasNoSideEffectsOnEmptyCache() async {
        let (sut, store) = makeSUT()
        store.stubEmptyCache()

        _ = try? await sut.load()

        #expect(store.receivedMessages == [.retrieve])
    }

    @Test func load_hasNoSideEffectsOnValidCache() async {
        let now = date(2026, 9, 30, 12, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        store.stubRetrieval(with: uniqueCache(savedAt: date(2026, 9, 29, 9, 0)))

        _ = try? await sut.load()

        #expect(store.receivedMessages == [.retrieve])
    }

    @Test func load_hasNoSideEffectsOnExpiredCache() async {
        let now = date(2026, 9, 30, 12, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        store.stubRetrieval(with: uniqueCache(savedAt: date(2026, 9, 25, 18, 0)))

        _ = try? await sut.load()

        #expect(store.receivedMessages == [.retrieve])
    }

    @Test func load_treatsMondayAsFirstWeekdayRegardlessOfCalendarSettings() async throws {
        var sundayFirstCalendar = makeCalendar()
        sundayFirstCalendar.firstWeekday = 1
        var now = date(2026, 10, 4, 12, 0)
        let (sut, store) = makeSUT(calendar: sundayFirstCalendar, currentDate: { now })
        let cacheSavedOnMonday = uniqueCache(savedAt: date(2026, 9, 28, 9, 0))

        store.stubRetrieval(with: cacheSavedOnMonday)
        let daysOnSunday = try await sut.load()

        now = date(2026, 9, 28, 9, 0)
        store.stubRetrieval(with: uniqueCache(savedAt: date(2026, 9, 27, 12, 0)))
        let daysOnMonday = try await sut.load()

        #expect(daysOnSunday == cacheSavedOnMonday.days, "Sunday belongs to the week started on Monday")
        #expect(daysOnMonday.isEmpty, "Monday starts a new week")
    }

    // MARK: - Helpers

    private func makeSUT(
        calendar: Calendar = makeCalendar(),
        currentDate: @escaping () -> Date = { Date(timeIntervalSince1970: 0) }
    ) -> (sut: LocalWorkoutsLoader, store: WeeklyWorkoutsStoreSpy) {
        let store = WeeklyWorkoutsStoreSpy()
        let sut = LocalWorkoutsLoader(store: store, marksStore: store, calendar: calendar, currentDate: currentDate)
        return (sut, store)
    }
}
