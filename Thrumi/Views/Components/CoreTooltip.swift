import SwiftUI

/// A one-time tooltip explaining how the Fusion Core's state is calculated.
/// Per PRODUCT.md: "use a one-time tooltip in week one (e.g., 'Core reflects Today + Past 7 Days')"
struct CoreTooltip: View {
    @AppStorage("hasSeenCoreTooltip") private var hasSeenTooltip = false
    @State private var isVisible = false
    @State private var opacity: Double = 0

    /// The date when the user first installed the app (stored in UserDefaults)
    private var installDate: Date {
        if let stored = UserDefaults.standard.object(forKey: "appInstallDate") as? Date {
            return stored
        } else {
            let now = Date()
            UserDefaults.standard.set(now, forKey: "appInstallDate")
            return now
        }
    }

    /// Whether we're still within the first week after install
    private var isWithinFirstWeek: Bool {
        let daysSinceInstall = Calendar.current.dateComponents(
            [.day],
            from: installDate,
            to: Date()
        ).day ?? 0
        return daysSinceInstall < 7
    }

    var body: some View {
        Group {
            if isVisible {
                tooltipContent
                    .opacity(opacity)
            }
        }
        .onAppear {
            checkAndShow()
        }
    }

    private var tooltipContent: some View {
        VStack(spacing: 12) {
            Text("Your Core reflects Today + Past 7 Days")
                .font(.callout)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Button {
                dismissTooltip()
            } label: {
                Text("Got it")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
        .padding(.horizontal, 40)
    }

    private func checkAndShow() {
        // Don't show if already dismissed
        guard !hasSeenTooltip else { return }

        // Only show during first week
        guard isWithinFirstWeek else { return }

        // Show with a slight delay so it doesn't appear immediately on launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeIn(duration: 0.3)) {
                isVisible = true
                opacity = 1.0
            }
        }
    }

    private func dismissTooltip() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isVisible = false
            hasSeenTooltip = true
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        // Reset preview state
        CoreTooltip()
            .onAppear {
                UserDefaults.standard.removeObject(forKey: "hasSeenCoreTooltip")
                UserDefaults.standard.removeObject(forKey: "appInstallDate")
            }
    }
}
