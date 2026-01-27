import SwiftUI

struct TrackingButtons: View {
    let onSave: (Bool) -> Void
    let isEnabled: Bool

    init(isEnabled: Bool = true, onSave: @escaping (Bool) -> Void) {
        self.isEnabled = isEnabled
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Was this meal on track?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Button(action: { onSave(false) }) {
                    Label("Off Track", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!isEnabled)

                Button(action: { onSave(true) }) {
                    Label("On Track", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isEnabled)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    TrackingButtons { isOnTrack in
        print("Saved: \(isOnTrack)")
    }
}
