import SwiftUI

struct MetricCard: View {
    let title: String
    let value: Double
    var isHighlighted: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            Text("\(Int(value * 100))%")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(isHighlighted ? .primary : .secondary)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .glassCard()
    }
}

#Preview("Highlighted") {
    MetricCard(title: "Today", value: 0.85, isHighlighted: true)
        .padding()
}

#Preview("Normal") {
    MetricCard(title: "Past 7 Days", value: 0.72)
        .padding()
}

#Preview("Zero") {
    MetricCard(title: "Past 30 Days", value: 0)
        .padding()
}
