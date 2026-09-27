import SwiftUI
import WeeklyWorkouts

/// The week, Monday to Sunday: one row per day with a separator below it.
/// While loading, each day shows a placeholder card; an error message shows a system alert over the days.
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
        .alert("Couldn't load workouts", isPresented: isShowingError, presenting: errorMessage) { _ in
            Button("OK", action: onDismissError)
        } message: { message in
            Text(message)
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
        errorMessage: "Check your connection and try again.",
        onToggle: { _ in },
        onDismissError: {}
    )
}

#Preview("Loaded with no workouts") {
    WeekView(days: PreviewData.emptyWeek, isLoading: false, errorMessage: nil, onToggle: { _ in }, onDismissError: {})
}

#Preview("320pt and 430pt widths") {
    HStack(alignment: .top, spacing: 16) {
        WeekView(days: PreviewData.week, isLoading: false, errorMessage: nil, onToggle: { _ in }, onDismissError: {})
            .frame(width: 320)
        WeekView(days: PreviewData.week, isLoading: false, errorMessage: nil, onToggle: { _ in }, onDismissError: {})
            .frame(width: 430)
    }
    .frame(height: 900)
}

#Preview("Large Dynamic Type") {
    WeekView(days: PreviewData.week, isLoading: false, errorMessage: nil, onToggle: { _ in }, onDismissError: {})
        .dynamicTypeSize(.accessibility2)
}
