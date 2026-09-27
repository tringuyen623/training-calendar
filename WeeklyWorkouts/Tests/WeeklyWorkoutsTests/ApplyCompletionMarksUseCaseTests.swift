import Foundation
import Testing
import WeeklyWorkouts

struct ApplyCompletionMarksUseCaseTests {
    @Test func init_doesNotMessageStoreUponCreation() {
        let (_, marksStore) = makeSUT()

        #expect(marksStore.receivedMessages.isEmpty)
    }

    @Test func apply_failsOnRetrievalError() async {
        let (sut, marksStore) = makeSUT()
        let retrievalError = anyNSError()
        marksStore.stubRetrieval(with: retrievalError)

        await #expect {
            try await sut.apply(to: uniqueDays())
        } throws: { error in
            error as NSError == retrievalError
        }
    }

    @Test func apply_hasNoSideEffectsOnRetrievalError() async {
        let (sut, marksStore) = makeSUT()
        marksStore.stubRetrieval(with: anyNSError())

        _ = try? await sut.apply(to: uniqueDays())

        #expect(marksStore.receivedMessages == [.retrieveAllMarks])
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: CompletionMarksApplier, marksStore: CompletionMarksStoreSpy) {
        let marksStore = CompletionMarksStoreSpy()
        let sut = CompletionMarksApplier(marksStore: marksStore)
        return (sut, marksStore)
    }
}
