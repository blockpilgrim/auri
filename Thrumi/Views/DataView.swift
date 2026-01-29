import SwiftUI

struct DataView: View {
    @Environment(\.mealService) private var mealService
    @Environment(\.adherenceEngine) private var adherenceEngine
    @Environment(\.userPreferences) private var userPreferences
    @Environment(\.dismiss) private var dismiss

    @State private var showingDietPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let goal = userPreferences?.settings.dietaryGoal {
                        DietBadge(goal: goal) {
                            showingDietPicker = true
                        }
                    }

                    MetricsSection(state: adherenceEngine?.state)

                    MealHistorySection(mealService: mealService)
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDietPicker) {
                if let goal = userPreferences?.settings.dietaryGoal {
                    DietPickerSheet(currentGoal: goal) { newGoal in
                        try? userPreferences?.updateDietaryGoal(newGoal)
                    }
                }
            }
        }
    }
}

#Preview {
    DataView()
}
