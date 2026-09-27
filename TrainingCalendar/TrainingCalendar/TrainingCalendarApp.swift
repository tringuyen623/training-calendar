import SwiftUI
import WeeklyWorkouts
import WeeklyWorkoutsUI

@main
struct TrainingCalendarApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var composer = WeeklyWorkoutsComposer()

    var body: some Scene {
        WindowGroup {
            WeeklyWorkoutsScreen(viewModel: composer.viewModel)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive {
                Task { await composer.validateCache() }
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
