import Foundation
import Testing
import WeeklyWorkouts

private let wednesdayNoon = date(2026, 9, 30, 12, 0)

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
            WorkoutDay(id: UUID().uuidString, day: 4, workouts: [fridayWorkout]),
            WorkoutDay(id: UUID().uuidString, day: 0, workouts: [mondayWorkout]),
        ]))

        await sut.send(.loadWeek)

        #expect(sut.days.map { $0.workouts.map(\.id) } == [[mondayWorkout.id], [], [], [], [fridayWorkout.id], [], []])
        #expect(sut.days.flatMap(\.workouts).map(\.title) == [mondayWorkout.title, fridayWorkout.title])
    }

    // MARK: - Helpers

    private func makeSUT(
        now: @escaping () -> Date = { wednesdayNoon }
    ) -> (sut: WeeklyWorkoutsViewModel, loader: WeekLoaderSpy, toggler: CompletionTogglerSpy) {
        let loader = WeekLoaderSpy()
        let toggler = CompletionTogglerSpy()
        var calendar = makeCalendar()
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let sut = WeeklyWorkoutsViewModel(
            loadWeek: loader.load,
            toggleCompletion: toggler.toggle,
            calendar: calendar,
            now: now
        )
        return (sut, loader, toggler)
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

@MainActor
private final class WeekLoaderSpy {
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

    func toggle(workoutID: String, isCompleted: Bool) async throws -> Bool {
        receivedToggles.append(Toggle(workoutID: workoutID, isCompleted: isCompleted))
        return !isCompleted
    }
}
