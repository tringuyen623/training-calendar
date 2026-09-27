import SwiftUI
import WeeklyWorkouts
import WeeklyWorkoutsUI

@main
struct TrainingCalendarApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var composer = WeeklyWorkoutsComposer()
    /// Set when the app leaves the foreground, so the launch's first activation doesn't load the week a second time.
    @State private var hasLeftForeground = false

    var body: some Scene {
        WindowGroup {
            WeeklyWorkoutsScreen(viewModel: composer.viewModel)
        }
        .onChange(of: scenePhase) { oldPhase, phase in
            if oldPhase == .active && phase == .inactive {
                // Only on leaving: validating again on the way back could race with the week's reload.
                hasLeftForeground = true
                Task { await composer.validateCache() }
            } else if phase == .active && hasLeftForeground {
                hasLeftForeground = false
                Task { await composer.loadWeekIfNeeded() }
            }
        }
    }
}

/// Binds `WeekView` to the ViewModel that owns the week screen's state.
private struct WeeklyWorkoutsScreen: View {
    let viewModel: WeeklyWorkoutsViewModel

    var body: some View {
        WeekView(
            days: viewModel.days,
            isLoading: viewModel.isLoading,
            errorMessage: viewModel.errorMessage,
            onToggle: { id in Task { await viewModel.send(.toggle(workoutID: id)) } },
            onDismissError: { Task { await viewModel.send(.dismissError) } }
        )
        .task { await viewModel.send(.loadWeek) }
    }
}
