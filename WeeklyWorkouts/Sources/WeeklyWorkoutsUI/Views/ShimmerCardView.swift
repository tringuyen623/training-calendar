import SwiftUI

/// A card-shaped placeholder shown while the week loads, with a highlight sweeping across it.
/// The highlight stays still when Reduce Motion is on.
struct ShimmerCardView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    var body: some View {
        RoundedRectangle(cornerRadius: Metrics.Card.cornerRadius)
            .fill(Palette.cardBackground)
            .frame(height: Metrics.Card.height)
            .overlay {
                if !reduceMotion {
                    GeometryReader { proxy in
                        LinearGradient(
                            colors: [Palette.cardBackground, Palette.shimmerHighlight, Palette.cardBackground],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(width: proxy.size.width / 2)
                        .offset(x: phase * proxy.size.width * 1.5 + proxy.size.width / 4)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Metrics.Card.cornerRadius))
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
            .accessibilityLabel(Text("Loading"))
    }
}

#Preview("Shimmer") {
    ShimmerCardView()
        .frame(width: 283)
        .padding()
        .background(Palette.background)
}
