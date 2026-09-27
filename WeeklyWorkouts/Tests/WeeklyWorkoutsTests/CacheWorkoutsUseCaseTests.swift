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

    // MARK: - Helpers

    private func makeSUT(
        currentDate: @escaping () -> Date = { Date(timeIntervalSince1970: 0) }
    ) -> (sut: LocalWorkoutsLoader, store: WorkoutsStoreSpy) {
        let store = WorkoutsStoreSpy()
        let sut = LocalWorkoutsLoader(store: store, calendar: Calendar(identifier: .gregorian), currentDate: currentDate)
        return (sut, store)
    }
}
