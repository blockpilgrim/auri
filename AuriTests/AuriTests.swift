import Foundation
import SwiftData
import Testing

@testable import Auri

@Suite("Model Tests")
struct ModelTests {
    @Test("Meal creation with photo source")
    func mealCreationWithPhoto() {
        let meal = Meal(
            isOnTrack: true,
            source: .photo
        )

        #expect(meal.isOnTrack == true)
        #expect(meal.source == .photo)
        #expect(meal.photoPath == nil)
        #expect(meal.mealDescription == nil)
    }

    @Test("Meal creation with text source")
    func mealCreationWithText() {
        let meal = Meal(
            mealDescription: "Grilled chicken salad",
            isOnTrack: true,
            source: .text
        )

        #expect(meal.isOnTrack == true)
        #expect(meal.source == .text)
        #expect(meal.mealDescription == "Grilled chicken salad")
    }

    @Test("UserSettings creation with defaults")
    func userSettingsDefaults() {
        let settings = UserSettings()

        #expect(settings.dietaryGoal == .wholeFood)
        #expect(settings.onboardingComplete == false)
    }

    @Test("UserSettings creation with custom goal")
    func userSettingsCustomGoal() {
        let settings = UserSettings(dietaryGoal: .keto)

        #expect(settings.dietaryGoal == .keto)
    }
}

@Suite("AdherenceState Tests")
struct AdherenceStateTests {
    @Test("Core adherence blending formula")
    func coreAdherenceBlending() {
        let state = AdherenceState(
            todayAdherence: 1.0,
            rolling7Adherence: 0.5,
            rolling30Adherence: 0.6
        )

        // coreAdherence = 0.6 * today + 0.4 * rolling7
        // = 0.6 * 1.0 + 0.4 * 0.5 = 0.6 + 0.2 = 0.8
        #expect(state.coreAdherence == 0.8)
    }

    @Test("Tier from dreaming adherence")
    func tierDreaming() {
        let state = AdherenceState(
            todayAdherence: 0.2,
            rolling7Adherence: 0.2,
            rolling30Adherence: 0.2
        )

        #expect(state.tier == .dreaming)
    }

    @Test("Tier from resting adherence")
    func tierResting() {
        let state = AdherenceState(
            todayAdherence: 0.4,
            rolling7Adherence: 0.4,
            rolling30Adherence: 0.4
        )

        #expect(state.tier == .resting)
    }

    @Test("Tier from awakening adherence")
    func tierAwakening() {
        let state = AdherenceState(
            todayAdherence: 0.6,
            rolling7Adherence: 0.6,
            rolling30Adherence: 0.6
        )

        #expect(state.tier == .awakening)
    }

    @Test("Tier from vibrant adherence")
    func tierVibrant() {
        let state = AdherenceState(
            todayAdherence: 0.8,
            rolling7Adherence: 0.8,
            rolling30Adherence: 0.8
        )

        #expect(state.tier == .vibrant)
    }

    @Test("Tier from radiant adherence")
    func tierRadiant() {
        let state = AdherenceState(
            todayAdherence: 1.0,
            rolling7Adherence: 1.0,
            rolling30Adherence: 1.0
        )

        #expect(state.tier == .radiant)
    }

    @Test("Empty state defaults")
    func emptyState() {
        let state = AdherenceState.empty

        #expect(state.todayAdherence == 0)
        #expect(state.rolling7Adherence == 0)
        #expect(state.rolling30Adherence == 0)
        #expect(state.coreAdherence == 0)
        #expect(state.tier == .dreaming)
    }
}

@Suite("OrbTier Tests")
struct OrbTierTests {
    @Test("OrbTier from adherence boundaries", arguments: [
        (0.0, OrbTier.dreaming),
        (0.29, OrbTier.dreaming),
        (0.30, OrbTier.resting),
        (0.49, OrbTier.resting),
        (0.50, OrbTier.awakening),
        (0.69, OrbTier.awakening),
        (0.70, OrbTier.vibrant),
        (0.89, OrbTier.vibrant),
        (0.90, OrbTier.radiant),
        (1.0, OrbTier.radiant),
    ])
    func orbTierFromAdherence(adherence: Double, expected: OrbTier) {
        #expect(OrbTier.from(adherence: adherence) == expected)
    }
}

@Suite("DietaryGoal Tests")
struct DietaryGoalTests {
    @Test("All dietary goals have display names")
    func allGoalsHaveDisplayNames() {
        for goal in DietaryGoal.allCases {
            #expect(!goal.displayName.isEmpty)
        }
    }
}

@Suite("MealSource Tests")
struct MealSourceTests {
    @Test("MealSource is Codable")
    func mealSourceCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let original = MealSource.photo
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(MealSource.self, from: data)

        #expect(decoded == original)
    }
}
