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

    @Test func apply_hasNoSideEffectsOnSuccessfulRetrieval() async {
        let (sut, marksStore) = makeSUT()
        marksStore.stubRetrieval(with: [UUID().uuidString: true])

        _ = try? await sut.apply(to: uniqueDays())

        #expect(marksStore.receivedMessages == [.retrieveAllMarks])
    }

    @Test func apply_completesNotCompletedWorkoutWithCompletedMark() async throws {
        let (sut, marksStore) = makeSUT()
        let assigned = makeWorkout(status: .assigned)
        let missed = makeWorkout(status: .missed)
        marksStore.stubRetrieval(with: [missed.id: true])

        let receivedDays = try await sut.apply(to: makeWeek([assigned, missed]))

        #expect(receivedDays == makeWeek([assigned, missed.with(status: .completed)]))
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: CompletionMarksApplier, marksStore: CompletionMarksStoreSpy) {
        let marksStore = CompletionMarksStoreSpy()
        let sut = CompletionMarksApplier(marksStore: marksStore)
        return (sut, marksStore)
    }

    private func makeWorkout(status: Workout.Status) -> Workout {
        Workout(id: UUID().uuidString, title: "any title", status: status, exerciseCount: 5)
    }

    private func makeWeek(_ workouts: [Workout]) -> [WorkoutDay] {
        [
            WorkoutDay(id: "monday-id", day: 0, workouts: workouts),
            WorkoutDay(id: "friday-id", day: 4, workouts: []),
        ]
    }
}

private extension Workout {
    func with(status: Status) -> Workout {
        Workout(id: id, title: title, status: status, exerciseCount: exerciseCount)
    }
}
