import SwiftUI
import WeeklyWorkouts

/// The week, Monday to Sunday: one row per day with a separator below it.
/// A failed load shows a system alert over the seven days.
public struct WeekView: View {
    private let viewData: WeekViewData
    private let onToggle: (WorkoutCardViewData.ID) -> Void
    private let onDismissError: () -> Void

    public init(
        viewData: WeekViewData,
        onToggle: @escaping (WorkoutCardViewData.ID) -> Void,
        onDismissError: @escaping () -> Void
    ) {
        self.viewData = viewData
        self.onToggle = onToggle
        self.onDismissError = onDismissError
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(viewData.days) { day in
                    DayRowView(viewData: day, isLoading: viewData.state == .loading, onToggle: onToggle)
                        .overlay(alignment: .bottom) {
                            Palette.separator
                                .frame(height: Metrics.Separator.thickness)
                        }
                }
            }
        }
        .background(Palette.background.ignoresSafeArea())
        .alert("Couldn't load workouts", isPresented: isShowingError, presenting: errorMessage) { _ in
            Button("OK", action: onDismissError)
        } message: { message in
            Text(message)
        }
    }

    private var errorMessage: String? {
        guard case let .failed(message) = viewData.state else { return nil }
        return message
    }

    private var isShowingError: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { _ in })
    }
}

#Preview("Design week") {
    WeekView(viewData: WeekViewData(days: PreviewData.week, state: .loaded), onToggle: { _ in }, onDismissError: {})
}

#Preview("Loading") {
    WeekView(viewData: WeekViewData(days: PreviewData.emptyWeek, state: .loading), onToggle: { _ in }, onDismissError: {})
}

#Preview("Failed") {
    WeekView(
        viewData: WeekViewData(days: PreviewData.emptyWeek, state: .failed(message: "Check your connection and try again.")),
        onToggle: { _ in },
        onDismissError: {}
    )
}

#Preview("Loaded with no workouts") {
    WeekView(viewData: WeekViewData(days: PreviewData.emptyWeek, state: .loaded), onToggle: { _ in }, onDismissError: {})
}

#Preview("320pt and 430pt widths") {
    HStack(alignment: .top, spacing: 16) {
        WeekView(viewData: WeekViewData(days: PreviewData.week, state: .loaded), onToggle: { _ in }, onDismissError: {})
            .frame(width: 320)
        WeekView(viewData: WeekViewData(days: PreviewData.week, state: .loaded), onToggle: { _ in }, onDismissError: {})
            .frame(width: 430)
    }
    .frame(height: 900)
}

#Preview("Large Dynamic Type") {
    WeekView(viewData: WeekViewData(days: PreviewData.week, state: .loaded), onToggle: { _ in }, onDismissError: {})
        .dynamicTypeSize(.accessibility2)
}
