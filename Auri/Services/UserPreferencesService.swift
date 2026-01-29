import Foundation
import SwiftData

@Observable
final class UserPreferencesService {
    private let modelContext: ModelContext

    private(set) var settings: UserSettings

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.settings = Self.fetchOrCreateSettings(in: modelContext)
    }

    func updateDietaryGoal(_ goal: DietaryGoal, customName: String? = nil) throws {
        settings.dietaryGoal = goal
        settings.customDietName = goal == .custom ? customName : nil
        try modelContext.save()
    }

    func completeOnboarding() throws {
        settings.onboardingComplete = true
        try modelContext.save()
    }

    // MARK: - Private Helpers

    private static func fetchOrCreateSettings(in context: ModelContext) -> UserSettings {
        let descriptor = FetchDescriptor<UserSettings>()

        do {
            let existingSettings = try context.fetch(descriptor)
            if let settings = existingSettings.first {
                return settings
            }
        } catch {
            // Fall through to create new settings
        }

        let newSettings = UserSettings()
        context.insert(newSettings)
        try? context.save()
        return newSettings
    }
}
