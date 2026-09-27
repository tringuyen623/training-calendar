import Foundation
import Testing
import WeeklyWorkouts

struct ApplyCompletionMarksUseCaseTests {
    @Test func init_doesNotMessageStoreUponCreation() {
        let (_, marksStore) = makeSUT()

        #expect(marksStore.receivedMessages.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: CompletionMarksApplier, marksStore: CompletionMarksStoreSpy) {
        let marksStore = CompletionMarksStoreSpy()
        let sut = CompletionMarksApplier(marksStore: marksStore)
        return (sut, marksStore)
    }
}
