import Foundation
import Testing
import WeeklyWorkouts

struct CacheWorkoutsUseCaseTests {
    @Test func save_doesNotRequestCacheInsertionOnDeletionError() async {
        let (sut, store) = makeSUT()
        store.stubDeletion(with: anyNSError())

        try? await sut.save(uniqueDays())

        #expect(store.receivedMessages == [.deleteCachedWorkouts])
    }

    @Test func save_requestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() async {
        var now = Date(timeIntervalSince1970: 1_000)
        let (sut, store) = makeSUT(currentDate: { now })
        let days = uniqueDays()

        now = Date(timeIntervalSince1970: 2_000)
        try? await sut.save(days)

        #expect(store.receivedMessages == [.deleteCachedWorkouts, .insert(days, now)])
    }

    @Test func save_hasNoSideEffectsBeyondDeletionAndInsertionOnInsertionError() async {
        let now = Date(timeIntervalSince1970: 1_000)
        let (sut, store) = makeSUT(currentDate: { now })
        let days = uniqueDays()
        store.stubInsertion(with: anyNSError())

        try? await sut.save(days)

        #expect(store.receivedMessages == [.deleteCachedWorkouts, .insert(days, now)])
    }

    @Test func save_failsOnDeletionError() async {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()
        store.stubDeletion(with: deletionError)

        await #expect {
            try await sut.save(uniqueDays())
        } throws: { error in
            error as NSError == deletionError
        }
    }

    @Test func save_failsOnInsertionError() async {
        let (sut, store) = makeSUT()
        let insertionError = anyNSError()
        store.stubInsertion(with: insertionError)

        await #expect {
            try await sut.save(uniqueDays())
        } throws: { error in
            error as NSError == insertionError
        }
    }

    @Test func save_succeedsOnSuccessfulCacheInsertion() async {
        let (sut, _) = makeSUT()

        await #expect(throws: Never.self) {
            try await sut.save(uniqueDays())
        }
    }

    // MARK: - Helpers

    private func makeSUT(
        marksStore: CompletionMarksStoreSpy = .init(),
        currentDate: @escaping () -> Date = { Date(timeIntervalSince1970: 0) }
    ) -> (sut: LocalWorkoutsLoader, store: WorkoutsStoreSpy) {
        let store = WorkoutsStoreSpy()
        let sut = LocalWorkoutsLoader(store: store, marksStore: marksStore, calendar: Calendar(identifier: .gregorian), currentDate: currentDate)
        return (sut, store)
    }
}
