import SwiftUI
import UIKit

struct OnboardingView: View {
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "atom")
                    .font(.system(size: 100))
                    .foregroundStyle(.blue)

                Text("Thrumi")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Keep your reactor online")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(spacing: 16) {
                Text("Onboarding flow will be implemented here")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button(action: onComplete) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
            }

            Spacer()
                .frame(height: 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .systemBackground))
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
