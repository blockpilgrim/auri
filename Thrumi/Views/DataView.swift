import SwiftUI

struct DataView: View {
    @Environment(\.mealService) private var mealService
    @Environment(\.adherenceEngine) private var adherenceEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
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
        }
    }
}

#Preview {
    DataView()
}
