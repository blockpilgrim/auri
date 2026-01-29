import SwiftUI

/// Shared design tokens and modifiers for the dark glass UI aesthetic.
/// Used across all views to maintain visual consistency.
enum GlassStyle {
    // MARK: - Fills

    static let cardFill = Color.white.opacity(0.07)
    static let selectedFill = Color.white.opacity(0.15)
    static let onTrackFill = Color(red: 0.3, green: 0.8, blue: 0.7).opacity(0.15)

    // MARK: - Borders

    static let borderGradient = LinearGradient(
        colors: [.white.opacity(0.25), .white.opacity(0.08)],
        startPoint: .top,
        endPoint: .bottom
    )
    static let onTrackBorderGradient = LinearGradient(
        colors: [
            Color(red: 0.3, green: 0.8, blue: 0.7).opacity(0.5),
            Color(red: 0.3, green: 0.8, blue: 0.7).opacity(0.15),
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    static let selectedBorderGradient = LinearGradient(
        colors: [.white.opacity(0.5), .white.opacity(0.2)],
        startPoint: .top,
        endPoint: .bottom
    )
    static let borderWidth: CGFloat = 0.5

    // MARK: - Dimensions

    static let cornerRadius: CGFloat = 12

    // MARK: - Colors

    static let onTrackColor = Color(red: 0.3, green: 0.8, blue: 0.7)
}

// MARK: - View Modifiers

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = GlassStyle.cornerRadius

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(GlassStyle.cardFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(GlassStyle.borderGradient, lineWidth: GlassStyle.borderWidth)
            )
    }
}

struct GlassCapsuleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                Capsule().fill(GlassStyle.cardFill)
            )
            .overlay(
                Capsule()
                    .strokeBorder(GlassStyle.borderGradient, lineWidth: GlassStyle.borderWidth)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = GlassStyle.cornerRadius) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    func glassCapsule() -> some View {
        modifier(GlassCapsuleModifier())
    }
}
