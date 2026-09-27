import Foundation
import Testing
import WeeklyWorkouts

struct ToggleWorkoutCompletionUseCaseTests {
    @Test func init_doesNotMessageStoreUponCreation() {
        let (_, marksStore) = makeSUT()

        #expect(marksStore.receivedMessages.isEmpty)
    }

    @Test(arguments: [true, false])
    func toggle_requestsMarkInsertionWithInvertedCompletionForWorkout(isCompleted: Bool) async {
        let (sut, marksStore) = makeSUT()
        let workoutID = UUID().uuidString

        _ = try? await sut.toggle(workoutID: workoutID, isCompleted: isCompleted)

        #expect(marksStore.receivedMessages == [.insertMark(!isCompleted, workoutID)])
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: WorkoutCompletionToggler, marksStore: CompletionMarksStoreSpy) {
        let marksStore = CompletionMarksStoreSpy()
        let sut = WorkoutCompletionToggler(marksStore: marksStore)
        return (sut, marksStore)
    }
}
