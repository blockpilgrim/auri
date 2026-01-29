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

    @Test("Core tier from safe mode adherence")
    func coreTierSafeMode() {
        let state = AdherenceState(
            todayAdherence: 0.2,
            rolling7Adherence: 0.2,
            rolling30Adherence: 0.2
        )

        #expect(state.tier == .safeMode)
    }

    @Test("Core tier from standby adherence")
    func coreTierStandby() {
        let state = AdherenceState(
            todayAdherence: 0.4,
            rolling7Adherence: 0.4,
            rolling30Adherence: 0.4
        )

        #expect(state.tier == .standby)
    }

    @Test("Core tier from stabilizing adherence")
    func coreTierStabilizing() {
        let state = AdherenceState(
            todayAdherence: 0.6,
            rolling7Adherence: 0.6,
            rolling30Adherence: 0.6
        )

        #expect(state.tier == .stabilizing)
    }

    @Test("Core tier from online adherence")
    func coreTierOnline() {
        let state = AdherenceState(
            todayAdherence: 0.8,
            rolling7Adherence: 0.8,
            rolling30Adherence: 0.8
        )

        #expect(state.tier == .online)
    }

    @Test("Core tier from phase-locked adherence")
    func coreTierPhaseLocked() {
        let state = AdherenceState(
            todayAdherence: 1.0,
            rolling7Adherence: 1.0,
            rolling30Adherence: 1.0
        )

        #expect(state.tier == .phaseLocked)
    }

    @Test("Empty state defaults")
    func emptyState() {
        let state = AdherenceState.empty

        #expect(state.todayAdherence == 0)
        #expect(state.rolling7Adherence == 0)
        #expect(state.rolling30Adherence == 0)
        #expect(state.coreAdherence == 0)
        #expect(state.tier == .safeMode)
    }
}

@Suite("CoreTier Tests")
struct CoreTierTests {
    @Test("CoreTier from adherence boundaries", arguments: [
        (0.0, CoreTier.safeMode),
        (0.29, CoreTier.safeMode),
        (0.30, CoreTier.standby),
        (0.49, CoreTier.standby),
        (0.50, CoreTier.stabilizing),
        (0.69, CoreTier.stabilizing),
        (0.70, CoreTier.online),
        (0.89, CoreTier.online),
        (0.90, CoreTier.phaseLocked),
        (1.0, CoreTier.phaseLocked),
    ])
    func coreTierFromAdherence(adherence: Double, expected: CoreTier) {
        #expect(CoreTier.from(adherence: adherence) == expected)
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
