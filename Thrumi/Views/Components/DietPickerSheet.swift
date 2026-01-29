import SwiftUI

/// A sheet allowing the user to change their dietary goal.
struct DietPickerSheet: View {
    let currentGoal: DietaryGoal
    let currentCustomName: String?
    let onSelect: (DietaryGoal, String?) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var showingCustomInput = false
    @State private var customText = ""
    @FocusState private var customFieldFocused: Bool

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
                            if goal == .custom {
                                DietOptionButton(
                                    goal: goal,
                                    isSelected: currentGoal == .custom && !showingCustomInput
                                ) {
                                    showingCustomInput = true
                                    customFieldFocused = true
                                }
                            } else {
                                DietOptionButton(
                                    goal: goal,
                                    isSelected: goal == currentGoal && !showingCustomInput
                                ) {
                                    onSelect(goal, nil)
                                    dismiss()
                                }
                            }
                        }
                    }

                    if showingCustomInput {
                        VStack(spacing: 12) {
                            TextField("e.g. Carnivore, Lion Diet", text: $customText)
                                .font(.body)
                                .padding(12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .focused($customFieldFocused)
                                .submitLabel(.done)
                                .onSubmit { saveCustom() }

                            Button(action: saveCustom) {
                                Text("Save")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(customText.trimmingCharacters(in: .whitespaces).isEmpty
                                        ? Color.accentColor.opacity(0.4)
                                        : Color.accentColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .disabled(customText.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .animation(.easeInOut(duration: 0.2), value: showingCustomInput)
            }
            .navigationTitle("Diet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            if currentGoal == .custom {
                customText = currentCustomName ?? ""
            }
        }
    }

    private func saveCustom() {
        let trimmed = customText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onSelect(.custom, trimmed)
        dismiss()
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
    DietPickerSheet(currentGoal: .keto, currentCustomName: nil, onSelect: { _, _ in })
}

#Preview("Custom Selected") {
    DietPickerSheet(currentGoal: .custom, currentCustomName: "Carnivore", onSelect: { _, _ in })
}
