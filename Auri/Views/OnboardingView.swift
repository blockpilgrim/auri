import SwiftUI

/// Main onboarding flow that guides users through setup.
///
/// Flow structure:
/// 1. Welcome Screen (1 tap)
/// 2. Dietary Goal Picker (1 tap)
/// 3. Core Tutorial (1 gesture: flick to spin)
/// 4. First Meal Prompt (1 tap)
///
/// Target: Under 60 seconds to first meaningful interaction.
struct OnboardingView: View {
    @Environment(\.userPreferences) private var userPreferences

    @State private var currentStep: OnboardingStep = .welcome

    var onComplete: () -> Void

    enum OnboardingStep: CaseIterable {
        case welcome
        case goalSelection
        case coreTutorial
        case firstMealPrompt
    }

    var body: some View {
        ZStack {
            // Black background for all steps
            Color.black.ignoresSafeArea()

            // Current step content
            stepContent
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }

    // MARK: - Step Content

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .welcome:
            WelcomeStep(onContinue: {
                currentStep = .goalSelection
            })
            .transition(.asymmetric(
                insertion: .opacity,
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

        case .goalSelection:
            GoalSelectionStep(onSelect: { goal, customName in
                saveGoal(goal, customName: customName)
                currentStep = .coreTutorial
            })
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

        case .coreTutorial:
            CoreTutorialStep(onComplete: {
                currentStep = .firstMealPrompt
            })
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

        case .firstMealPrompt:
            FirstMealPromptStep(onComplete: completeOnboarding)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))
        }
    }

    // MARK: - Actions

    private func saveGoal(_ goal: DietaryGoal, customName: String?) {
        try? userPreferences?.updateDietaryGoal(goal, customName: customName)
    }

    private func completeOnboarding() {
        try? userPreferences?.completeOnboarding()
        onComplete()
    }
}

#Preview("Welcome") {
    OnboardingView(onComplete: {})
}

#Preview("Goal Selection") {
    OnboardingView(onComplete: {})
        .onAppear {
            // Can't easily preview specific steps without state injection
        }
}
