import Foundation
import Observation

/// The week screen's state: always the seven days of the current week, with the delivered workouts placed into them.
/// It only formats what `WeekSchedule` derives; it loads through the injected service and saves completions through the injected toggler.
@MainActor
@Observable
public final class WeeklyWorkoutsViewModel {
    public enum Action: Equatable, Sendable {
        case loadWeek
        case toggle(workoutID: String)
        case dismissError
    }

    public private(set) var days: [DayViewData] = []
    public private(set) var isLoading = false
    public private(set) var errorMessage: String?

    /// The week behind `days`, kept to toggle a workout from its current completion.
    @ObservationIgnored private var workoutDays: [WorkoutDay] = []

    private let service: WeeklyWorkoutsService
    private let toggler: WorkoutCompletionToggler
    private let calendar: Calendar
    private let now: () -> Date

    public init(
        service: WeeklyWorkoutsService,
        toggler: WorkoutCompletionToggler,
        calendar: Calendar,
        now: @escaping () -> Date
    ) {
        self.service = service
        self.toggler = toggler
        self.calendar = calendar
        self.now = now
        show([])
    }

    public func send(_ action: Action) async {
        switch action {
        case .loadWeek:
            await load()
        case let .toggle(workoutID):
            await toggle(workoutID)
        case .dismissError:
            errorMessage = nil
        }
    }

    /// Shows a week delivered outside of `loadWeek`, such as the cached week read again after the cache changed.
    public func display(_ workoutDays: [WorkoutDay]) {
        show(workoutDays)
    }

    private func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            show(try await service.loadWeek())
        } catch is CancellationError {
            return
        } catch {
            show([])
            errorMessage = "Couldn't load workouts"
        }
    }

    private func toggle(_ workoutID: String) async {
        guard let workout = workoutDays.lazy.flatMap(\.workouts).first(where: { $0.id == workoutID }) else { return }
        let isCompleted = workout.isCompleted
        show(settingCompletion(!isCompleted, ofWorkout: workoutID, in: workoutDays))
        do {
            _ = try await toggler.toggle(workoutID: workoutID, isCompleted: isCompleted)
        } catch {
            show(settingCompletion(isCompleted, ofWorkout: workoutID, in: workoutDays))
            errorMessage = "Couldn't save your change"
        }
    }

    // Mirrors a completion mark: completed, or not completed so that the week rules derive missed, assigned or upcoming.
    private func settingCompletion(_ isCompleted: Bool, ofWorkout workoutID: String, in workoutDays: [WorkoutDay]) -> [WorkoutDay] {
        workoutDays.map { day in
            WorkoutDay(id: day.id, day: day.day, workouts: day.workouts.map { workout in
                guard workout.id == workoutID else { return workout }
                return Workout(
                    id: workout.id,
                    title: workout.title,
                    status: isCompleted ? .completed : .assigned,
                    exerciseCount: workout.exerciseCount
                )
            })
        }
    }

    private func show(_ workoutDays: [WorkoutDay]) {
        self.workoutDays = workoutDays
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
        WorkoutCardViewData(
            id: workout.id,
            title: workout.title,
            statusText: statusText(workout.status),
            exerciseCount: exerciseCountText(workout.exerciseCount),
            status: cardStatus(workout.status)
        )
    }

    private func statusText(_ status: ScheduledWorkout.Status) -> String? {
        switch status {
        case .missed: "Missed"
        case .completed: "Completed"
        case .assigned, .upcoming: nil
        }
    }

    private func cardStatus(_ status: ScheduledWorkout.Status) -> WorkoutCardViewData.Status {
        switch status {
        case .missed: .missed
        case .assigned: .assigned
        case .completed: .completed
        case .upcoming: .upcoming
        }
    }

    private func exerciseCountText(_ count: Int) -> String {
        count == 1 ? "1 exercise" : "\(count) exercises"
    }
}
