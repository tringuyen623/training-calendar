import Foundation
import Testing
import WeeklyWorkouts

struct ValidateWorkoutsCacheUseCaseTests {
    @Test func validateCache_deletesCacheOnRetrievalError() async throws {
        let (sut, store, marksStore) = makeSUT()
        store.stubRetrieval(with: anyNSError())

        try await sut.validateCache()

        #expect(store.receivedMessages == [.retrieve, .deleteCachedWorkouts])
        #expect(marksStore.receivedMessages.isEmpty)
    }

    @Test func validateCache_hasNoSideEffectsOnEmptyCache() async throws {
        let (sut, store, marksStore) = makeSUT()
        store.stubEmptyCache()

        try await sut.validateCache()

        #expect(store.receivedMessages == [.retrieve])
        #expect(marksStore.receivedMessages.isEmpty)
    }

    @Test func validateCache_hasNoSideEffectsOnNonExpiredCache() async throws {
        let now = date(2026, 9, 30, 12, 0)
        let (sut, store, marksStore) = makeSUT(currentDate: { now })
        store.stubRetrieval(with: uniqueCache(savedAt: date(2026, 9, 29, 9, 0)))

        try await sut.validateCache()

        #expect(store.receivedMessages == [.retrieve])
        #expect(marksStore.receivedMessages.isEmpty)
    }

    @Test func validateCache_deletesCacheAndCompletionMarksOnExpiredCache() async throws {
        let now = date(2026, 9, 30, 12, 0)
        let (sut, store, marksStore) = makeSUT(currentDate: { now })
        store.stubRetrieval(with: uniqueCache(savedAt: date(2026, 9, 25, 18, 0)))

        try await sut.validateCache()

        #expect(store.receivedMessages == [.retrieve, .deleteCachedWorkouts])
        #expect(marksStore.receivedMessages == [.deleteAllMarks])
    }

    @Test func validateCache_failsOnDeletionErrorAfterRetrievalError() async {
        let (sut, store, _) = makeSUT()
        let deletionError = NSError(domain: "deletion error", code: 0)
        store.stubRetrieval(with: anyNSError())
        store.stubDeletion(with: deletionError)

        await #expect {
            try await sut.validateCache()
        } throws: { error in
            error as NSError == deletionError
        }
    }

    @Test func validateCache_failsOnCompletionMarksDeletionError() async {
        let now = date(2026, 9, 30, 12, 0)
        let (sut, store, marksStore) = makeSUT(currentDate: { now })
        let marksDeletionError = NSError(domain: "marks deletion error", code: 0)
        store.stubRetrieval(with: uniqueCache(savedAt: date(2026, 9, 25, 18, 0)))
        marksStore.stubDeletion(with: marksDeletionError)

        await #expect {
            try await sut.validateCache()
        } throws: { error in
            error as NSError == marksDeletionError
        }
    }

    @Test func validateCache_doesNotDeleteCachedWorkoutsOnCompletionMarksDeletionError() async {
        let now = date(2026, 9, 30, 12, 0)
        let (sut, store, marksStore) = makeSUT(currentDate: { now })
        store.stubRetrieval(with: uniqueCache(savedAt: date(2026, 9, 25, 18, 0)))
        marksStore.stubDeletion(with: anyNSError())

        try? await sut.validateCache()

        #expect(store.receivedMessages == [.retrieve])
        #expect(marksStore.receivedMessages == [.deleteAllMarks])
    }

    // MARK: - Helpers

    private func makeSUT(
        currentDate: @escaping () -> Date = { Date(timeIntervalSince1970: 0) }
    ) -> (sut: LocalWorkoutsLoader, store: WorkoutsStoreSpy, marksStore: CompletionMarksStoreSpy) {
        let store = WorkoutsStoreSpy()
        let marksStore = CompletionMarksStoreSpy()
        let sut = LocalWorkoutsLoader(store: store, marksStore: marksStore, calendar: makeCalendar(), currentDate: currentDate)
        return (sut, store, marksStore)
    }
}
