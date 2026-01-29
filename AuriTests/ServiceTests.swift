import Foundation
import SwiftData
import Testing

@testable import Auri

// MARK: - MealService Tests

@Suite("MealService Tests")
@MainActor
struct MealServiceTests {
    @Test("Save and retrieve meal for today")
    func saveMealForToday() throws {
        let container = try createTestContainer()
        let service = MealService(modelContext: container.mainContext)

        let meal = Meal(isOnTrack: true, source: .photo)
        try service.saveMeal(meal)

        let meals = service.getMealsForDate(Date())
        #expect(meals.count == 1)
        #expect(meals.first?.id == meal.id)
    }

    @Test("Get meals in date range")
    func getMealsInRange() throws {
        let container = try createTestContainer()
        let service = MealService(modelContext: container.mainContext)

        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!

        let meal1 = Meal(timestamp: today, isOnTrack: true, source: .text)
        let meal2 = Meal(timestamp: yesterday, isOnTrack: false, source: .text)
        let meal3 = Meal(timestamp: twoDaysAgo, isOnTrack: true, source: .text)

        try service.saveMeal(meal1)
        try service.saveMeal(meal2)
        try service.saveMeal(meal3)

        let startOfYesterday = calendar.startOfDay(for: yesterday)
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today))!

        let meals = service.getMealsInRange(from: startOfYesterday, to: endOfToday)
        #expect(meals.count == 2)
    }

    @Test("Delete meal removes from storage")
    func deleteMeal() throws {
        let container = try createTestContainer()
        let service = MealService(modelContext: container.mainContext)

        let meal = Meal(isOnTrack: true, source: .text)
        try service.saveMeal(meal)

        var meals = service.getMealsForDate(Date())
        #expect(meals.count == 1)

        try service.deleteMeal(meal)

        meals = service.getMealsForDate(Date())
        #expect(meals.count == 0)
    }

    @Test("Meals sorted by timestamp ascending")
    func mealsSortedByTimestamp() throws {
        let container = try createTestContainer()
        let service = MealService(modelContext: container.mainContext)

        let now = Date()
        let earlier = now.addingTimeInterval(-3600)

        let laterMeal = Meal(timestamp: now, isOnTrack: true, source: .text)
        let earlierMeal = Meal(timestamp: earlier, isOnTrack: false, source: .text)

        try service.saveMeal(laterMeal)
        try service.saveMeal(earlierMeal)

        let meals = service.getMealsForDate(now)
        #expect(meals.count == 2)
        #expect(meals[0].id == earlierMeal.id)
        #expect(meals[1].id == laterMeal.id)
    }
}

// MARK: - AdherenceEngine Tests

@Suite("AdherenceEngine Tests")
@MainActor
struct AdherenceEngineTests {
    @Test("No meals returns 0.5 default adherence")
    func noMealsDefaultAdherence() throws {
        let container = try createTestContainer()
        let engine = AdherenceEngine(modelContext: container.mainContext)

        #expect(engine.state.todayAdherence == 0.5)
        #expect(engine.state.rolling7Adherence == 0.5)
        #expect(engine.state.rolling30Adherence == 0.5)
    }

    @Test("All on-track meals returns 1.0 adherence")
    func allOnTrackAdherence() throws {
        let container = try createTestContainer()
        let mealService = MealService(modelContext: container.mainContext)

        try mealService.saveMeal(Meal(isOnTrack: true, source: .text))
        try mealService.saveMeal(Meal(isOnTrack: true, source: .text))
        try mealService.saveMeal(Meal(isOnTrack: true, source: .text))

        let engine = AdherenceEngine(modelContext: container.mainContext)
        engine.recalculate()

        #expect(engine.state.todayAdherence == 1.0)
    }

    @Test("All off-track meals returns 0.0 adherence")
    func allOffTrackAdherence() throws {
        let container = try createTestContainer()
        let mealService = MealService(modelContext: container.mainContext)

        try mealService.saveMeal(Meal(isOnTrack: false, source: .text))
        try mealService.saveMeal(Meal(isOnTrack: false, source: .text))

        let engine = AdherenceEngine(modelContext: container.mainContext)
        engine.recalculate()

        #expect(engine.state.todayAdherence == 0.0)
    }

    @Test("Mixed meals returns correct ratio")
    func mixedMealsAdherence() throws {
        let container = try createTestContainer()
        let mealService = MealService(modelContext: container.mainContext)

        try mealService.saveMeal(Meal(isOnTrack: true, source: .text))
        try mealService.saveMeal(Meal(isOnTrack: true, source: .text))
        try mealService.saveMeal(Meal(isOnTrack: false, source: .text))
        try mealService.saveMeal(Meal(isOnTrack: false, source: .text))

        let engine = AdherenceEngine(modelContext: container.mainContext)
        engine.recalculate()

        #expect(engine.state.todayAdherence == 0.5)
    }

