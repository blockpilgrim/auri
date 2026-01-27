import SwiftUI

struct CoreView: View {
    @Environment(\.adherenceEngine) private var adherenceEngine

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            // Fusion Core 3D View (full screen)
            FusionCoreView(
                adherenceState: adherenceEngine?.state ?? .empty,
                adherenceEngine: adherenceEngine
            )

            // HUD Overlay
            CoreHUD(adherence: adherenceEngine?.state)

            // First-week tooltip
            CoreTooltip()
        }
        .onAppear {
            // Recalculate adherence when view appears
            // This ensures state is fresh after returning from other screens
            adherenceEngine?.recalculate()
        }
    }
}

#Preview {
    CoreView()
}
