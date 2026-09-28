import Foundation
import Testing
import WeeklyWorkouts

private let wednesdayNoon = date(2026, 9, 30, 12, 0)
private let tuesday = 1
private let wednesday = 2
private let thursday = 3

@MainActor
struct WeeklyWorkoutsViewModelTests {
    @Test func init_doesNotRequestLoadOrToggle() {
        let (_, client, store) = makeSUT()

        #expect(client.requestedURLs.isEmpty)
        #expect(store.receivedMessages.isEmpty)
    }

    @Test func init_showsTheSevenFormattedDaysOfTheCurrentWeekWithNoWorkouts() {
        let (sut, _, _) = makeSUT()

        #expect(sut.days == emptyWeekOfWednesday())
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
    }

    @Test func loadWeek_requestsLoadOnce() async {
        let (sut, client, _) = makeSUT()

        await sut.send(.loadWeek)

        #expect(client.requestedURLs.count == 1)
    }

    @Test func loadWeek_showsLoadingWithTheSevenDaysUntilLoadCompletes() async {
        let (sut, client, _) = makeSUT()
        client.stubPendingRequest()

        let loading = Task { await sut.send(.loadWeek) }
        await client.waitForPendingRequest()

        #expect(sut.isLoading == true)
        #expect(sut.days == emptyWeekOfWednesday())

        client.completePendingRequests(withStatusCode: 200, data: makeJSON(days: []))
        await loading.value

        #expect(sut.isLoading == false)
    }

    @Test func loadWeek_placesLoadedWorkoutsIntoTheirDaysOnSuccess() async {
        let (sut, client, store) = makeSUT()
        let mondayWorkout = makeWorkout()
        let fridayWorkout = makeWorkout()
        stubLoadedWeek([
            makeDay(4, with: fridayWorkout),
            makeDay(0, with: mondayWorkout),
        ], client: client, store: store)

        await sut.send(.loadWeek)

        #expect(sut.days.map { $0.workouts.map(\.id) } == [[mondayWorkout.id], [], [], [], [fridayWorkout.id], [], []])
        #expect(sut.days.flatMap(\.workouts).map(\.title) == [mondayWorkout.title, fridayWorkout.title])
    }

    @Test(arguments: zip([1, 5], ["1 exercise", "5 exercises"]))
    func loadWeek_formatsExerciseCount(count: Int, expectedText: String) async {
        let (sut, client, store) = makeSUT()
        stubLoadedWeek([makeDay(0, with: makeWorkout(exerciseCount: count))], client: client, store: store)

        await sut.send(.loadWeek)

        #expect(sut.days[0].workouts.map(\.exerciseCount) == [expectedText])
    }

    @Test(arguments: [
        StatusCase(status: .completed, day: tuesday, expectedText: "Completed", expectedStatus: .completed),
        StatusCase(status: .assigned, day: tuesday, expectedText: "Missed", expectedStatus: .missed),
        StatusCase(status: .assigned, day: wednesday, expectedText: nil, expectedStatus: .assigned),
        StatusCase(status: .assigned, day: thursday, expectedText: nil, expectedStatus: .upcoming),
    ])
    func loadWeek_formatsScheduledStatus(_ statusCase: StatusCase) async {
        let (sut, client, store) = makeSUT()
        stubLoadedWeek([makeDay(statusCase.day, with: makeWorkout(status: statusCase.status))], client: client, store: store)

        await sut.send(.loadWeek)

        let card = sut.days[statusCase.day].workouts.first
        #expect(card?.statusText == statusCase.expectedText)
        #expect(card?.status == statusCase.expectedStatus)
    }

    @Test func loadWeek_showsTheWeekOfTheCurrentDateWhenResultArrives() async {
        var now = wednesdayNoon
        let (sut, _, _) = makeSUT(now: { now })
        now = date(2026, 10, 5, 9, 0)

        await sut.send(.loadWeek)

        #expect(sut.days.map(\.dayNumber) == ["5", "6", "7", "8", "9", "10", "11"])
        #expect(sut.days.map(\.isToday) == [true, false, false, false, false, false, false])
    }

    @Test func loadWeek_onFailure_showsTheSevenEmptyDaysAndErrorAndStopsLoading() async {
        let (sut, client, store) = makeSUT()
        stubLoadedWeek([makeDay(0, with: makeWorkout())], client: client, store: store)
        await sut.send(.loadWeek)

        stubLoadFailure(with: anyNSError(), client: client, store: store)
        await sut.send(.loadWeek)

        #expect(sut.days == emptyWeekOfWednesday())
        #expect(sut.errorMessage == "Couldn't load workouts")
        #expect(sut.isLoading == false)
    }

    @Test func loadWeek_onCancellation_stopsLoadingWithoutError() async {
        let (sut, client, store) = makeSUT()
        stubLoadFailure(with: CancellationError(), client: client, store: store)

        await sut.send(.loadWeek)

        #expect(sut.errorMessage == nil)
        #expect(sut.isLoading == false)
    }

    @Test func loadWeek_whileLoading_doesNotRequestAnotherLoad() async {
        let (sut, client, _) = makeSUT()
        client.stubPendingRequest()
        let loading = Task { await sut.send(.loadWeek) }
        await client.waitForPendingRequest()

        await sut.send(.loadWeek)

        #expect(client.requestedURLs.count == 1)

        client.completePendingRequests(withStatusCode: 200, data: makeJSON(days: []))
        await loading.value
    }

    @Test func dismissError_clearsErrorMessage() async {
        let (sut, client, store) = makeSUT()
        stubLoadFailure(with: anyNSError(), client: client, store: store)
        await sut.send(.loadWeek)

        await sut.send(.dismissError)

        #expect(sut.errorMessage == nil)
    }

