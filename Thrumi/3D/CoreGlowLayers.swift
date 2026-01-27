import RealityKit
import UIKit
import simd

@MainActor
final class CoreGlowLayers {
    let container: Entity

    private let hotCenter: ModelEntity
    private let innerCore: ModelEntity
    private let outerGlow: ModelEntity
    private let energyField1: ModelEntity
    private let energyField2: ModelEntity
    private let atmosphere: ModelEntity
    private let energyRing: ModelEntity

    private let unitScale: Float

    private let field1BaseTilt = simd_quatf(angle: 0.35, axis: [1, 0, 0])
    private let field2BaseTilt = simd_quatf(angle: 0.25, axis: [0, 0, 1])

    private var field1Angle: Float = 0
    private var field2Angle: Float = 0
    private var ringAngle: Float = 0

    private init(
        container: Entity,
        hotCenter: ModelEntity,
        innerCore: ModelEntity,
        outerGlow: ModelEntity,
        energyField1: ModelEntity,
        energyField2: ModelEntity,
        atmosphere: ModelEntity,
        energyRing: ModelEntity,
        unitScale: Float
    ) {
        self.container = container
        self.hotCenter = hotCenter
        self.innerCore = innerCore
        self.outerGlow = outerGlow
        self.energyField1 = energyField1
        self.energyField2 = energyField2
        self.atmosphere = atmosphere
        self.energyRing = energyRing
        self.unitScale = unitScale
    }

    static func create(unitScale: Float) -> CoreGlowLayers {
        let container = Entity()
        container.name = "CoreGlowLayers"

        let atmosphere = glowSphere(name: "Atmosphere", radius: 0.90 * unitScale, color: CoreColors.coreTeal, opacity: 0.05)
        let energyField2 = glowSphere(name: "EnergyField2", radius: 0.70 * unitScale, color: CoreColors.coreTeal, opacity: 0.10)
        let energyField1 = glowSphere(name: "EnergyField1", radius: 0.50 * unitScale, color: CoreColors.coreTeal, opacity: 0.25)
        let outerGlow = glowSphere(name: "OuterGlow", radius: 0.38 * unitScale, color: CoreColors.coreTeal, opacity: 0.60)
        let energyRing = glowRing(name: "EnergyRing", meanRadius: 0.35 * unitScale, tubeRadius: 0.018 * unitScale, color: CoreColors.coreTeal, opacity: 0.70)
        let innerCore = glowSphere(name: "InnerCore", radius: 0.25 * unitScale, color: CoreColors.lightTeal, opacity: 0.90)
        let hotCenter = glowSphere(name: "HotCenter", radius: 0.12 * unitScale, color: CoreColors.whiteHot, opacity: 1.00)

        // Make fields visibly rotatable.
        energyField1.scale = [1.0, 0.82, 1.0]
        energyField2.scale = [1.0, 0.76, 1.0]

        atmosphere.isEnabled = false
        energyField1.isEnabled = false
        energyField2.isEnabled = false

        container.addChild(atmosphere)
        container.addChild(energyField2)
        container.addChild(energyField1)
        container.addChild(outerGlow)
        container.addChild(energyRing)
        container.addChild(innerCore)
        container.addChild(hotCenter)

        return CoreGlowLayers(
            container: container,
            hotCenter: hotCenter,
            innerCore: innerCore,
            outerGlow: outerGlow,
            energyField1: energyField1,
            energyField2: energyField2,
            atmosphere: atmosphere,
            energyRing: energyRing,
            unitScale: unitScale
        )
    }

