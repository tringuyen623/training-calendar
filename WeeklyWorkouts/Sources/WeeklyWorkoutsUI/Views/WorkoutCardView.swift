import SwiftUI
import WeeklyWorkouts

/// One workout: its title over its status and exercise count, styled by its status. Tapping it toggles completion.
struct WorkoutCardView: View {
    let viewData: WorkoutCardViewData
    let onTap: () -> Void

    private var style: WorkoutCardStyle { WorkoutCardStyle(viewData.status) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Metrics.Card.titleToCheckmarkSpacing) {
                VStack(alignment: .leading, spacing: Metrics.Card.lineSpacing) {
                    Text(viewData.title)
                        .textStyle(Typography.cardTitle)
                        .truncationMode(.tail)
                        .foregroundStyle(style.title)
                    Text(subtitle)
                        .textStyle(Typography.cardSubtitle)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if style.showsCheckmark {
                    CheckmarkView()
                }
            }
            .padding(.leading, Metrics.Card.leadingPadding)
            .padding(.trailing, style.showsCheckmark ? Metrics.Card.checkmarkTrailingPadding : Metrics.Card.trailingPadding)
            .padding(.top, Metrics.Card.topPadding)
            .padding(.bottom, Metrics.Card.bottomPadding)
            .frame(minHeight: Metrics.Card.height)
            .background(style.background, in: RoundedRectangle(cornerRadius: Metrics.Card.cornerRadius))
            .contentShape(RoundedRectangle(cornerRadius: Metrics.Card.cornerRadius))
        }
        .buttonStyle(CardButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(viewData.status == .completed ? [.isButton, .isSelected] : .isButton)
    }

    /// "Missed • 5 exercises" with only the status word in its status color, "Completed", or "7 exercises".
    private var subtitle: AttributedString {
        var parts: [AttributedString] = []
        if let statusText = viewData.statusText {
            var status = AttributedString(statusText)
            status.foregroundColor = style.statusText
            parts.append(status)
        }
        if style.showsExerciseCount {
            var count = AttributedString(viewData.exerciseCount)
            count.foregroundColor = style.exerciseCount
            parts.append(count)
        }
        var separator = AttributedString(" • ")
        separator.foregroundColor = style.exerciseCount
        return parts.dropFirst().reduce(parts.first ?? AttributedString()) { $0 + separator + $1 }
    }

    private var accessibilityText: String {
        [viewData.title, viewData.statusText, style.showsExerciseCount ? viewData.exerciseCount : nil]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

private struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

#Preview("Card styles") {
    VStack(spacing: Metrics.Row.cardSpacing) {
        WorkoutCardView(viewData: PreviewData.missed, onTap: {})
        WorkoutCardView(viewData: PreviewData.completed, onTap: {})
        WorkoutCardView(viewData: PreviewData.assigned, onTap: {})
        WorkoutCardView(viewData: PreviewData.upcoming, onTap: {})
    }
    .frame(width: 283)
    .padding()
    .background(Palette.background)
}

#Preview("Completed upcoming and one exercise") {
    VStack(spacing: Metrics.Row.cardSpacing) {
        WorkoutCardView(viewData: PreviewData.completedUpcoming, onTap: {})
        WorkoutCardView(viewData: PreviewData.singleExercise, onTap: {})
    }
    .frame(width: 283)
    .padding()
    .background(Palette.background)
}

#Preview("Long titles truncate") {
    VStack(spacing: Metrics.Row.cardSpacing) {
        WorkoutCardView(viewData: PreviewData.card(PreviewData.missed, title: PreviewData.veryLongTitle), onTap: {})
        WorkoutCardView(viewData: PreviewData.card(PreviewData.completed, title: PreviewData.veryLongTitle), onTap: {})
        WorkoutCardView(viewData: PreviewData.card(PreviewData.upcoming, title: PreviewData.veryLongTitle), onTap: {})
    }
    .frame(width: 283)
    .padding()
    .background(Palette.background)
}
