import SwiftUI

struct MealRow: View {
    let meal: Meal

    var body: some View {
        HStack {
            if let photoPath = meal.photoPath {
                MealThumbnail(path: photoPath)
            } else {
                Image(systemName: "text.alignleft")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(meal.timestamp, style: .time)
                    .font(.subheadline)

                if let description = meal.mealDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: meal.isOnTrack ? "checkmark.circle.fill" : "xmark.circle")
                .font(.title3)
                .foregroundStyle(meal.isOnTrack ? .green : .orange)
        }
        .padding(.vertical, 4)
    }
}
