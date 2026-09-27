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
}
