import Foundation
import SwiftData

@Observable
final class AdherenceEngine {
    private let modelContext: ModelContext

    private(set) var state: AdherenceState = .empty

    private static let defaultAdherenceWhenNoMeals = 0.5
    private static let rewardCurveExponent = 2.5

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        recalculate()
    }

    func recalculate() {
        let todayAdherence = calculateTodayAdherence()
        let rolling7Adherence = calculateRolling7Adherence()
        let rolling30Adherence = calculateRolling30Adherence()

        state = AdherenceState(
            todayAdherence: todayAdherence,
            rolling7Adherence: rolling7Adherence,
            rolling30Adherence: rolling30Adherence
        )
    }

    func applyRewardCurve(_ adherence: Double) -> Double {
        1 - pow(1 - adherence, Self.rewardCurveExponent)
    }

    // MARK: - Adherence Calculations

    private func calculateTodayAdherence() -> Double {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return Self.defaultAdherenceWhenNoMeals
        }

        let meals = fetchMeals(from: startOfDay, to: endOfDay)
        return calculateAdherenceRatio(for: meals)
    }

    private func calculateRolling7Adherence() -> Double {
        let calendar = Calendar.current
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: calendar.startOfDay(for: Date())) else {
            return Self.defaultAdherenceWhenNoMeals
        }

        let meals = fetchMeals(from: startDate, to: endOfToday)
        return calculateAdherenceRatio(for: meals)
    }

    private func calculateRolling30Adherence() -> Double {
        let calendar = Calendar.current
        let endOfToday = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: Date()))!
        guard let startDate = calendar.date(byAdding: .day, value: -30, to: calendar.startOfDay(for: Date())) else {
            return Self.defaultAdherenceWhenNoMeals
        }

        let meals = fetchMeals(from: startDate, to: endOfToday)
        return calculateAdherenceRatio(for: meals)
    }

    private func fetchMeals(from startDate: Date, to endDate: Date) -> [Meal] {
        let predicate = #Predicate<Meal> { meal in
            meal.timestamp >= startDate && meal.timestamp < endDate
        }
        let descriptor = FetchDescriptor<Meal>(predicate: predicate)

        do {
            return try modelContext.fetch(descriptor)
        } catch {
            return []
        }
    }

    private func calculateAdherenceRatio(for meals: [Meal]) -> Double {
        guard !meals.isEmpty else {
            return Self.defaultAdherenceWhenNoMeals
        }

        let onTrackCount = meals.filter(\.isOnTrack).count
        return Double(onTrackCount) / Double(meals.count)
    }
}
