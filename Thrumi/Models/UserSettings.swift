import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID
    var dietaryGoal: DietaryGoal
    var customDietName: String?
    var onboardingComplete: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        dietaryGoal: DietaryGoal = .wholeFood,
        customDietName: String? = nil,
        onboardingComplete: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.dietaryGoal = dietaryGoal
        self.customDietName = customDietName
        self.onboardingComplete = onboardingComplete
        self.createdAt = createdAt
    }

    /// The display-ready name for the user's diet.
    /// Returns the custom name for `.custom` goals, otherwise the enum's display name.
    var dietDisplayName: String {
        if dietaryGoal == .custom, let name = customDietName, !name.isEmpty {
            return name
        }
        return dietaryGoal.displayName
    }
}
