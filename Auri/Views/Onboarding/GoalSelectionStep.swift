import SwiftUI

/// Dietary goal selection - second step of onboarding.
/// Allows user to select what "on track" means for them.
struct GoalSelectionStep: View {
    let onSelect: (DietaryGoal, String?) -> Void

    @State private var showingCustomInput = false
    @State private var customText = ""
    @FocusState private var customFieldFocused: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 60)

            VStack(spacing: 8) {
                Text("What's your goal?")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                Text("This helps you define what 'on track' means")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }

            Spacer()
                .frame(height: 20)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(DietaryGoal.allCases, id: \.self) { goal in
                    if goal == .custom {
                        GoalButton(goal: goal) {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showingCustomInput = true
                            }
                            customFieldFocused = true
                        }
                    } else {
                        GoalButton(goal: goal) {
                            onSelect(goal, nil)
                        }
                    }
                }
            }

            if showingCustomInput {
                VStack(spacing: 12) {
                    TextField("e.g. Carnivore, Lion Diet", text: $customText)
                        .font(.body)
                        .padding(12)
                        .background(.ultraThinMaterial.opacity(0.8))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                        .focused($customFieldFocused)
                        .submitLabel(.done)
                        .onSubmit { saveCustom() }

                    Button(action: saveCustom) {
                        Text("Continue")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background {
                                if customText.trimmingCharacters(in: .whitespaces).isEmpty {
                                    Color.white.opacity(0.15)
                                } else {
                                    LinearGradient(
                                        colors: [.cyan, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(customText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func saveCustom() {
        let trimmed = customText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onSelect(.custom, trimmed)
    }
}

#Preview {
    GoalSelectionStep(onSelect: { goal, name in
        print("Selected: \(goal), custom: \(name ?? "none")")
    })
    .background(Color.black)
}
