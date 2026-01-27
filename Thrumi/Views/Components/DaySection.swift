import SwiftUI

struct DaySection: View {
    let date: Date
    let meals: [Meal]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(date, style: .date)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ForEach(meals, id: \.id) { meal in
                MealRow(meal: meal)
            }
        }
    }
}
