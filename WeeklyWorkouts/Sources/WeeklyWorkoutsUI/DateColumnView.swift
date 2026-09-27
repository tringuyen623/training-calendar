import SwiftUI
import WeeklyWorkouts

/// The weekday over the day number; accent-colored when the day is today.
struct DateColumnView: View {
    let viewData: DayViewData

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(viewData.weekday)
                .textCase(.uppercase)
                .textStyle(Typography.weekday)
                .foregroundStyle(viewData.isToday ? Palette.accent : Palette.textSecondary)
            Text(viewData.dayNumber)
                .textStyle(Typography.dayNumber)
                .foregroundStyle(viewData.isToday ? Palette.accent : Palette.textPrimary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Date column") {
    HStack(spacing: 40) {
        DateColumnView(viewData: PreviewData.week[0])
        DateColumnView(viewData: PreviewData.week[4])
    }
    .padding()
    .background(Palette.background)
}
