import Foundation
import Observation

@MainActor
@Observable
public final class WeeklyWorkoutsViewModel {
    private let loadWeek: () async throws -> [WorkoutDay]
    private let toggleCompletion: (_ workoutID: String, _ isCompleted: Bool) async throws -> Bool

    public init(
        loadWeek: @escaping () async throws -> [WorkoutDay],
        toggleCompletion: @escaping (_ workoutID: String, _ isCompleted: Bool) async throws -> Bool
    ) {
        self.loadWeek = loadWeek
        self.toggleCompletion = toggleCompletion
    }
}
