import SwiftUI

/// Displays the Today's adherence percentage as a subtle HUD overlay.
/// Per PRODUCT.md Section 13: "Display Today's adherence subtly (not dashboard-y)"
struct CoreHUD: View {
    let adherence: AdherenceState?

    var body: some View {
        VStack {
            HStack {
                adherenceLabel
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)

            Spacer()
        }
    }

    @ViewBuilder
    private var adherenceLabel: some View {
        let percentage = Int((adherence?.todayAdherence ?? 0) * 100)

        VStack(alignment: .leading, spacing: 2) {
            Text("TODAY")
                .font(.caption2)
                .fontWeight(.medium)
                .tracking(0.8)
                .foregroundStyle(.white.opacity(0.45))
            Text("\(percentage)%")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .glassCard()
    }
}

#Preview("High Adherence") {
    ZStack {
        Color.black.ignoresSafeArea()
        CoreHUD(adherence: AdherenceState(
            todayAdherence: 0.85,
            rolling7Adherence: 0.80,
            rolling30Adherence: 0.75
        ))
    }
}

#Preview("Low Adherence") {
    ZStack {
        Color.black.ignoresSafeArea()
        CoreHUD(adherence: AdherenceState(
            todayAdherence: 0.35,
            rolling7Adherence: 0.40,
            rolling30Adherence: 0.45
        ))
    }
}

#Preview("No Data") {
    ZStack {
        Color.black.ignoresSafeArea()
        CoreHUD(adherence: nil)
    }
}
