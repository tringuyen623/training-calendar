/// What a day row shows, ready for display.
public struct DayViewData: Identifiable, Equatable, Sendable {
    /// The day's position in the week: 0 = Monday … 6 = Sunday.
    public let id: Int
    /// "Mon".
    public let weekday: String
    /// "24".
    public let dayNumber: String
    public let isToday: Bool
    public let workouts: [WorkoutCardViewData]

    public init(id: Int, weekday: String, dayNumber: String, isToday: Bool, workouts: [WorkoutCardViewData]) {
        self.id = id
        self.weekday = weekday
        self.dayNumber = dayNumber
        self.isToday = isToday
        self.workouts = workouts
    }
}
