import Foundation
import Testing
import WeeklyWorkouts

struct WeekScheduleTests {
    @Test func days_deliversTheSevenDaysOfTheMondayToSundayWeekOfNowWithNoWorkoutsOnEmptyInput() {
        var sundayFirstCalendar = makeCalendar()
        sundayFirstCalendar.firstWeekday = 1

        let days = WeekSchedule.days(for: [], now: date(2026, 9, 30, 12, 0), calendar: sundayFirstCalendar)

        #expect(days.map(\.date) == [
            date(2026, 9, 28), date(2026, 9, 29), date(2026, 9, 30), date(2026, 10, 1),
            date(2026, 10, 2), date(2026, 10, 3), date(2026, 10, 4),
        ])
        #expect(days.allSatisfy { $0.workouts.isEmpty })
    }

    @Test func days_placesEachServerDayOnItsDateInTheWeek() {
        let mondayWorkouts = [makeWorkout(), makeWorkout()]
        let fridayWorkouts = [makeWorkout()]
        let serverDays = [
            WorkoutDay(id: UUID().uuidString, day: 4, workouts: fridayWorkouts),
            WorkoutDay(id: UUID().uuidString, day: 0, workouts: mondayWorkouts),
        ]

        let days = WeekSchedule.days(for: serverDays, now: date(2026, 9, 30, 12, 0), calendar: makeCalendar())

        #expect(days.map { $0.workouts.map(\.id) } == [mondayWorkouts.map(\.id), [], [], [], fridayWorkouts.map(\.id), [], []])
        #expect(days.flatMap(\.workouts).map(\.title) == (mondayWorkouts + fridayWorkouts).map(\.title))
        #expect(days.flatMap(\.workouts).map(\.exerciseCount) == (mondayWorkouts + fridayWorkouts).map(\.exerciseCount))
    }

    @Test func days_marksOnlyTheDayOfNowAsToday() {
        let days = WeekSchedule.days(for: [], now: date(2026, 9, 30, 12, 0), calendar: makeCalendar())

        #expect(days.map(\.isToday) == [false, false, true, false, false, false, false])
    }

    @Test func days_showsMissedForNotCompletedWorkoutBeforeToday() {
        #expect(status(of: makeWorkout(status: .assigned), on: tuesday) == .missed)
    }

    @Test func days_showsAssignedForNotCompletedWorkoutToday() {
        #expect(status(of: makeWorkout(status: .missed), on: wednesday) == .assigned)
    }

    @Test func days_showsUpcomingForNotCompletedWorkoutAfterToday() {
        #expect(status(of: makeWorkout(status: .missed), on: thursday) == .upcoming)
    }

    @Test(arguments: [1, 2, 3])
    func days_showsCompletedForCompletedWorkoutWhateverItsDay(day: Int) {
        #expect(status(of: makeWorkout(status: .completed), on: day) == .completed)
    }

    // MARK: - Helpers

    private let wednesdayNoon = date(2026, 9, 30, 12, 0)
    private let tuesday = 1
    private let wednesday = 2
    private let thursday = 3

    private func status(of workout: Workout, on day: Int) -> ScheduledWorkout.Status? {
        let serverDays = [WorkoutDay(id: UUID().uuidString, day: day, workouts: [workout])]
        let days = WeekSchedule.days(for: serverDays, now: wednesdayNoon, calendar: makeCalendar())
        return days[day].workouts.first?.status
    }

    private func makeWorkout(status: Workout.Status = .assigned) -> Workout {
        Workout(id: UUID().uuidString, title: "title \(UUID().uuidString)", status: status, exerciseCount: Int.random(in: 1...20))
    }
}
