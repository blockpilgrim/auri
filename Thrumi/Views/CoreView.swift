import SwiftUI

struct CoreView: View {
    @Environment(\.adherenceEngine) private var adherenceEngine
    @Environment(\.hapticsManager) private var hapticsManager

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            // Wisp Orb 3D View (full screen)
            WispOrbView(
                adherenceState: adherenceEngine?.state ?? .empty,
                adherenceEngine: adherenceEngine,
                hapticsManager: hapticsManager
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
