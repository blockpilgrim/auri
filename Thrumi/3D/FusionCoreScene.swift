import RealityKit
import UIKit
import simd

/// The Fusion Core 3D scene - a magnetically-levitated industrial fidget spinner
/// inspired by arc reactor technology.
///
/// Design philosophy (per PRODUCT.md):
/// - Machined precision plus alive glow
/// - Materials: brushed palladium/steel, machined chamfers, exposed copper coils
/// - Center: contained energy field (procedural glow)
/// - Should feel like a functional power module, not a toy
@MainActor
final class FusionCoreScene {
    /// Unit scale converts design units to RealityKit meters.
    /// All dimensions are authored at ~1.0 unit = full core radius.
    static let unitScale: Float = 0.045

    let rootEntity: Entity
    let particleManager: ParticleSystem

    private let reactorCore: ReactorCore
    private let spinnerRings: SpinnerRings
    private let coreLight: Entity
    private let rimLight: Entity

    private init(
        rootEntity: Entity,
        reactorCore: ReactorCore,
        spinnerRings: SpinnerRings,
        particleManager: ParticleSystem,
        coreLight: Entity,
        rimLight: Entity
    ) {
        self.rootEntity = rootEntity
        self.reactorCore = reactorCore
        self.spinnerRings = spinnerRings
        self.particleManager = particleManager
        self.coreLight = coreLight
        self.rimLight = rimLight
    }

    // MARK: - Factory

    static func create() async -> FusionCoreScene {
        let root = Entity()
        root.name = "FusionCore"

        // Scale and position for hero presentation.
        // RealityKit uses meters; we position the core in front of the default camera.
        root.scale = SIMD3<Float>(repeating: 5.0)
        root.position = [0, -0.04, -0.28]

        // Pitch the scene to simulate a fixed camera looking down at ~60°.
        let pitch: Float = 60.0 * .pi / 180.0
        root.transform.rotation = simd_quatf(angle: pitch, axis: [1, 0, 0])

        // Build the reactor core (central energy field).
        let core = ReactorCore.create(unitScale: unitScale)
        root.addChild(core.container)

        // Build the spinning rings (industrial structure).
        let rings = SpinnerRings.create(unitScale: unitScale)
        root.addChild(rings.container)

        // Create lighting.
        let coreLight = createPointLight(
            name: "CoreLight",
            color: CoreColors.coreTeal,
            intensity: 2000,
            attenuationRadius: 0.5,
            position: [0, 0, 0]
        )

        let rimLight = createPointLight(
            name: "RimLight",
            color: CoreColors.coilGlow,
            intensity: 800,
            attenuationRadius: 0.35,
            position: [0, 0.02, 0]
        )

        root.addChild(coreLight)
        root.addChild(rimLight)
        root.addChild(createFillLight())

        // Create particle system.
        let particles = ParticleSystem(ringRadii: rings.ringRadii, unitScale: unitScale)
        root.addChild(particles.container)

        return FusionCoreScene(
            rootEntity: root,
            reactorCore: core,
            spinnerRings: rings,
            particleManager: particles,
            coreLight: coreLight,
            rimLight: rimLight
        )
    }

    // MARK: - Update

    func update(
        interpolator: StateInterpolator,
        pulse: MultiFrequencyPulse.PulseValues,
        deltaTime: Float,
        spinAngle: Float,
        currentTime: TimeInterval,
        bloomMultiplier: Float,
        thermalParticleMultiplier: Float,
        showParticles: Bool
    ) {
        // Update reactor core glow.
        reactorCore.update(
            interpolator: interpolator,
            pulse: pulse,
            deltaTime: deltaTime,
            bloomMultiplier: bloomMultiplier
        )

        // Update spinning rings.
        spinnerRings.update(
            spinAngle: spinAngle,
            interpolator: interpolator,
            pulse: pulse,
            deltaTime: deltaTime
        )

        // Update lights.
        updateLights(interpolator: interpolator, pulse: pulse)

        // Update particles.
        particleManager.update(
            interpolator: interpolator,
            deltaTime: deltaTime,
            currentTime: currentTime,
            thermalMultiplier: thermalParticleMultiplier,
            enabled: showParticles
        )
    }

    // MARK: - Lighting

    private func updateLights(interpolator: StateInterpolator, pulse: MultiFrequencyPulse.PulseValues) {
        let lightPulse = 1.0 + pulse.primary * 0.4 + pulse.fast * 0.15

        if var light = coreLight.components[PointLightComponent.self] {
            light.intensity = 2000 * interpolator.coreLightIntensity * lightPulse
            light.attenuationRadius = lerp(0.25, 0.55, interpolator.adherence)
            coreLight.components.set(light)
        }

        if var light = rimLight.components[PointLightComponent.self] {
            light.intensity = 800 * interpolator.coilLightIntensity * (1.0 + pulse.fast * 0.25)
            light.attenuationRadius = lerp(0.18, 0.40, interpolator.adherence)
            rimLight.components.set(light)
        }
    }

    // MARK: - Light Creation

    private static func createPointLight(
        name: String,
        color: UIColor,
        intensity: Float,
        attenuationRadius: Float,
        position: SIMD3<Float>
    ) -> Entity {
        let entity = Entity()
        entity.name = name
        entity.position = position

        var light = PointLightComponent()
        light.color = .init(cgColor: color.cgColor)
        light.intensity = intensity
        light.attenuationRadius = attenuationRadius
        entity.components.set(light)

        return entity
    }

    private static func createFillLight() -> Entity {
        let entity = Entity()
        entity.name = "FillLight"

        var light = DirectionalLightComponent()
        light.color = .init(white: 0.92, alpha: 1.0)
        light.intensity = 500
        entity.components.set(light)

        // Angle from upper-front.
        entity.transform.rotation = simd_quatf(angle: -.pi / 3.5, axis: [1, 0, 0])
            * simd_quatf(angle: .pi / 7, axis: [0, 1, 0])

        return entity
    }

    // MARK: - Utilities

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * clamp01(t)
    }

    private func clamp01(_ x: Float) -> Float {
        max(0, min(1, x))
    }
}
