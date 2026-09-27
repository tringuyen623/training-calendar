import SwiftUI
import WeeklyWorkouts

/// The week, Monday to Sunday: one row per day with a separator below it.
/// While loading, each day shows a placeholder card; an error message shows a system alert, titled by the message, over the days.
public struct WeekView: View {
    private let days: [DayViewData]
    private let isLoading: Bool
    private let errorMessage: String?
    private let onToggle: (WorkoutCardViewData.ID) -> Void
    private let onDismissError: () -> Void

    public init(
        days: [DayViewData],
        isLoading: Bool,
        errorMessage: String?,
        onToggle: @escaping (WorkoutCardViewData.ID) -> Void,
        onDismissError: @escaping () -> Void
    ) {
        self.days = days
        self.isLoading = isLoading
        self.errorMessage = errorMessage
        self.onToggle = onToggle
        self.onDismissError = onDismissError
    }

    public var body: some View {
        ScrollView {
            DayRowsView(days: days, isLoading: isLoading, onToggle: onToggle)
        }
        .background(Palette.background.ignoresSafeArea())
        .alert(errorMessage ?? "", isPresented: isShowingError) {
            Button("OK", action: onDismissError)
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { _ in })
    }
}

/// The seven rows, stacked; each row draws its own bottom separator.
struct DayRowsView: View {
    let days: [DayViewData]
    let isLoading: Bool
    let onToggle: (WorkoutCardViewData.ID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ForEach(days) { day in
                DayRowView(viewData: day, isLoading: isLoading, onToggle: onToggle)
            }
        }
    }
}

#Preview("Design week") {
    WeekView(days: PreviewData.week, isLoading: false, errorMessage: nil, onToggle: { _ in }, onDismissError: {})
}

#Preview("Loading") {
    WeekView(days: PreviewData.emptyWeek, isLoading: true, errorMessage: nil, onToggle: { _ in }, onDismissError: {})
}

#Preview("Failed") {
    WeekView(
        days: PreviewData.emptyWeek,
        isLoading: false,
        errorMessage: "Couldn't load workouts",
        onToggle: { _ in },
        onDismissError: {}
    )
}

#Preview("Loaded with no workouts") {
    WeekView(days: PreviewData.emptyWeek, isLoading: false, errorMessage: nil, onToggle: { _ in }, onDismissError: {})
}

