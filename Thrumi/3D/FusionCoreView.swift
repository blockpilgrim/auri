import RealityKit
import SwiftUI

/// A SwiftUI view that renders the Fusion Core 3D model using RealityKit.
///
/// The Fusion Core is a magnetically-levitated, industrial high-tech fidget spinner
/// that visualizes the user's adherence state.
struct FusionCoreView: View {
    /// The current adherence state that drives the Core's visual appearance.
    let adherenceState: AdherenceState

    @State private var scene: FusionCoreScene?
    @State private var cameraAngle: Float = 0
    @State private var cameraElevation: Float = 0.3

    // Drag gesture state
    @State private var lastDragValue: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            RealityView { content in
                // Create and add the Fusion Core scene
                let fusionCore = await FusionCoreScene.create()
                content.add(fusionCore.rootEntity)

                // Add camera anchor for orbit controls
                let cameraAnchor = createCameraAnchor()
                content.add(cameraAnchor)

                // Add ambient lighting
                let ambientLight = createAmbientLight()
                content.add(ambientLight)

                // Store scene reference for updates
                await MainActor.run {
                    scene = fusionCore
                }
            } update: { content in
                // Update visual state based on adherence
                updateCoreAppearance()
                updateCameraPosition()
            }
            .gesture(dragGesture)
            .ignoresSafeArea()
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let delta = CGSize(
                    width: value.translation.width - lastDragValue.width,
                    height: value.translation.height - lastDragValue.height
                )

                // Horizontal drag rotates camera around Y axis
                cameraAngle += Float(delta.width) * 0.01

                // Vertical drag adjusts elevation (clamped)
                cameraElevation = max(-0.8, min(0.8, cameraElevation - Float(delta.height) * 0.005))

                lastDragValue = value.translation
            }
            .onEnded { _ in
                lastDragValue = .zero
            }
    }

    // MARK: - Scene Setup

    private func createCameraAnchor() -> Entity {
        let anchor = Entity()
        anchor.name = "CameraAnchor"
        anchor.position = [0, 0, 0.4] // Initial camera distance
        return anchor
    }

    private func createAmbientLight() -> Entity {
        let light = Entity()
        light.name = "AmbientLight"

        // Directional light for key lighting
        var directionalLight = DirectionalLightComponent()
        directionalLight.color = .init(white: 0.9, alpha: 1.0)
        directionalLight.intensity = 1500

        light.components.set(directionalLight)
        light.transform.rotation = simd_quatf(angle: -.pi / 4, axis: [1, 0, 0])

        return light
    }

    // MARK: - State Updates

    private func updateCoreAppearance() {
        guard let scene else { return }

        // Map adherence to visual parameters using the reward curve
        let power = applyRewardCurve(adherenceState.coreAdherence)

        // Update emissive intensity (center glow and coils)
        let glowIntensity = Float(0.3 + power * 0.7)
        scene.setEmissiveIntensity(glowIntensity, for: .center)
        scene.setEmissiveIntensity(glowIntensity * 0.8, for: .coils)

        // Update light intensity
        scene.setLightIntensity(Float(0.4 + power * 0.6))

        // Update ring roughness (higher adherence = shinier)
        let roughness = Float(0.4 - power * 0.25)
        scene.setMetallicRoughness(roughness, for: .outerRing)
        scene.setMetallicRoughness(roughness * 0.9, for: .middleRing)
        scene.setMetallicRoughness(roughness * 0.8, for: .innerRing)
    }

    private func updateCameraPosition() {
        guard let scene else { return }

        // The root entity stays at origin; we rotate the model to simulate camera orbit
        scene.rootEntity.transform.rotation = simd_quatf(angle: -cameraAngle, axis: [0, 1, 0])
            * simd_quatf(angle: -cameraElevation, axis: [1, 0, 0])
    }

    /// Applies the reward curve to make 80% feel awesome.
    /// power = 1 - (1 - adherence)^k where k ~ 2.5
    private func applyRewardCurve(_ adherence: Double) -> Double {
        let k = 2.5
        return 1 - pow(1 - adherence, k)
    }
}

// MARK: - Previews

#Preview("Phase-Locked (100%)") {
    FusionCoreView(adherenceState: AdherenceState(
        todayAdherence: 1.0,
        rolling7Adherence: 1.0,
        rolling30Adherence: 1.0
    ))
    .background(Color.black)
}

#Preview("Online (80%)") {
    FusionCoreView(adherenceState: AdherenceState(
        todayAdherence: 0.8,
        rolling7Adherence: 0.8,
        rolling30Adherence: 0.8
    ))
    .background(Color.black)
}

#Preview("Stabilizing (60%)") {
    FusionCoreView(adherenceState: AdherenceState(
        todayAdherence: 0.6,
        rolling7Adherence: 0.6,
        rolling30Adherence: 0.6
    ))
    .background(Color.black)
}

#Preview("Safe Mode (20%)") {
    FusionCoreView(adherenceState: AdherenceState(
        todayAdherence: 0.2,
        rolling7Adherence: 0.2,
        rolling30Adherence: 0.2
    ))
    .background(Color.black)
}
