import Foundation
import Testing
@testable import WeeklyWorkouts

private let now = date(2026, 9, 30, 12, 0)

@MainActor
struct WeeklyWorkoutsServiceTests {
    @Test func init_doesNotMessageClientOrStore() {
        let (_, client, store) = makeSUT()

        #expect(client.requestedURLs.isEmpty)
        #expect(store.receivedMessages.isEmpty)
    }

    // MARK: - No cached week

    @Test func loadWeek_onEmptyCache_requestsDataFromURLOnce() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client, _) = makeSUT(url: url)

        _ = try? await sut.loadWeek()

        #expect(client.requestedURLs == [url])
    }

    @Test func loadWeek_onEmptyCache_deliversRequestFailureOnClientError() async {
        let (sut, client, _) = makeSUT()
        client.stub(error: anyNSError())

        await #expect(throws: WeeklyWorkoutsService.Error.requestFailure) {
            try await sut.loadWeek()
        }
    }

    @Test func loadWeek_onEmptyCache_deliversCancellationErrorOnClientCancellation() async {
        let (sut, client, _) = makeSUT()
        client.stub(error: CancellationError())

        await #expect(throws: CancellationError.self) {
            try await sut.loadWeek()
        }
    }

    @Test func loadWeek_onEmptyCache_deliversInvalidDataOnInvalidResponse() async {
        let (sut, client, _) = makeSUT()
        client.stub(statusCode: 200, data: Data("invalid json".utf8))

        await #expect(throws: WeeklyWorkoutsService.Error.invalidData) {
            try await sut.loadWeek()
        }
    }

    @Test func loadWeek_onEmptyCache_replacesCacheWithRawServerWeek() async {
        let (sut, client, store) = makeSUT()
        let serverWeek = makeServerWeek()
        client.stub(statusCode: 200, data: serverWeek.json)
        store.stubMarksRetrieval(with: ["assigned-id": true])

        _ = try? await sut.loadWeek()

        #expect(store.insertedCaches == [CachedWorkouts(days: serverWeek.days, timestamp: now)])
    }

    @Test(arguments: APIFailure.allCases)
    func loadWeek_onEmptyCache_doesNotWriteToStoreOnAPIFailure(_ failure: APIFailure) async {
        let (sut, client, store) = makeSUT()
        failure.stub(on: client)

        _ = try? await sut.loadWeek()

        #expect(store.writes.isEmpty)
    }

    @Test func loadWeek_onEmptyCache_deliversServerWeekOnSaveFailure() async throws {
        let (sut, client, store) = makeSUT()
        let serverWeek = makeServerWeek()
        client.stub(statusCode: 200, data: serverWeek.json)
        store.stubInsertion(with: anyNSError())

        let days = try await sut.loadWeek()

        #expect(days == serverWeek.days)
    }

    // MARK: - Cached week reloaded after a store change

    @Test func loadCachedWeek_completesNotCompletedWorkoutWithCompletedMark() async throws {
        let (sut, _, store) = makeSUT()
        let assigned = makeWorkout(status: .assigned)
        let missed = makeWorkout(status: .missed)
        store.stubRetrieval(with: validCache(makeWeek([assigned, missed])))
        store.stubMarksRetrieval(with: [missed.id: true])

        let days = try await sut.loadCachedWeek()

        #expect(days == makeWeek([assigned, missed.with(status: .completed)]))
    }

    @Test func loadCachedWeek_uncompletesCompletedWorkoutWithNotCompletedMark() async throws {
        let (sut, _, store) = makeSUT()
        let assigned = makeWorkout(status: .assigned)
        let completed = makeWorkout(status: .completed)
        store.stubRetrieval(with: validCache(makeWeek([assigned, completed])))
        store.stubMarksRetrieval(with: [completed.id: false])

        let days = try await sut.loadCachedWeek()

        #expect(days == makeWeek([assigned, completed.with(status: .assigned)]))
    }

    @Test func loadCachedWeek_keepsServerStatusOfWorkoutsWithoutMark() async throws {
        let (sut, _, store) = makeSUT()
        let marked = makeWorkout(status: .assigned)
        let assigned = makeWorkout(status: .assigned)
        let missed = makeWorkout(status: .missed)
        let completed = makeWorkout(status: .completed)
        store.stubRetrieval(with: validCache(makeWeek([marked, assigned, missed, completed])))
        store.stubMarksRetrieval(with: [marked.id: true])

        let days = try await sut.loadCachedWeek()

        #expect(days == makeWeek([marked.with(status: .completed), assigned, missed, completed]))
    }

    @Test func loadCachedWeek_ignoresMarksForWorkoutsNotInWeek() async throws {
        let (sut, _, store) = makeSUT()
        let week = makeWeek([makeWorkout(status: .assigned), makeWorkout(status: .completed)])
        store.stubRetrieval(with: validCache(week))
        store.stubMarksRetrieval(with: [UUID().uuidString: true, UUID().uuidString: false, week[0].id: false])

        let days = try await sut.loadCachedWeek()

        #expect(days == week)
    }

    // MARK: - Helpers

    private func validCache(_ days: [WorkoutDay]) -> CachedWorkouts {
        CachedWorkouts(days: days, timestamp: date(2026, 9, 29, 9, 0))
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

    enum APIFailure: CaseIterable, Sendable {
        case requestFailure
        case invalidData
        case cancellation

        func stub(on client: HTTPClientSpy) {
            switch self {
            case .requestFailure: client.stub(error: anyNSError())
            case .invalidData: client.stub(statusCode: 200, data: Data("invalid json".utf8))
            case .cancellation: client.stub(error: CancellationError())
            }
        }
    }

    private func makeSUT(
        url: URL = URL(string: "https://a-url.com")!
    ) -> (sut: WeeklyWorkoutsService, client: HTTPClientSpy, store: WeeklyWorkoutsStoreSpy) {
        let client = HTTPClientSpy()
        let store = WeeklyWorkoutsStoreSpy()
        let sut = WeeklyWorkoutsService(url: url, client: client, store: store, calendar: makeCalendar(), currentDate: { now })
        return (sut, client, store)
    }
}

