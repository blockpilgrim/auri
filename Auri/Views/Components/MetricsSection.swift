import SwiftUI

struct MetricsSection: View {
    let state: AdherenceState?

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                MetricCard(
                    title: "Today",
                    value: state?.todayAdherence ?? 0,
                    isHighlighted: true
                )
                MetricCard(
                    title: "Past 7 Days",
                    value: state?.rolling7Adherence ?? 0
                )
                MetricCard(
                    title: "Past 30 Days",
                    value: state?.rolling30Adherence ?? 0
                )
            }

            Text("Your Core reflects Today (60%) + Past 7 Days (40%)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("With Data") {
    MetricsSection(state: AdherenceState(
        todayAdherence: 0.85,
        rolling7Adherence: 0.72,
        rolling30Adherence: 0.68
    ))
    .padding()
}

#Preview("No Data") {
    MetricsSection(state: nil)
        .padding()
}
