import SwiftUI

/// Every color of the week calendar, from the Figma specs. Fixed light colors: the design has no dark variant.
enum Palette {
    static let background = Color(hex: 0xFFFFFF)
    static let textPrimary = Color(hex: 0x1E0A3C)
    static let textSecondary = Color(hex: 0x7B7E91)
    static let accent = Color(hex: 0x7470EF)
    static let missed = Color(hex: 0xFF5E5E)
    static let cardBackground = Color(hex: 0xF7F8FC)
    static let onAccent = Color(hex: 0xFFFFFF)
    static let separator = Color(hex: 0x767676).opacity(0.1)
    static let shimmerHighlight = Color(hex: 0xFFFFFF)
}

/// Every text style of the week calendar: Open Sans at the design's size and line height,
/// scaled with Dynamic Type relative to the closest system text style.
struct TextStyle: Sendable {
    let fontName: String
    let size: CGFloat
    let lineHeight: CGFloat
    let tracking: CGFloat
    let relativeTo: Font.TextStyle

    var font: Font {
        FontRegistration.registerIfNeeded()
        return .custom(fontName, size: size, relativeTo: relativeTo)
    }
}

enum Typography {
    static let weekday = TextStyle(fontName: "OpenSans-Bold", size: 12, lineHeight: 20, tracking: 0.3, relativeTo: .caption)
    static let dayNumber = TextStyle(fontName: "OpenSans-Regular", size: 16, lineHeight: 24, tracking: 0, relativeTo: .body)
    static let cardTitle = TextStyle(fontName: "OpenSans-Bold", size: 15, lineHeight: 20, tracking: 0, relativeTo: .subheadline)
    static let cardSubtitle = TextStyle(fontName: "OpenSans-Regular", size: 13, lineHeight: 18, tracking: 0, relativeTo: .footnote)
}

/// Every size of the week calendar, from the Figma specs (a 375pt-wide frame).
/// Horizontal positions and widths are fractions of the screen width; vertical sizes are points.
enum Metrics {
    static let designWidth: CGFloat = 375

    enum Row {
        /// 19pt of 375 (CSS: 5.07%).
        static let dateLeading: CGFloat = 19 / designWidth
        /// 71pt of 375 (CSS: 18.93%): the 36pt date column, then 16pt before the card.
        static let cardLeading: CGFloat = 71 / designWidth
        /// 283pt of 375, leaving 21pt (5.6%) on the trailing side.
        static let cardWidth: CGFloat = 283 / designWidth
        /// 17.86% of the 112pt row, above and below the cards.
        static let verticalPadding: CGFloat = 20
        /// 548 − (468 + 72) between the cards of one day.
        static let cardSpacing: CGFloat = 8
        /// A one-card row is 112pt including its bottom separator (CSS: separator at 99.11% of 112): 20 + 72 + 20,
        /// with the separator over its bottom point. Rows stack without overlapping.
        static let minHeight: CGFloat = verticalPadding + Card.height + verticalPadding
        /// The date column group is 46pt tall, centered on the first card (33pt from the row's top).
        static let dateColumnHeight: CGFloat = 46
    }

    enum Card {
        static let height: CGFloat = 72
        static let cornerRadius: CGFloat = 8
        static let leadingPadding: CGFloat = 16
        /// 283 − 16 − 249 (the title's width).
        static let trailingPadding: CGFloat = 18
        /// 22.22% of 72.
        static let topPadding: CGFloat = 16
        /// 20.83% of 72.
        static let bottomPadding: CGFloat = 15
        /// Subtitle top (23) − title line height (20).
        static let lineSpacing: CGFloat = 3
        /// 354 − 330: the checkmark's distance from the card's trailing edge.
        static let checkmarkTrailingPadding: CGFloat = 24
        /// Not in the specs: the title stops this far before the checkmark.
        static let titleToCheckmarkSpacing: CGFloat = 12
    }

    enum Checkmark {
        static let size: CGFloat = 24
        /// 1 − 26.25% − 26.23% of 24.
        static let tickWidth: CGFloat = 11.4
        /// 1 − 32.5% − 32.5% of 24.
        static let tickHeight: CGFloat = 8.4
        /// Not in the specs: matched to the frame by comparing the tick's pixel area in a render.
        static let tickLineWidth: CGFloat = 1.8
    }

    enum Separator {
        static let thickness: CGFloat = 1
    }
}

extension View {
    /// Applies a text style: font, tracking, and the design's line height as the text's height.
    func textStyle(_ style: TextStyle) -> some View {
        modifier(TextStyleModifier(style: style))
    }
}

private struct TextStyleModifier: ViewModifier {
    let style: TextStyle
    @ScaledMetric private var lineHeight: CGFloat

    init(style: TextStyle) {
        self.style = style
        _lineHeight = ScaledMetric(wrappedValue: style.lineHeight, relativeTo: style.relativeTo)
    }

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(style.tracking)
            .lineLimit(1)
            .frame(height: lineHeight)
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
