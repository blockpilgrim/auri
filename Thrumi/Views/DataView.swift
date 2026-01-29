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
                    if let settings = userPreferences?.settings {
                        DietBadge(displayName: settings.dietDisplayName) {
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
                if let settings = userPreferences?.settings {
                    DietPickerSheet(
                        currentGoal: settings.dietaryGoal,
                        currentCustomName: settings.customDietName
                    ) { goal, customName in
                        try? userPreferences?.updateDietaryGoal(goal, customName: customName)
                    }
                }
            }
        }
    }
}

#Preview {
    DataView()
}
