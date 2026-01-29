import SwiftUI

/// First meal prompt - final step of onboarding.
/// Encourages user to log their first meal.
struct FirstMealPromptStep: View {
    let onComplete: () -> Void

    /// Purple accent from the Auri spark palette (SparkColors.purple)
    private let accentPurple = Color(red: 0.7, green: 0.5, blue: 0.9)

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 24) {
                // Icon — glass circle with fork.knife symbol in Auri purple
                ZStack {
                    Circle()
                        .fill(GlassStyle.cardFill)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .strokeBorder(GlassStyle.borderGradient, lineWidth: GlassStyle.borderWidth)
                        )

                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(accentPurple.opacity(0.8))
                }

                VStack(spacing: 12) {
                    Text("Ready to start?")
                        .font(.title.bold())
                        .foregroundStyle(.white)

                    Text("Log your next meal to power up your Auri")
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }

            Spacer()

            Button(action: onComplete) {
                Text("Let's Go")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .glassCard()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)

            Spacer()
                .frame(height: 48)
        }
        .padding()
    }
}

#Preview {
    FirstMealPromptStep(onComplete: {})
        .background(Color.black)
}