private func makeServerWeek() -> (days: [WorkoutDay], json: Data) {
    let days = [
        WorkoutDay(id: "monday-id", day: 0, workouts: [
            Workout(id: "assigned-id", title: "Legs day", status: .assigned, exerciseCount: 7),
            Workout(id: "missed-id", title: "HIIT Tabata", status: .missed, exerciseCount: 15),
        ]),
        WorkoutDay(id: "friday-id", day: 4, workouts: [
            Workout(id: "completed-id", title: "Full body", status: .completed, exerciseCount: 5),
        ]),
    ]
    let json = makeJSON(days: [
        makeDayJSON(id: "monday-id", day: 0, workouts: [
            makeWorkoutJSON(id: "assigned-id", title: "Legs day", status: 0, exerciseCount: 7),
            makeWorkoutJSON(id: "missed-id", title: "HIIT Tabata", status: 1, exerciseCount: 15),
        ]),
        makeDayJSON(id: "friday-id", day: 4, workouts: [
            makeWorkoutJSON(id: "completed-id", title: "Full body", status: 2, exerciseCount: 5),
        ]),
    ])
    return (days, json)
}

private extension WeeklyWorkoutsStoreSpy {
    /// Everything the store was asked to change, without the reads.
    var writes: [Message] {
        receivedMessages.filter { $0 != .retrieve && $0 != .retrieveAllMarks }
    }

    /// The caches the store was asked to insert, without how the replacement is carried out.
    var insertedCaches: [CachedWorkouts] {
        receivedMessages.compactMap { message in
            guard case let .insert(days, timestamp) = message else { return nil }
            return CachedWorkouts(days: days, timestamp: timestamp)
        }
    }
}

private extension Workout {
    func with(status: Status) -> Workout {
        Workout(id: id, title: title, status: status, exerciseCount: exerciseCount)
    }
}
