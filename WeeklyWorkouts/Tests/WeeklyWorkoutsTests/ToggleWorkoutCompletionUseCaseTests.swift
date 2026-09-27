import Foundation
import Testing
import WeeklyWorkouts

struct ToggleWorkoutCompletionUseCaseTests {
    @Test func init_doesNotMessageStoreUponCreation() {
        let (_, marksStore) = makeSUT()

        #expect(marksStore.receivedMessages.isEmpty)
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: WorkoutCompletionToggler, marksStore: CompletionMarksStoreSpy) {
        let marksStore = CompletionMarksStoreSpy()
        let sut = WorkoutCompletionToggler(marksStore: marksStore)
        return (sut, marksStore)
    }
}
