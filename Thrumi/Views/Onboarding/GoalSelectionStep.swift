import SwiftUI

/// Dietary goal selection - second step of onboarding.
/// Allows user to select what "on track" means for them.
struct GoalSelectionStep: View {
    let onSelect: (DietaryGoal) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 60)

            VStack(spacing: 8) {
                Text("What's your goal?")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("This helps you define what 'on track' means")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Spacer()
                .frame(height: 20)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(DietaryGoal.allCases, id: \.self) { goal in
                    GoalButton(goal: goal, onSelect: onSelect)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

#Preview {
    GoalSelectionStep(onSelect: { goal in
        print("Selected: \(goal)")
    })
    .background(Color.black)
}
