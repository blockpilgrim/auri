import SwiftUI

struct CoreView: View {
    @Environment(\.adherenceEngine) private var adherenceEngine

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Fusion Core 3D View
                FusionCoreView(
                    adherenceState: adherenceEngine?.state ?? .empty,
                    adherenceEngine: adherenceEngine
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Today's adherence HUD
                HStack {
                    adherenceHUD
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            }
        }
    }

    @ViewBuilder
    private var adherenceHUD: some View {
        let percentage = Int((adherenceEngine?.state.todayAdherence ?? 0) * 100)
        VStack(alignment: .leading, spacing: 2) {
            Text("TODAY")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.gray)
            Text("\(percentage)%")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    CoreView()
}
