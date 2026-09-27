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
        let (_, loader, toggler) = makeSUT()

        #expect(loader.loadCallCount == 0)
        #expect(toggler.receivedToggles.isEmpty)
    }

    @Test func init_showsTheSevenFormattedDaysOfTheCurrentWeekWithNoWorkouts() {
        let (sut, _, _) = makeSUT()

        #expect(sut.days == emptyWeekOfWednesday())
        #expect(sut.isLoading == false)
        #expect(sut.errorMessage == nil)
    }

    @Test func loadWeek_requestsLoadOnce() async {
        let (sut, loader, _) = makeSUT()

        await sut.send(.loadWeek)

        #expect(loader.loadCallCount == 1)
    }

    @Test func loadWeek_showsLoadingWithTheSevenDaysUntilLoadCompletes() async {
        let (sut, loader, _) = makeSUT()
        loader.stubPendingLoad()

        let loading = Task { await sut.send(.loadWeek) }
        await loader.waitForPendingLoads()

        #expect(sut.isLoading == true)
        #expect(sut.days == emptyWeekOfWednesday())

        loader.completePendingLoads(with: .success([]))
        await loading.value

        #expect(sut.isLoading == false)
    }

    @Test func loadWeek_placesLoadedWorkoutsIntoTheirDaysOnSuccess() async {
        let (sut, loader, _) = makeSUT()
        let mondayWorkout = makeWorkout()
        let fridayWorkout = makeWorkout()
        loader.stub(.success([
            makeDay(4, with: fridayWorkout),
            makeDay(0, with: mondayWorkout),
        ]))

        await sut.send(.loadWeek)

        #expect(sut.days.map { $0.workouts.map(\.id) } == [[mondayWorkout.id], [], [], [], [fridayWorkout.id], [], []])
        #expect(sut.days.flatMap(\.workouts).map(\.title) == [mondayWorkout.title, fridayWorkout.title])
    }

    @Test(arguments: zip([1, 5], ["1 exercise", "5 exercises"]))
    func loadWeek_formatsExerciseCount(count: Int, expectedText: String) async {
        let (sut, loader, _) = makeSUT()
        loader.stub(.success([makeDay(0, with: makeWorkout(exerciseCount: count))]))

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
        let (sut, loader, _) = makeSUT()
        loader.stub(.success([makeDay(statusCase.day, with: makeWorkout(status: statusCase.status))]))

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
        let (sut, loader, _) = makeSUT()
        loader.stub(.success([makeDay(0, with: makeWorkout())]))
        await sut.send(.loadWeek)

        loader.stub(.failure(anyNSError()))
        await sut.send(.loadWeek)

        #expect(sut.days == emptyWeekOfWednesday())
        #expect(sut.errorMessage == "Couldn't load workouts")
        #expect(sut.isLoading == false)
    }

    @Test func loadWeek_onCancellation_stopsLoadingWithoutError() async {
        let (sut, loader, _) = makeSUT()
        loader.stub(.failure(CancellationError()))

        await sut.send(.loadWeek)

        #expect(sut.errorMessage == nil)
        #expect(sut.isLoading == false)
    }

    @Test func loadWeek_whileLoading_doesNotRequestAnotherLoad() async {
        let (sut, loader, _) = makeSUT()
        loader.stubPendingLoad()
        let loading = Task { await sut.send(.loadWeek) }
        await loader.waitForPendingLoads()

        loader.stub(.success([]))
        await sut.send(.loadWeek)

        #expect(loader.loadCallCount == 1)

        loader.completePendingLoads(with: .success([]))
        await loading.value
    }

    @Test func dismissError_clearsErrorMessage() async {
        let (sut, loader, _) = makeSUT()
        loader.stub(.failure(anyNSError()))
        await sut.send(.loadWeek)

        await sut.send(.dismissError)

        #expect(sut.errorMessage == nil)
    }

    @Test func display_placesDeliveredWorkoutsIntoTheDaysWithoutRequestingLoadOrToggle() {
        let (sut, loader, toggler) = makeSUT()
        let workout = makeWorkout(status: .completed)

        sut.display([makeDay(tuesday, with: workout)])

        #expect(sut.days[tuesday].workouts == [
            WorkoutCardViewData(id: workout.id, title: workout.title, statusText: "Completed", exerciseCount: "5 exercises", status: .completed),
        ])
        #expect(loader.loadCallCount == 0)
        #expect(toggler.receivedToggles.isEmpty)
    }

    @Test(arguments: [true, false])
    func toggle_requestsToggleWithWorkoutsCurrentCompletion(isCompleted: Bool) async {
        let (sut, _, toggler) = makeSUT()
        let workout = makeWorkout(status: isCompleted ? .completed : .assigned)
        sut.display([makeDay(tuesday, with: workout)])

        await sut.send(.toggle(workoutID: workout.id))

        #expect(toggler.receivedToggles == [.init(workoutID: workout.id, isCompleted: isCompleted)])
    }

    @Test(arguments: zip([Workout.Status.assigned, .completed], [WorkoutCardViewData.Status.completed, .missed]))
    func toggle_showsNewCompletionWhileSaving(status: Workout.Status, expectedStatus: WorkoutCardViewData.Status) async {
        let (sut, _, toggler) = makeSUT()
        let workout = makeWorkout(status: status)
        sut.display([makeDay(tuesday, with: workout)])
        toggler.stubPendingToggle()

        let toggling = Task { await sut.send(.toggle(workoutID: workout.id)) }
        await toggler.waitForPendingToggle()

        #expect(sut.days[tuesday].workouts.map(\.status) == [expectedStatus])

        toggler.completePendingToggle(with: .success(status != .completed))
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
        let (sut, _, toggler) = makeSUT()
        let workout = makeWorkout(status: .completed)
        sut.display([makeDay(tuesday, with: workout)])
        toggler.stubToggle(with: anyNSError())

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

    private func makeSUT(
        now: @escaping () -> Date = { wednesdayNoon }
    ) -> (sut: WeeklyWorkoutsViewModel, loader: WeekLoaderSpy, toggler: CompletionTogglerSpy) {
        let loader = WeekLoaderSpy()
        let toggler = CompletionTogglerSpy()
        var calendar = makeCalendar()
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let sut = WeeklyWorkoutsViewModel(
            loader: loader,
            toggleCompletion: toggler.toggle,
            calendar: calendar,
            now: now
        )
        return (sut, loader, toggler)
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

private final class WeekLoaderSpy: WorkoutsLoader {
    private(set) var loadCallCount = 0
    private var result: Result<[WorkoutDay], Error>? = .success([])
    private var pendingLoads: [CheckedContinuation<[WorkoutDay], Error>] = []
    private var pendingLoadWaiters: [CheckedContinuation<Void, Never>] = []

    func stub(_ result: Result<[WorkoutDay], Error>) {
        self.result = result
    }

    /// Loads stay pending until `completePendingLoads(with:)`.
    func stubPendingLoad() {
        result = nil
    }

    func waitForPendingLoads(count: Int = 1) async {
        while pendingLoads.count < count {
            await withCheckedContinuation { pendingLoadWaiters.append($0) }
        }
    }

    func completePendingLoads(with result: Result<[WorkoutDay], Error>) {
        pendingLoads.forEach { $0.resume(with: result) }
        pendingLoads.removeAll()
    }

    func load() async throws -> [WorkoutDay] {
        loadCallCount += 1
        if let result {
            return try result.get()
        }
        return try await withCheckedThrowingContinuation { continuation in
            pendingLoads.append(continuation)
            pendingLoadWaiters.forEach { $0.resume() }
            pendingLoadWaiters.removeAll()
        }
    }
}

@MainActor
private final class CompletionTogglerSpy {
    struct Toggle: Equatable {
        let workoutID: String
        let isCompleted: Bool
    }

    private(set) var receivedToggles: [Toggle] = []
    private var error: Error?
    private var isPending = false
    private var pendingToggle: CheckedContinuation<Bool, Error>?
    private var pendingToggleWaiters: [CheckedContinuation<Void, Never>] = []

    func stubToggle(with error: Error) {
        self.error = error
    }

    /// Toggles stay pending until `completePendingToggle(with:)`.
    func stubPendingToggle() {
        isPending = true
    }

    func waitForPendingToggle() async {
        while pendingToggle == nil {
            await withCheckedContinuation { pendingToggleWaiters.append($0) }
        }
    }

    func completePendingToggle(with result: Result<Bool, Error>) {
        pendingToggle?.resume(with: result)
        pendingToggle = nil
    }

    func toggle(workoutID: String, isCompleted: Bool) async throws -> Bool {
        receivedToggles.append(Toggle(workoutID: workoutID, isCompleted: isCompleted))
        if let error {
            throw error
        }
        guard isPending else {
            return !isCompleted
        }
        return try await withCheckedThrowingContinuation { continuation in
            pendingToggle = continuation
            pendingToggleWaiters.forEach { $0.resume() }
            pendingToggleWaiters.removeAll()
        }
    }
}
