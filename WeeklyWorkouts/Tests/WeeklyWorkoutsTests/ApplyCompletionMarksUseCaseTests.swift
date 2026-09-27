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
        marksStore.stubMarksRetrieval(with: retrievalError)

        await #expect {
            try await sut.apply(to: uniqueDays())
        } throws: { error in
            error as NSError == retrievalError
        }
    }

    @Test func apply_hasNoSideEffectsOnRetrievalError() async {
        let (sut, marksStore) = makeSUT()
        marksStore.stubMarksRetrieval(with: anyNSError())

        _ = try? await sut.apply(to: uniqueDays())

        #expect(marksStore.receivedMessages == [.retrieveAllMarks])
    }

    @Test func apply_hasNoSideEffectsOnSuccessfulRetrieval() async {
        let (sut, marksStore) = makeSUT()
        marksStore.stubMarksRetrieval(with: [UUID().uuidString: true])

        _ = try? await sut.apply(to: uniqueDays())

        #expect(marksStore.receivedMessages == [.retrieveAllMarks])
    }

    @Test func apply_completesNotCompletedWorkoutWithCompletedMark() async throws {
        let (sut, marksStore) = makeSUT()
        let assigned = makeWorkout(status: .assigned)
        let missed = makeWorkout(status: .missed)
        marksStore.stubMarksRetrieval(with: [missed.id: true])

        let receivedDays = try await sut.apply(to: makeWeek([assigned, missed]))

        #expect(receivedDays == makeWeek([assigned, missed.with(status: .completed)]))
    }

    @Test func apply_uncompletesCompletedWorkoutWithNotCompletedMark() async throws {
        let (sut, marksStore) = makeSUT()
        let assigned = makeWorkout(status: .assigned)
        let completed = makeWorkout(status: .completed)
        marksStore.stubMarksRetrieval(with: [completed.id: false])

        let receivedDays = try await sut.apply(to: makeWeek([assigned, completed]))

        #expect(receivedDays == makeWeek([assigned, completed.with(status: .assigned)]))
    }

    @Test func apply_keepsServerStatusOfWorkoutsWithoutMark() async throws {
        let (sut, marksStore) = makeSUT()
        let marked = makeWorkout(status: .assigned)
        let assigned = makeWorkout(status: .assigned)
        let missed = makeWorkout(status: .missed)
        let completed = makeWorkout(status: .completed)
        marksStore.stubMarksRetrieval(with: [marked.id: true])

        let receivedDays = try await sut.apply(to: makeWeek([marked, assigned, missed, completed]))

        #expect(receivedDays == makeWeek([marked.with(status: .completed), assigned, missed, completed]))
    }

    @Test func apply_ignoresMarksForWorkoutsNotInWeek() async throws {
        let (sut, marksStore) = makeSUT()
        let week = makeWeek([makeWorkout(status: .assigned), makeWorkout(status: .completed)])
        marksStore.stubMarksRetrieval(with: [UUID().uuidString: true, UUID().uuidString: false, week[0].id: false])

        let receivedDays = try await sut.apply(to: week)

        #expect(receivedDays == week)
    }

    // MARK: - Helpers

    private func makeSUT() -> (sut: CompletionMarksApplier, marksStore: WeeklyWorkoutsStoreSpy) {
        let marksStore = WeeklyWorkoutsStoreSpy()
        let sut = CompletionMarksApplier(marksStore: marksStore)
        return (sut, marksStore)
    }

    private func makeWorkout(status: Workout.Status) -> Workout {
        Workout(id: UUID().uuidString, title: UUID().uuidString, status: status, exerciseCount: Int.random(in: 1...20))
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
