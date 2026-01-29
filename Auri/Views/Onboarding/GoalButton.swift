import SwiftUI

/// A button for selecting a dietary goal during onboarding.
struct GoalButton: View {
    let goal: DietaryGoal
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(goal.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                        .fill(GlassStyle.cardFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                        .strokeBorder(GlassStyle.borderGradient, lineWidth: GlassStyle.borderWidth)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        GoalButton(goal: .keto, action: {})
        GoalButton(goal: .vegetarian, action: {})
        GoalButton(goal: .custom, action: {})
    }
    .padding()
    .background(Color.black)
}
