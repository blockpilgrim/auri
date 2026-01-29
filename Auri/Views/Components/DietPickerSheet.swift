import SwiftUI

/// A sheet allowing the user to change their dietary goal.
struct DietPickerSheet: View {
    let currentGoal: DietaryGoal
    let currentCustomName: String?
    let onSelect: (DietaryGoal, String?) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var showingCustomInput = false
    @State private var customText = ""
    @State private var selectedDetent: PresentationDetent = .medium
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
                                    selectedDetent = .large
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
                        let canSave = !customText.trimmingCharacters(in: .whitespaces).isEmpty

                        VStack(spacing: 12) {
                            TextField("e.g. Carnivore, Lion Diet", text: $customText)
                                .font(.body)
                                .padding(12)
                                .background(GlassStyle.cardFill)
                                .clipShape(RoundedRectangle(cornerRadius: GlassStyle.cornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                                        .strokeBorder(GlassStyle.borderGradient, lineWidth: GlassStyle.borderWidth)
                                )
                                .focused($customFieldFocused)
                                .submitLabel(.done)
                                .onSubmit { saveCustom() }

                            Button(action: saveCustom) {
                                Text("Save")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(canSave ? .white.opacity(0.9) : .white.opacity(0.3))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                                            .fill(canSave ? GlassStyle.onTrackFill : GlassStyle.cardFill)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                                            .strokeBorder(
                                                canSave ? GlassStyle.onTrackBorderGradient : GlassStyle.borderGradient,
                                                lineWidth: GlassStyle.borderWidth
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                            .disabled(!canSave)
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
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(.visible)
        .presentationBackground(.black)
        .preferredColorScheme(.dark)
        .onAppear {
            if currentGoal == .custom {
                customText = currentCustomName ?? ""
            }
        }
        .onChange(of: showingCustomInput) {
            if !showingCustomInput {
                selectedDetent = .medium
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
            .foregroundStyle(isSelected ? .white.opacity(0.95) : .white.opacity(0.7))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                    .fill(isSelected ? GlassStyle.selectedFill : GlassStyle.cardFill)
            )
            .clipShape(RoundedRectangle(cornerRadius: GlassStyle.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                    .strokeBorder(
                        isSelected ? GlassStyle.selectedBorderGradient : GlassStyle.borderGradient,
                        lineWidth: GlassStyle.borderWidth
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
