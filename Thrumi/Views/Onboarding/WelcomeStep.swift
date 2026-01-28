import SwiftUI

/// Welcome screen - first step of onboarding.
/// Shows app branding and introduces the core concept.
struct WelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon placeholder - using atom symbol as Core representation
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.cyan.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 80
                        )
                    )
                    .frame(width: 160, height: 160)

                Image(systemName: "atom")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            VStack(spacing: 12) {
                Text("Thrumi")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Keep your wisps thriving")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
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
