import SwiftUI

/// A sheet allowing the user to change their dietary goal.
struct DietPickerSheet: View {
    let currentGoal: DietaryGoal
    let onSelect: (DietaryGoal) -> Void
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("This defines what 'on track' means for you")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(DietaryGoal.allCases, id: \.self) { goal in
                            DietOptionButton(
                                goal: goal,
                                isSelected: goal == currentGoal
                            ) {
                                onSelect(goal)
                                dismiss()
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle("Diet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

/// A single diet option in the picker grid.
private struct DietOptionButton: View {
    let goal: DietaryGoal
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(goal.displayName)
                    .font(.subheadline.weight(.medium))

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                }
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color.accentColor.opacity(0.85) : Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.primary.opacity(0.08),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DietPickerSheet(currentGoal: .keto, onSelect: { _ in })
}
