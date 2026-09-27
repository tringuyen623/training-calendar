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

    @Test(arguments: [true, false])
    func toggle_deliversNewCompletionOnSuccessfulInsertion(isCompleted: Bool) async throws {
        let (sut, _) = makeSUT()

        let newCompletion = try await sut.toggle(workoutID: UUID().uuidString, isCompleted: isCompleted)

        #expect(newCompletion == !isCompleted)
    }

    @Test func toggle_failsOnInsertionError() async {
        let (sut, marksStore) = makeSUT()
        let insertionError = anyNSError()
        marksStore.stubInsertion(with: insertionError)

        await #expect {
            try await sut.toggle(workoutID: UUID().uuidString, isCompleted: false)
        } throws: { error in
            error as NSError == insertionError
        }
    }

    @Test func toggle_hasNoSideEffectsBeyondInsertionOnInsertionError() async {
        let (sut, marksStore) = makeSUT()
        let workoutID = UUID().uuidString
        marksStore.stubInsertion(with: anyNSError())

        _ = try? await sut.toggle(workoutID: workoutID, isCompleted: false)

        #expect(marksStore.receivedMessages == [.insertMark(true, workoutID)])
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: WorkoutCompletionToggler, marksStore: CompletionMarksStoreSpy) {
        let marksStore = CompletionMarksStoreSpy()
        let sut = WorkoutCompletionToggler(marksStore: marksStore)
        return (sut, marksStore)
    }
}
