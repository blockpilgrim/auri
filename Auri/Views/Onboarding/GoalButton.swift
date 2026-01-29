import SwiftUI

/// A button for selecting a dietary goal during onboarding.
struct GoalButton: View {
    let goal: DietaryGoal
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(goal.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial.opacity(0.8))
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
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
