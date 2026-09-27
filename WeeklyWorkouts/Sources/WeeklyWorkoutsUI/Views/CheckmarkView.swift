import SwiftUI

/// The completed card's checkmark: an accent tick on a white circle.
struct CheckmarkView: View {
    var body: some View {
        Circle()
            .fill(Palette.onAccent)
            .overlay {
                TickShape()
                    .stroke(Palette.accent, style: StrokeStyle(lineWidth: Metrics.Checkmark.tickLineWidth, lineCap: .round, lineJoin: .round))
                    .padding(Metrics.Checkmark.tickLineWidth / 2)
                    .frame(width: Metrics.Checkmark.tickWidth, height: Metrics.Checkmark.tickHeight)
            }
            .frame(width: Metrics.Checkmark.size, height: Metrics.Checkmark.size)
            .accessibilityHidden(true)
    }
}

/// A tick with a short and a long leg at 45°, traced from the design frame.
private struct TickShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.5))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.35, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}

#Preview("Checkmark") {
    CheckmarkView()
        .padding()
        .background(Palette.accent)
}