    @Test func display_placesDeliveredWorkoutsIntoTheDaysWithoutRequestingLoadOrToggle() {
        let (sut, client, store) = makeSUT()
        let workout = makeWorkout(status: .completed)

        sut.display([makeDay(tuesday, with: workout)])

        #expect(sut.days[tuesday].workouts == [
            WorkoutCardViewData(id: workout.id, title: workout.title, statusText: "Completed", exerciseCount: "5 exercises", status: .completed),
        ])
        #expect(client.requestedURLs.isEmpty)
        #expect(store.receivedMessages.isEmpty)
    }

    @Test(arguments: [true, false])
    func toggle_requestsToggleWithWorkoutsCurrentCompletion(isCompleted: Bool) async {
        let (sut, _, store) = makeSUT()
        let workout = makeWorkout(status: isCompleted ? .completed : .assigned)
        sut.display([makeDay(tuesday, with: workout)])

        await sut.send(.toggle(workoutID: workout.id))

        #expect(store.receivedMessages == [.insertMark(!isCompleted, workout.id)])
    }

    @Test(arguments: zip([Workout.Status.assigned, .completed], [WorkoutCardViewData.Status.completed, .missed]))
    func toggle_showsNewCompletionWhileSaving(status: Workout.Status, expectedStatus: WorkoutCardViewData.Status) async {
        let (sut, _, store) = makeSUT()
        let workout = makeWorkout(status: status)
        sut.display([makeDay(tuesday, with: workout)])
        store.stubPendingMarkInsertion()

        let toggling = Task { await sut.send(.toggle(workoutID: workout.id)) }
        await store.waitForPendingMarkInsertion()

        #expect(sut.days[tuesday].workouts.map(\.status) == [expectedStatus])

        store.completePendingMarkInsertion(with: .success(()))
        await toggling.value
    }

    @Test func toggle_keepsNewCompletionWithoutErrorOnSuccess() async {
        let (sut, _, _) = makeSUT()
        let workout = makeWorkout(status: .assigned)
        sut.display([makeDay(tuesday, with: workout)])

        await sut.send(.toggle(workoutID: workout.id))

        #expect(sut.days[tuesday].workouts.map(\.status) == [.completed])
        #expect(sut.errorMessage == nil)
    }

    @Test func toggle_onFailure_revertsToPreviousCompletionAndShowsError() async {
        let (sut, _, store) = makeSUT()
        let workout = makeWorkout(status: .completed)
        sut.display([makeDay(tuesday, with: workout)])
        store.stubMarkInsertion(with: anyNSError())

        await sut.send(.toggle(workoutID: workout.id))

        #expect(sut.days[tuesday].workouts.map(\.status) == [.completed])
        #expect(sut.errorMessage == "Couldn't save your change")
    }

    // MARK: - Helpers

    struct StatusCase: Sendable {
        let status: Workout.Status
        let day: Int
        let expectedText: String?
        let expectedStatus: WorkoutCardViewData.Status
    }

    /// Loads through a real service: by default the cache is empty and the API delivers an empty week.
    private func makeSUT(
        now: @escaping () -> Date = { wednesdayNoon }
    ) -> (sut: WeeklyWorkoutsViewModel, client: HTTPClientSpy, store: WeeklyWorkoutsStoreSpy) {
        let client = HTTPClientSpy()
        let store = WeeklyWorkoutsStoreSpy()
        client.stub(statusCode: 200, data: makeJSON(days: []))
        var calendar = makeCalendar()
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let service = WeeklyWorkoutsService(url: URL(string: "https://a-url.com")!, client: client, store: store, calendar: calendar, currentDate: now)
        let sut = WeeklyWorkoutsViewModel(
            weekLoader: service,
            completionToggler: service,
            calendar: calendar,
            now: now
        )
        return (sut, client, store)
    }

    /// The week is delivered from the cache right away; its background refresh fails without effect.
    private func stubLoadedWeek(_ days: [WorkoutDay], client: HTTPClientSpy, store: WeeklyWorkoutsStoreSpy) {
        store.stubRetrieval(with: CachedWorkouts(days: local(days), timestamp: wednesdayNoon))
        client.stub(error: anyNSError())
    }

    /// With nothing cached, the service waits for the API, so its failure reaches the ViewModel.
    private func stubLoadFailure(with error: Error, client: HTTPClientSpy, store: WeeklyWorkoutsStoreSpy) {
        store.stubEmptyCache()
        client.stub(error: error)
    }

    private func makeDay(_ day: Int, with workout: Workout) -> WorkoutDay {
        WorkoutDay(id: UUID().uuidString, day: day, workouts: [workout])
    }

    private func makeWorkout(status: Workout.Status = .assigned, exerciseCount: Int = 5) -> Workout {
        Workout(id: UUID().uuidString, title: "title \(UUID().uuidString)", status: status, exerciseCount: exerciseCount)
    }

    private func emptyWeekOfWednesday() -> [DayViewData] {
        [
            DayViewData(id: 0, weekday: "Mon", dayNumber: "28", isToday: false, workouts: []),
            DayViewData(id: 1, weekday: "Tue", dayNumber: "29", isToday: false, workouts: []),
            DayViewData(id: 2, weekday: "Wed", dayNumber: "30", isToday: true, workouts: []),
            DayViewData(id: 3, weekday: "Thu", dayNumber: "1", isToday: false, workouts: []),
            DayViewData(id: 4, weekday: "Fri", dayNumber: "2", isToday: false, workouts: []),
            DayViewData(id: 5, weekday: "Sat", dayNumber: "3", isToday: false, workouts: []),
            DayViewData(id: 6, weekday: "Sun", dayNumber: "4", isToday: false, workouts: []),
        ]
    }
}
