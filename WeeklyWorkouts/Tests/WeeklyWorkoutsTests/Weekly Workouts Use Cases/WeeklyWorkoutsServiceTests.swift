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

    // MARK: - Load Weekly Workouts Use Case: cached week

    @Test func loadWeek_onCachedWeek_deliversItWithMarksAppliedWithoutWaitingForTheAPI() async throws {
        let (sut, client, store) = makeSUT()
        let assigned = makeWorkout(status: .assigned)
        let missed = makeWorkout(status: .missed)
        store.stubRetrieval(with: validCache(makeWeek([assigned, missed])))
        store.stubMarksRetrieval(with: [missed.id: true])
        client.stubPendingRequest()

        let days = try await sut.loadWeek()

        #expect(days == makeWeek([assigned, missed.with(status: .completed)]))
        await completePendingRefresh(of: sut, on: client)
    }

    @Test func loadWeek_onCachedWeek_requestsDataFromURLInTheBackground() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client, store) = makeSUT(url: url)
        store.stubRetrieval(with: validCache(makeWeek([makeWorkout(status: .assigned)])))

        _ = try? await sut.loadWeek()
        await sut.refreshTask?.value

        #expect(client.requestedURLs == [url])
    }

    @Test func loadWeek_onCachedWeek_doesNotWriteToStoreBeforeRefreshCompletes() async {
        let (sut, client, store) = makeSUT()
        store.stubRetrieval(with: validCache(makeWeek([makeWorkout(status: .assigned)])))
        client.stubPendingRequest()

        _ = try? await sut.loadWeek()
        await client.waitForPendingRequest()

        #expect(store.writes.isEmpty)
        await completePendingRefresh(of: sut, on: client)
    }

    @Test func loadWeek_onCachedWeek_replacesCacheWithRawServerWeekOnSuccessfulRefresh() async {
        let (sut, client, store) = makeSUT()
        let serverWeek = makeServerWeek()
        store.stubRetrieval(with: validCache(makeWeek([makeWorkout(status: .assigned)])))
        store.stubMarksRetrieval(with: ["assigned-id": true])
        client.stub(statusCode: 200, data: serverWeek.json)

        _ = try? await sut.loadWeek()
        await sut.refreshTask?.value

        #expect(store.insertedCaches == [CachedWorkouts(days: local(serverWeek.days), timestamp: now)])
    }

    @Test func loadWeek_onCachedWeek_keepsCacheWithoutErrorOnFailedRefresh() async throws {
        let (sut, client, store) = makeSUT()
        let cachedWeek = makeWeek([makeWorkout(status: .assigned)])
        store.stubRetrieval(with: validCache(cachedWeek))
        client.stub(error: anyNSError())

        let days = try await sut.loadWeek()
        await sut.refreshTask?.value

        #expect(days == cachedWeek)
        #expect(store.writes.isEmpty)
    }

    @Test func loadWeek_onCachedWeek_deliversMarksRetrievalErrorWithoutRequestingAPI() async {
        let (sut, client, store) = makeSUT()
        let retrievalError = anyNSError()
        store.stubRetrieval(with: validCache(makeWeek([makeWorkout(status: .assigned)])))
        store.stubMarksRetrieval(with: retrievalError)

        await #expect {
            try await sut.loadWeek()
        } throws: { error in
            error as NSError == retrievalError
        }
        await sut.refreshTask?.value
        #expect(client.requestedURLs.isEmpty)
    }

    // MARK: - Load Weekly Workouts Use Case: no cached week

    @Test func loadWeek_onEmptyCache_requestsDataFromURLOnce() async {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client, _) = makeSUT(url: url)

        _ = try? await sut.loadWeek()
        await sut.refreshTask?.value

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

    @Test func loadWeek_onEmptyCache_deliversServerWeekWithMarksApplied() async throws {
        let (sut, client, store) = makeSUT()
        let serverWeek = makeServerWeek()
        client.stub(statusCode: 200, data: serverWeek.json)
        store.stubMarksRetrieval(with: ["assigned-id": true, "completed-id": false])

        let days = try await sut.loadWeek()

        #expect(days == [
            WorkoutDay(id: "monday-id", day: 0, workouts: [
                serverWeek.days[0].workouts[0].with(status: .completed),
                serverWeek.days[0].workouts[1],
            ]),
            WorkoutDay(id: "friday-id", day: 4, workouts: [
                serverWeek.days[1].workouts[0].with(status: .assigned),
            ]),
        ])
    }

    @Test func loadWeek_onEmptyCache_replacesCacheWithRawServerWeek() async {
        let (sut, client, store) = makeSUT()
        let serverWeek = makeServerWeek()
        client.stub(statusCode: 200, data: serverWeek.json)
        store.stubMarksRetrieval(with: ["assigned-id": true])

        _ = try? await sut.loadWeek()

        #expect(store.insertedCaches == [CachedWorkouts(days: local(serverWeek.days), timestamp: now)])
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

    @Test func loadWeek_onEmptyCache_deliversMarksRetrievalErrorAfterReplacingCache() async {
        let (sut, client, store) = makeSUT()
        let serverWeek = makeServerWeek()
        let retrievalError = anyNSError()
        client.stub(statusCode: 200, data: serverWeek.json)
        store.stubMarksRetrieval(with: retrievalError)

        await #expect {
            try await sut.loadWeek()
        } throws: { error in
            error as NSError == retrievalError
        }
        #expect(store.insertedCaches == [CachedWorkouts(days: local(serverWeek.days), timestamp: now)])
    }

    // MARK: - Load Weekly Workouts Use Case: unreadable cache

    @Test func loadWeek_onCacheRetrievalError_deliversServerWeekAndReplacesCache() async throws {
        let (sut, client, store) = makeSUT()
        let serverWeek = makeServerWeek()
        store.stubRetrieval(with: anyNSError())
        client.stub(statusCode: 200, data: serverWeek.json)

        let days = try await sut.loadWeek()

        #expect(days == serverWeek.days)
        #expect(store.insertedCaches == [CachedWorkouts(days: local(serverWeek.days), timestamp: now)])
    }

    // MARK: - Load Weekly Workouts Use Case: needs loading

    @Test func needsLoading_onCachedWeek_isFalse() async {
        let (sut, _, store) = makeSUT()
        store.stubRetrieval(with: validCache(makeWeek([makeWorkout(status: .assigned)])))

        #expect(await sut.needsLoading() == false)
    }

    @Test(arguments: [CacheState.emptyCache, .cacheFromPreviousWeek])
    func needsLoading_withoutCachedWeek_isTrue(_ state: CacheState) async {
        let (sut, _, store) = makeSUT()
        state.stub(on: store)

        #expect(await sut.needsLoading() == true)
    }

    @Test func needsLoading_onCacheRetrievalError_isTrue() async {
        let (sut, _, store) = makeSUT()
        store.stubRetrieval(with: anyNSError())

        #expect(await sut.needsLoading() == true)
    }

    @Test(arguments: CacheState.allCases)
    func needsLoading_onlyReadsTheCache(_ state: CacheState) async {
        let (sut, client, store) = makeSUT()
        state.stub(on: store)
        client.stub(statusCode: 200, data: makeServerWeek().json)

        _ = await sut.needsLoading()
        await sut.refreshTask?.value

        #expect(store.receivedMessages == [.retrieve])
        #expect(client.requestedURLs.isEmpty)
        #expect(sut.refreshTask == nil)
    }

    // MARK: - Reload Cached Weekly Workouts Use Case

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

    @Test func loadCachedWeek_deliversMarksRetrievalError() async {
        let (sut, _, store) = makeSUT()
        let retrievalError = anyNSError()
        store.stubRetrieval(with: validCache(makeWeek([makeWorkout(status: .assigned)])))
        store.stubMarksRetrieval(with: retrievalError)

        await #expect {
            try await sut.loadCachedWeek()
        } throws: { error in
            error as NSError == retrievalError
        }
    }

    @Test func loadCachedWeek_doesNotRequestAPIOrWriteToStore() async {
        let (sut, client, store) = makeSUT()
        client.stub(statusCode: 200, data: makeServerWeek().json)
        store.stubRetrieval(with: validCache(makeWeek([makeWorkout(status: .assigned)])))

        _ = try? await sut.loadCachedWeek()

        #expect(client.requestedURLs.isEmpty)
        #expect(store.writes.isEmpty)
    }

    // MARK: - Validate Workouts Cache Use Case

    @Test func validateCache_deletesMarksThenCachedWorkoutsOnExpiredCache() async throws {
        let (sut, _, store) = makeSUT()
        store.stubRetrieval(with: CachedWorkouts(days: local(makeWeek([makeWorkout(status: .assigned)])), timestamp: date(2026, 9, 25, 18, 0)))

        try await sut.validateCache()

        #expect(store.receivedMessages == [.retrieve, .deleteAllMarks, .deleteCachedWorkouts])
    }

    // MARK: - Toggle Workout Completion Use Case

    @Test(arguments: [true, false])
    func toggle_requestsMarkInsertionWithInvertedCompletionForWorkout(isCompleted: Bool) async {
        let (sut, _, store) = makeSUT()
        let workoutID = UUID().uuidString

        _ = try? await sut.toggle(workoutID: workoutID, isCompleted: isCompleted)

        #expect(store.receivedMessages == [.insertMark(!isCompleted, workoutID)])
    }

    @Test(arguments: [true, false])
    func toggle_deliversNewCompletionOnSuccessfulInsertion(isCompleted: Bool) async throws {
        let (sut, _, _) = makeSUT()

        let newCompletion = try await sut.toggle(workoutID: UUID().uuidString, isCompleted: isCompleted)

        #expect(newCompletion == !isCompleted)
    }

    @Test func toggle_failsOnInsertionError() async {
        let (sut, _, store) = makeSUT()
        let insertionError = anyNSError()
        store.stubMarkInsertion(with: insertionError)

        await #expect {
            try await sut.toggle(workoutID: UUID().uuidString, isCompleted: false)
        } throws: { error in
            error as NSError == insertionError
        }
    }

    @Test func toggle_hasNoSideEffectsBeyondInsertionOnInsertionError() async {
        let (sut, _, store) = makeSUT()
        let workoutID = UUID().uuidString
        store.stubMarkInsertion(with: anyNSError())

        _ = try? await sut.toggle(workoutID: workoutID, isCompleted: false)

        #expect(store.receivedMessages == [.insertMark(true, workoutID)])
    }

    // MARK: - Helpers

    private func completePendingRefresh(of sut: WeeklyWorkoutsService, on client: HTTPClientSpy) async {
        await client.waitForPendingRequest()
        client.completePendingRequests(with: anyNSError())
        await sut.refreshTask?.value
    }

    private func validCache(_ days: [WorkoutDay]) -> CachedWorkouts {
        CachedWorkouts(days: local(days), timestamp: date(2026, 9, 29, 9, 0))
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

    enum CacheState: CaseIterable, Sendable {
        case currentWeek
        /// Never loaded, or deleted by the cache validation.
        case emptyCache
        case cacheFromPreviousWeek
        case unreadable

        func stub(on store: WeeklyWorkoutsStoreSpy) {
            switch self {
            case .currentWeek:
                store.stubRetrieval(with: CachedWorkouts(days: local(uniqueDays().models), timestamp: date(2026, 9, 28, 0, 0)))
            case .unreadable:
                store.stubRetrieval(with: anyNSError())
            case .emptyCache:
                store.stubEmptyCache()
            case .cacheFromPreviousWeek:
                store.stubRetrieval(with: CachedWorkouts(days: local(uniqueDays().models), timestamp: date(2026, 9, 27, 23, 59)))
            }
        }
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