    func update(
        interpolator: StateInterpolator,
        pulse: MultiFrequencyPulse.PulseValues,
        deltaTime: Float,
        bloomMultiplier: Float
    ) {
        let adherence = interpolator.adherence

        let bloom = interpolator.bloomStrength * bloomMultiplier
        let bloomT = clamp01(bloom / 1.8)

        let glow = interpolator.glowMultiplier
        let coreColor = CoreColors.coreTeal
        let innerColor = interpolator.innerCoreColor

        // Layer visibility thresholds
        energyField1.isEnabled = interpolator.showEnergyField1
        atmosphere.isEnabled = interpolator.showAtmosphere
        energyField2.isEnabled = interpolator.showEnergyField2

        // Pulse shaping
        let primary = pulse.primary
        let fast = pulse.fast
        let ultra = pulse.ultraFast

        // Hot center
        setGlow(
            hotCenter,
            color: CoreColors.whiteHot,
            opacity: clamp01(1.0 * (0.55 + 0.45 * bloomT) * (1.0 + fast * 0.9 + ultra * 0.4)),
            scale: lerp(0.92, 1.20, bloomT) * (1.0 + fast * 0.10)
        )

        // Inner core (white shift at 80%+)
        setGlow(
            innerCore,
            color: innerColor,
            opacity: clamp01(0.90 * glow * (1.0 + primary * 0.65 + fast * 0.25) * (0.55 + 0.45 * bloomT)),
            scale: lerp(0.98, 1.12, bloomT) * (1.0 + primary * 0.06)
        )

        // Outer glow (acts as bloom)
        setGlow(
            outerGlow,
            color: coreColor,
            opacity: clamp01(0.60 * glow * (1.0 + primary * 0.85) * (0.40 + 0.60 * bloomT)),
            scale: lerp(1.05, 1.45, bloomT) * (1.0 + primary * 0.08)
        )

        // Energy ring
        ringAngle = wrap(ringAngle + deltaTime * lerp(0.6, 2.2, adherence))
        energyRing.transform.rotation = simd_quatf(angle: ringAngle, axis: [0, 1, 0])
        setGlow(
            energyRing,
            color: CoreColors.coreTeal,
            opacity: clamp01(0.70 * glow * (1.0 + primary * 0.9 + fast * 0.25) * (0.45 + 0.55 * bloomT)),
            scale: lerp(0.98, 1.10, bloomT) * (1.0 + primary * 0.05)
        )

        // Energy fields
        if energyField1.isEnabled {
            field1Angle = wrap(field1Angle + deltaTime * lerp(0.15, 0.45, adherence))
            energyField1.transform.rotation = simd_quatf(angle: field1Angle, axis: [0, 1, 0]) * field1BaseTilt
            setGlow(
                energyField1,
                color: coreColor,
                opacity: clamp01(0.25 * glow * (0.35 + 0.65 * bloomT) * (1.0 + primary * 0.35)),
                scale: 1.0
            )
        }

        if energyField2.isEnabled {
            field2Angle = wrap(field2Angle - deltaTime * lerp(0.12, 0.40, adherence))
            energyField2.transform.rotation = simd_quatf(angle: field2Angle, axis: [0, 1, 0]) * field2BaseTilt
            setGlow(
                energyField2,
                color: coreColor,
                opacity: clamp01(0.10 * glow * (0.30 + 0.70 * bloomT) * (1.0 + primary * 0.25)),
                scale: 1.0
            )
        }

        if atmosphere.isEnabled {
            setGlow(
                atmosphere,
                color: coreColor,
                opacity: clamp01(0.05 * glow * (0.20 + 0.80 * bloomT)),
                scale: lerp(1.05, 1.60, bloomT)
            )
        }
    }

    private static func glowSphere(name: String, radius: Float, color: UIColor, opacity: Float) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: radius)
        var material = UnlitMaterial()
        material.color = .init(tint: CoreColors.withAlpha(color, opacity))
        material.blending = .transparent(opacity: .init(floatLiteral: opacity))
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = name
        return entity
    }

    private static func glowRing(name: String, meanRadius: Float, tubeRadius: Float, color: UIColor, opacity: Float) -> ModelEntity {
        let mesh = MeshResource.generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius, segments: 72, tubeSegments: 18)
        var material = UnlitMaterial()
        material.color = .init(tint: CoreColors.withAlpha(color, opacity))
        material.blending = .transparent(opacity: .init(floatLiteral: opacity))
        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = name
        return entity
    }

    private func setGlow(_ entity: ModelEntity, color: UIColor, opacity: Float, scale: Float) {
        let opacity = clamp01(opacity)
        var material = UnlitMaterial()
        material.color = .init(tint: CoreColors.withAlpha(color, opacity))
        material.blending = .transparent(opacity: .init(floatLiteral: opacity))
        entity.model?.materials = [material]
        entity.scale = [scale, scale, scale]
    }

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * clamp01(t)
    }

    private func wrap(_ radians: Float) -> Float {
        radians.truncatingRemainder(dividingBy: 2 * .pi)
    }

    private func clamp01(_ x: Float) -> Float {
        max(0, min(1, x))
    }
}
