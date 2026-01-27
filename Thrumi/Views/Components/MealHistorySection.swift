import SwiftUI

struct MealHistorySection: View {
    let mealService: MealService?

    private var groupedMeals: [(Date, [Meal])] {
        guard let meals = mealService?.getAllMeals(), !meals.isEmpty else { return [] }
        let grouped = Dictionary(grouping: meals) { meal in
            Calendar.current.startOfDay(for: meal.timestamp)
        }
        return grouped.sorted { $0.key > $1.key }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meal History")
                .font(.headline)

            if groupedMeals.isEmpty {
                EmptyHistoryView()
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(groupedMeals, id: \.0) { date, meals in
                    DaySection(date: date, meals: meals)
                }
            }
        }
    }
}
