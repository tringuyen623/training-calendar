import SwiftUI
import WeeklyWorkouts

/// How a card looks for each status. The only place where a status becomes colors.
struct WorkoutCardStyle {
    let background: Color
    let title: Color
    let statusText: Color
    let exerciseCount: Color
    let showsExerciseCount: Bool
    let showsCheckmark: Bool

    init(_ status: WorkoutCardViewData.Status) {
        switch status {
        case .missed:
            self.init(background: Palette.cardBackground, title: Palette.textPrimary, statusText: Palette.missed, exerciseCount: Palette.textPrimary, showsExerciseCount: true, showsCheckmark: false)
        case .assigned:
            self.init(background: Palette.cardBackground, title: Palette.textPrimary, statusText: Palette.textPrimary, exerciseCount: Palette.textPrimary, showsExerciseCount: true, showsCheckmark: false)
        case .completed:
            self.init(background: Palette.accent, title: Palette.onAccent, statusText: Palette.onAccent, exerciseCount: Palette.onAccent, showsExerciseCount: false, showsCheckmark: true)
        case .upcoming:
            self.init(background: Palette.cardBackground, title: Palette.textSecondary, statusText: Palette.textSecondary, exerciseCount: Palette.textSecondary, showsExerciseCount: true, showsCheckmark: false)
        }
    }

    private init(background: Color, title: Color, statusText: Color, exerciseCount: Color, showsExerciseCount: Bool, showsCheckmark: Bool) {
        self.background = background
        self.title = title
        self.statusText = statusText
        self.exerciseCount = exerciseCount
        self.showsExerciseCount = showsExerciseCount
        self.showsCheckmark = showsCheckmark
    }
}
