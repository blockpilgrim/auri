import Foundation
import SwiftData

@Model
final class UserSettings {
    var id: UUID
    var dietaryGoal: DietaryGoal
    var onboardingComplete: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        dietaryGoal: DietaryGoal = .wholeFood,
        onboardingComplete: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.dietaryGoal = dietaryGoal
        self.onboardingComplete = onboardingComplete
        self.createdAt = createdAt
    }
}
