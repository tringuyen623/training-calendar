import Foundation
import Testing
@testable import WeeklyWorkouts

struct ValidateWorkoutsCacheUseCaseTests {
    @Test func validateCache_failsOnRetrievalError() async {
        let (sut, store) = makeSUT()
        let retrievalError = anyNSError()
        store.stubRetrieval(with: retrievalError)

        await #expect {
            try await sut.validateCache()
        } throws: { error in
            error as NSError == retrievalError
        }
    }

    @Test func validateCache_hasNoSideEffectsOnRetrievalError() async {
        let (sut, store) = makeSUT()
        store.stubRetrieval(with: anyNSError())

        _ = try? await sut.validateCache()

        #expect(store.receivedMessages == [.retrieve])
    }

    @Test func validateCache_hasNoSideEffectsOnEmptyCache() async throws {
        let (sut, store) = makeSUT()
        store.stubEmptyCache()

        try await sut.validateCache()

        #expect(store.receivedMessages == [.retrieve])
    }

    @Test func validateCache_hasNoSideEffectsOnNonExpiredCache() async throws {
        let now = date(2026, 9, 30, 12, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        store.stubRetrieval(with: uniqueCache(savedAt: date(2026, 9, 29, 9, 0)).local)

        try await sut.validateCache()

        #expect(store.receivedMessages == [.retrieve])
    }

    @Test func validateCache_deletesCacheAndCompletionMarksOnExpiredCache() async throws {
        let now = date(2026, 9, 30, 12, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        store.stubRetrieval(with: uniqueCache(savedAt: date(2026, 9, 25, 18, 0)).local)

        try await sut.validateCache()

        #expect(store.receivedMessages == [.retrieve, .deleteAllMarks, .deleteCachedWorkouts])
    }

    @Test func validateCache_failsOnCompletionMarksDeletionError() async {
        let now = date(2026, 9, 30, 12, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        let marksDeletionError = NSError(domain: "marks deletion error", code: 0)
        store.stubRetrieval(with: uniqueCache(savedAt: date(2026, 9, 25, 18, 0)).local)
        store.stubMarksDeletion(with: marksDeletionError)

        await #expect {
            try await sut.validateCache()
        } throws: { error in
            error as NSError == marksDeletionError
        }
    }

    @Test func validateCache_doesNotDeleteCachedWorkoutsOnCompletionMarksDeletionError() async {
        let now = date(2026, 9, 30, 12, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        store.stubRetrieval(with: uniqueCache(savedAt: date(2026, 9, 25, 18, 0)).local)
        store.stubMarksDeletion(with: anyNSError())

        try? await sut.validateCache()

        #expect(store.receivedMessages == [.retrieve, .deleteAllMarks])
    }

    @Test func validateCache_failsOnCachedWorkoutsDeletionErrorOnExpiredCache() async {
        let now = date(2026, 9, 30, 12, 0)
        let (sut, store) = makeSUT(currentDate: { now })
        let deletionError = NSError(domain: "deletion error", code: 0)
        store.stubRetrieval(with: uniqueCache(savedAt: date(2026, 9, 25, 18, 0)).local)
        store.stubDeletion(with: deletionError)

        await #expect {
            try await sut.validateCache()
        } throws: { error in
            error as NSError == deletionError
        }
    }

    // MARK: - Helpers

    private func makeSUT(
        currentDate: @escaping () -> Date = { Date(timeIntervalSince1970: 0) }
    ) -> (sut: LocalWorkoutsLoader, store: WeeklyWorkoutsStoreSpy) {
        let store = WeeklyWorkoutsStoreSpy()
        let sut = LocalWorkoutsLoader(store: store, marksStore: store, calendar: makeCalendar(), currentDate: currentDate)
        return (sut, store)
    }
}
