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

            HStack(spacing: 12) {
                Button(action: { onSave(false) }) {
                    Label("Off Track", systemImage: "xmark.circle")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .glassCard()
                .opacity(isEnabled ? 1.0 : 0.4)
                .disabled(!isEnabled)

                Button(action: { onSave(true) }) {
                    Label("On Track", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(GlassStyle.onTrackColor.opacity(0.95))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                .background(
                    RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                        .fill(GlassStyle.onTrackFill)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GlassStyle.cornerRadius)
                        .strokeBorder(GlassStyle.onTrackBorderGradient, lineWidth: GlassStyle.borderWidth)
                )
                .opacity(isEnabled ? 1.0 : 0.4)
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
