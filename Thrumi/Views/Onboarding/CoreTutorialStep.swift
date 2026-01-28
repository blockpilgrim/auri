import SwiftUI

/// Core tutorial - third step of onboarding.
/// Shows the Orb of Wisps and prompts user to flick it.
struct CoreTutorialStep: View {
    @Environment(\.hapticsManager) private var hapticsManager
    @State private var hasFlicked = false

    let onComplete: () -> Void

    /// Tutorial state shows the Orb in a good "High" state (80% adherence)
    /// so it looks impressive but has room to improve
    private let tutorialState = AdherenceState(
        todayAdherence: 0.8,
        rolling7Adherence: 0.8,
        rolling30Adherence: 0.8
    )

    var body: some View {
        ZStack {
            // Full-screen Wisp Orb with flick detection
            WispOrbView(
                adherenceState: tutorialState,
                adherenceEngine: nil,
                hapticsManager: hapticsManager
            )
            .ignoresSafeArea()
            // Add simultaneous gesture to detect flicks without blocking Core's gestures
            .simultaneousGesture(flickDetectionGesture)

            // Tutorial overlay (doesn't block touches)
            VStack {
                Spacer()

                if !hasFlicked {
                    // Pre-flick prompt
                    instructionCard {
                        VStack(spacing: 8) {
                            Image(systemName: "hand.draw")
                                .font(.system(size: 32))
                                .foregroundStyle(.cyan)

                            Text("Flick to spin the wisps")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                    }
                } else {
                    // Post-flick success + continue
                    instructionCard {
                        VStack(spacing: 16) {
                            Text("Nice!")
                                .font(.title2.bold())
                                .foregroundStyle(.white)

                            Text("Your Orb's energy reflects your choices")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)

                            Button(action: onComplete) {
                                Text("Continue")
                                    .font(.headline)
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 12)
                                    .background(
                                        LinearGradient(
                                            colors: [.cyan, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                Spacer()
                    .frame(height: 100)
            }
            .allowsHitTesting(hasFlicked) // Only allow interaction with overlay after flick
        }
    }

    // MARK: - Flick Detection

    /// Gesture that runs simultaneously with WispOrbView's gestures
    /// to detect when user has flicked
    private var flickDetectionGesture: some Gesture {
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                // Calculate velocity magnitude
                let velocity = sqrt(
                    pow(value.velocity.width, 2) +
                    pow(value.velocity.height, 2)
                )

                // If velocity is high enough, it's a flick
                // 200 points/second is a reasonable threshold
                if velocity > 200 && !hasFlicked {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        hasFlicked = true
                    }
                }
            }
    }

    // MARK: - View Builders

    @ViewBuilder
    private func instructionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 32)
    }
}

#Preview {
    CoreTutorialStep(onComplete: {})
        .background(Color.black)
}
