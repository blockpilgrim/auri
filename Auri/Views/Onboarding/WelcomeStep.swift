import SwiftUI

/// Welcome screen - first step of onboarding.
/// Shows app branding and introduces the core concept.
struct WelcomeStep: View {
    let onContinue: () -> Void

    /// Purple accent from the Auri spark palette (SparkColors.purple)
    private let accentPurple = Color(red: 0.7, green: 0.5, blue: 0.9)

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon — glass circle with atom symbol in Auri purple
            ZStack {
                Circle()
                    .fill(GlassStyle.cardFill)
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .strokeBorder(GlassStyle.borderGradient, lineWidth: GlassStyle.borderWidth)
                    )

                Image(systemName: "atom")
                    .font(.system(size: 64, weight: .thin))
                    .foregroundStyle(accentPurple.opacity(0.8))
            }

            VStack(spacing: 12) {
                Text("Auri")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Feed your light")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
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
    WelcomeStep(onContinue: {})
        .background(Color.black)
}
