import Foundation
import Observation

@MainActor
@Observable
public final class WeeklyWorkoutsViewModel {
    public enum Action: Equatable, Sendable {
        case loadWeek
    }

    public private(set) var days: [DayViewData] = []
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    private let loadWeek: () async throws -> [WorkoutDay]
    private let toggleCompletion: (_ workoutID: String, _ isCompleted: Bool) async throws -> Bool
    private let calendar: Calendar
    private let now: () -> Date

    public init(
        loadWeek: @escaping () async throws -> [WorkoutDay],
        toggleCompletion: @escaping (_ workoutID: String, _ isCompleted: Bool) async throws -> Bool,
        calendar: Calendar,
        now: @escaping () -> Date
    ) {
        self.loadWeek = loadWeek
        self.toggleCompletion = toggleCompletion
        self.calendar = calendar
        self.now = now
        show([])
    }

    public func send(_ action: Action) async {
        switch action {
        case .loadWeek:
            isLoading = true
            if let workoutDays = try? await loadWeek() {
                show(workoutDays)
            }
            isLoading = false
        }
    }

    private func show(_ workoutDays: [WorkoutDay]) {
        days = WeekSchedule.days(for: workoutDays, now: now(), calendar: calendar)
            .enumerated()
            .map { index, day in dayViewData(for: day, at: index) }
    }

    private func dayViewData(for day: ScheduledDay, at index: Int) -> DayViewData {
        DayViewData(
            id: index,
            weekday: calendar.shortWeekdaySymbols[calendar.component(.weekday, from: day.date) - 1],
            dayNumber: String(calendar.component(.day, from: day.date)),
            isToday: day.isToday,
            workouts: day.workouts.map(cardViewData)
        )
    }

    private func cardViewData(for workout: ScheduledWorkout) -> WorkoutCardViewData {
        WorkoutCardViewData(id: workout.id, title: workout.title, statusText: nil, exerciseCount: "", status: .assigned)
    }
}
