/// Loads the week to show: the workout days with the local completion marks applied.
@MainActor
public protocol WeekLoader {
    func loadWeek() async throws -> [WorkoutDay]
}
