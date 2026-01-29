import SwiftUI

/// Displays the user's current dietary goal as a tappable pill.
/// Tapping opens a sheet to reconfigure the diet choice.
struct DietBadge: View {
    let displayName: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "leaf")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(GlassStyle.cardFill))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(GlassStyle.borderGradient, lineWidth: GlassStyle.borderWidth)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DietBadge(displayName: "Keto / Low-Carb", onTap: {})
        .padding()
}

#Preview("Custom") {
    DietBadge(displayName: "Carnivore", onTap: {})
        .padding()
}
