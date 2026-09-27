import SwiftUI
import WeeklyWorkouts

/// A day: its date next to its workout cards, or a placeholder card while loading,
/// with the separator over its bottom point, as in the design.
/// The row grows with its cards and is never shorter than a one-card row.
struct DayRowView: View {
    let viewData: DayViewData
    let isLoading: Bool
    let onToggle: (WorkoutCardViewData.ID) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            DateColumnView(viewData: viewData)
                .padding(.top, Metrics.Row.dateTopInset)
                .frame(width: Metrics.Row.dateColumnWidth, alignment: .leading)
            cards
                .frame(maxWidth: .infinity)
        }
        .padding(.leading, Metrics.Row.leadingPadding)
        .padding(.trailing, Metrics.Row.trailingPadding)
        .padding(.vertical, Metrics.Row.verticalPadding)
        .frame(maxWidth: .infinity, minHeight: Metrics.Row.minHeight, alignment: .topLeading)
        .overlay(alignment: .bottom) {
            Palette.separator
                .frame(height: Metrics.Separator.thickness)
        }
    }

    private var cards: some View {
        VStack(spacing: Metrics.Row.cardSpacing) {
            if isLoading {
                ShimmerCardView()
            } else {
                ForEach(viewData.workouts) { workout in
                    WorkoutCardView(viewData: workout) { onToggle(workout.id) }
                }
            }
        }
    }
}

#Preview("Day row states (not a week)") {
    VStack(spacing: 0) {
        DayRowView(viewData: PreviewData.week[0], isLoading: false, onToggle: { _ in })
        DayRowView(viewData: PreviewData.week[1], isLoading: false, onToggle: { _ in })
        DayRowView(viewData: PreviewData.week[2], isLoading: false, onToggle: { _ in })
        DayRowView(viewData: PreviewData.week[4], isLoading: false, onToggle: { _ in })
        DayRowView(viewData: PreviewData.week[6], isLoading: false, onToggle: { _ in })
    }
    .frame(width: 375)
    .background(Palette.background)
}

#Preview("Today with a completed workout") {
    DayRowView(
        viewData: DayViewData(id: 4, weekday: "Fri", dayNumber: "24", isToday: true, workouts: [PreviewData.completed]),
        isLoading: false,
        onToggle: { _ in }
    )
    .frame(width: 375)
    .background(Palette.background)
}

#Preview("Loading rows") {
    VStack(spacing: 0) {
        DayRowView(viewData: PreviewData.emptyWeek[0], isLoading: true, onToggle: { _ in })
        DayRowView(viewData: PreviewData.emptyWeek[4], isLoading: true, onToggle: { _ in })
    }
    .frame(width: 375)
    .background(Palette.background)
}
