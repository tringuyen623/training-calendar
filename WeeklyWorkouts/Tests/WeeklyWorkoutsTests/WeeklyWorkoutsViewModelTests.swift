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

    func load() async throws -> [WorkoutDay] {
        loadCallCount += 1
        return []
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