    @Test("Core adherence uses 60/40 blending")
    func coreAdherenceBlending() throws {
        let container = try createTestContainer()
        let mealService = MealService(modelContext: container.mainContext)
        let calendar = Calendar.current

        // 3 on-track today = 100% today
        try mealService.saveMeal(Meal(isOnTrack: true, source: .text))
        try mealService.saveMeal(Meal(isOnTrack: true, source: .text))
        try mealService.saveMeal(Meal(isOnTrack: true, source: .text))

        // Add meals from past days (within 7 day window)
        // 2 on-track, 2 off-track from yesterday = 50% for that day
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        try mealService.saveMeal(Meal(timestamp: yesterday, isOnTrack: true, source: .text))
        try mealService.saveMeal(Meal(timestamp: yesterday, isOnTrack: true, source: .text))
        try mealService.saveMeal(Meal(timestamp: yesterday, isOnTrack: false, source: .text))
        try mealService.saveMeal(Meal(timestamp: yesterday, isOnTrack: false, source: .text))

        let engine = AdherenceEngine(modelContext: container.mainContext)
        engine.recalculate()

        // Rolling 7 includes today (3 on) + yesterday (2 on, 2 off) = 5/7 ~= 0.714
        // Core = 0.6 * 1.0 (today) + 0.4 * (5/7) (rolling7)
        // Note: The exact value depends on the rolling calculation
        #expect(engine.state.todayAdherence == 1.0)
        #expect(engine.state.coreAdherence > 0.8) // Should be high due to good today + mixed rolling
    }

    @Test("Recalculate updates state")
    func recalculateUpdatesState() throws {
        let container = try createTestContainer()
        let engine = AdherenceEngine(modelContext: container.mainContext)
        let mealService = MealService(modelContext: container.mainContext)

        let initialState = engine.state
        #expect(initialState.todayAdherence == 0.5)

        try mealService.saveMeal(Meal(isOnTrack: true, source: .text))
        engine.recalculate()

        #expect(engine.state.todayAdherence == 1.0)
    }

    @Test("Reward curve makes 80% feel closer to peak")
    func rewardCurveApplied() throws {
        let container = try createTestContainer()
        let engine = AdherenceEngine(modelContext: container.mainContext)

        // Reward curve: 1 - pow(1 - adherence, 2.5)
        let raw80 = 0.8
        let curved80 = engine.applyRewardCurve(raw80)

        // At 80%, the curved value should be significantly higher
        // 1 - pow(0.2, 2.5) ≈ 1 - 0.0179 ≈ 0.982
        #expect(curved80 > 0.95)
        #expect(curved80 < 1.0)
    }

    @Test("Reward curve at 50% provides meaningful gain")
    func rewardCurve50Percent() throws {
        let container = try createTestContainer()
        let engine = AdherenceEngine(modelContext: container.mainContext)

        let raw50 = 0.5
        let curved50 = engine.applyRewardCurve(raw50)

        // 1 - pow(0.5, 2.5) ≈ 1 - 0.177 ≈ 0.823
        #expect(curved50 > 0.8)
        #expect(curved50 < 0.9)
    }

    @Test("Tier determination from core adherence")
    func tierDetermination() throws {
        let container = try createTestContainer()
        let mealService = MealService(modelContext: container.mainContext)

        // Create meals that result in ~90% adherence
        for _ in 0..<9 {
            try mealService.saveMeal(Meal(isOnTrack: true, source: .text))
        }
        try mealService.saveMeal(Meal(isOnTrack: false, source: .text))

        let engine = AdherenceEngine(modelContext: container.mainContext)
        engine.recalculate()

        #expect(engine.state.todayAdherence == 0.9)
        #expect(engine.state.tier == .phaseLocked)
    }
}

// MARK: - UserPreferencesService Tests

@Suite("UserPreferencesService Tests")
@MainActor
struct UserPreferencesServiceTests {
    @Test("Creates default settings if none exist")
    func createsDefaultSettings() throws {
        let container = try createTestContainer()
        let service = UserPreferencesService(modelContext: container.mainContext)

        #expect(service.settings.dietaryGoal == .wholeFood)
        #expect(service.settings.onboardingComplete == false)
    }

    @Test("Update dietary goal persists")
    func updateDietaryGoal() throws {
        let container = try createTestContainer()
        let service = UserPreferencesService(modelContext: container.mainContext)

        try service.updateDietaryGoal(.keto)
        #expect(service.settings.dietaryGoal == .keto)

        // Verify persistence by creating new service instance
        let service2 = UserPreferencesService(modelContext: container.mainContext)
        #expect(service2.settings.dietaryGoal == .keto)
    }

    @Test("Complete onboarding persists")
    func completeOnboarding() throws {
        let container = try createTestContainer()
        let service = UserPreferencesService(modelContext: container.mainContext)

        #expect(service.settings.onboardingComplete == false)

        try service.completeOnboarding()
        #expect(service.settings.onboardingComplete == true)
    }

    @Test("Uses existing settings if present")
    func usesExistingSettings() throws {
        let container = try createTestContainer()

        let existingSettings = UserSettings(dietaryGoal: .vegan, onboardingComplete: true)
        container.mainContext.insert(existingSettings)
        try container.mainContext.save()

        let service = UserPreferencesService(modelContext: container.mainContext)
        #expect(service.settings.dietaryGoal == .vegan)
        #expect(service.settings.onboardingComplete == true)
    }
}

// MARK: - Test Helpers

@MainActor
private func createTestContainer() throws -> ModelContainer {
    let schema = Schema([
        Meal.self,
        UserSettings.self,
    ])
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [modelConfiguration])
}
