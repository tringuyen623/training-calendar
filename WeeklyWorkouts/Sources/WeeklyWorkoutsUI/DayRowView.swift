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
        DayRowLayout {
            DateColumnView(viewData: viewData)
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
        .overlay(alignment: .bottom) {
            Palette.separator
                .frame(height: Metrics.Separator.thickness)
        }
    }
}

/// Places the date column and the cards at the design's fractions of the row's width.
/// The date column is centered on the first card, as in the design.
private struct DayRowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = rowWidth(for: proposal)
        return CGSize(width: width, height: frames(width: width, subviews: subviews).height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = frames(width: bounds.width, subviews: subviews)
        subviews[0].place(at: CGPoint(x: bounds.minX + frames.date.minX, y: bounds.minY + frames.date.minY), proposal: ProposedViewSize(frames.date.size))
        subviews[1].place(at: CGPoint(x: bounds.minX + frames.cards.minX, y: bounds.minY + frames.cards.minY), proposal: ProposedViewSize(frames.cards.size))
    }

    private func rowWidth(for proposal: ProposedViewSize) -> CGFloat {
        guard let width = proposal.width, width.isFinite else { return Metrics.designWidth }
        return width
    }

    private func frames(width: CGFloat, subviews: Subviews) -> (date: CGRect, cards: CGRect, height: CGFloat) {
        let padding = Metrics.Row.verticalPadding

        let dateX = width * Metrics.Row.dateLeading
        let cardsX = width * Metrics.Row.cardLeading
        let dateSize = subviews[0].sizeThatFits(ProposedViewSize(width: cardsX - dateX, height: nil))
        let dateHeight = max(Metrics.Row.dateColumnHeight, dateSize.height)
        let dateY = padding + max(0, (Metrics.Card.height - dateHeight) / 2)

        let cardsWidth = width * Metrics.Row.cardWidth
        let cardsHeight = subviews[1].sizeThatFits(ProposedViewSize(width: cardsWidth, height: nil)).height

        let height = max(Metrics.Row.minHeight, padding + cardsHeight + padding, dateY + dateSize.height + padding)
        return (
            CGRect(x: dateX, y: dateY, width: dateSize.width, height: dateSize.height),
            CGRect(x: cardsX, y: padding, width: cardsWidth, height: cardsHeight),
            height
        )
    }
}

#Preview("Day row states (not a week)") {
    VStack(spacing: -Metrics.Row.overlap) {
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
    VStack(spacing: -Metrics.Row.overlap) {
        DayRowView(viewData: PreviewData.emptyWeek[0], isLoading: true, onToggle: { _ in })
        DayRowView(viewData: PreviewData.emptyWeek[4], isLoading: true, onToggle: { _ in })
    }
    .frame(width: 375)
    .background(Palette.background)
}
