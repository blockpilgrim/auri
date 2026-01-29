import SwiftUI

/// Displays the user's current dietary goal as a tappable pill.
/// Tapping opens a sheet to reconfigure the diet choice.
struct DietBadge: View {
    let goal: DietaryGoal
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "leaf")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(goal.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DietBadge(goal: .keto, onTap: {})
        .padding()
}

#Preview("Long Name") {
    DietBadge(goal: .wholeFood, onTap: {})
        .padding()
}
