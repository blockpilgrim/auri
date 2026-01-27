import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.userPreferences) private var userPreferences

    @State private var showOnboarding: Bool?

    var body: some View {
        Group {
            if let showOnboarding {
                if showOnboarding {
                    OnboardingView(onComplete: completeOnboarding)
                } else {
                    MainView()
                }
            } else {
                Color.black
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            checkOnboardingStatus()
        }
    }

    private func checkOnboardingStatus() {
        if let userPreferences {
            showOnboarding = !userPreferences.settings.onboardingComplete
        } else {
            let settings = fetchOrCreateSettings()
            showOnboarding = !settings.onboardingComplete
        }
    }

    private func completeOnboarding() {
        if let userPreferences {
            try? userPreferences.completeOnboarding()
        } else {
            let settings = fetchOrCreateSettings()
            settings.onboardingComplete = true
            try? modelContext.save()
        }
        showOnboarding = false
    }

    private func fetchOrCreateSettings() -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()

        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        let newSettings = UserSettings()
        modelContext.insert(newSettings)
        try? modelContext.save()
        return newSettings
    }
}

#Preview {
    RootView()
        .modelContainer(for: [Meal.self, UserSettings.self], inMemory: true)
}
