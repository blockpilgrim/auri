import RealityKit
import UIKit
import simd

/// The central reactor core - the contained energy field at the heart of the Fusion Core.
///
/// Visual structure (from innermost to outermost):
/// 1. Plasma Center - Hot white point, always visible
/// 2. Inner Containment - Bright teal sphere, rapid shimmer
/// 3. Outer Containment - Larger teal sphere, slower pulse
/// 4. Energy Toroid - Horizontal spinning ring of energy
/// 5. Field Layers - Flattened spheroids that rotate, visible at higher adherence
/// 6. Atmosphere - Outer halo, subtle bloom
///
/// The core should feel like contained plasma, not just glowing spheres.
@MainActor
final class ReactorCore {
    let container: Entity

    // Core layers (innermost to outermost).
    private let plasmaCenter: ModelEntity
    private let innerContainment: ModelEntity
    private let outerContainment: ModelEntity
    private let energyToroid: ModelEntity
    private let fieldLayer1: ModelEntity
    private let fieldLayer2: ModelEntity
    private let atmosphere: ModelEntity

    // Animation state.
    private var toroidAngle: Float = 0
    private var field1Angle: Float = 0
    private var field2Angle: Float = 0

    // Base tilts for field layers.
    private let field1Tilt = simd_quatf(angle: 0.4, axis: normalize([1, 0, 0.3]))
    private let field2Tilt = simd_quatf(angle: 0.3, axis: normalize([0.2, 0, 1]))

    private let unitScale: Float

    private init(
        container: Entity,
        plasmaCenter: ModelEntity,
        innerContainment: ModelEntity,
        outerContainment: ModelEntity,
        energyToroid: ModelEntity,
        fieldLayer1: ModelEntity,
        fieldLayer2: ModelEntity,
        atmosphere: ModelEntity,
        unitScale: Float
    ) {
        self.container = container
        self.plasmaCenter = plasmaCenter
        self.innerContainment = innerContainment
        self.outerContainment = outerContainment
        self.energyToroid = energyToroid
        self.fieldLayer1 = fieldLayer1
        self.fieldLayer2 = fieldLayer2
        self.atmosphere = atmosphere
        self.unitScale = unitScale
    }

    // MARK: - Factory

    static func create(unitScale: Float) -> ReactorCore {
        let container = Entity()
        container.name = "ReactorCore"

        // Layer 1: Plasma center - hot white point.
        let plasmaCenter = glowSphere(
            name: "PlasmaCenter",
            radius: 0.08 * unitScale,
            color: CoreColors.whiteHot,
            opacity: 1.0
        )

        // Layer 2: Inner containment - bright teal.
        let innerContainment = glowSphere(
            name: "InnerContainment",
            radius: 0.18 * unitScale,
            color: CoreColors.lightTeal,
            opacity: 0.85
        )

        // Layer 3: Outer containment - larger teal.
        let outerContainment = glowSphere(
            name: "OuterContainment",
            radius: 0.32 * unitScale,
            color: CoreColors.coreTeal,
            opacity: 0.55
        )

        // Layer 4: Energy toroid - spinning horizontal ring.
        let energyToroid = glowTorus(
            name: "EnergyToroid",
            meanRadius: 0.28 * unitScale,
            tubeRadius: 0.022 * unitScale,
            color: CoreColors.coreTeal,
            opacity: 0.75
        )

        // Layer 5: Field layer 1 - flattened, rotates at 30%+.
        let fieldLayer1 = glowSphere(
            name: "FieldLayer1",
            radius: 0.42 * unitScale,
            color: CoreColors.coreTeal,
            opacity: 0.22
        )
        fieldLayer1.scale = [1.0, 0.65, 1.0] // Flatten vertically.
        fieldLayer1.isEnabled = false

        // Layer 6: Field layer 2 - counter-rotates at 50%+.
        let fieldLayer2 = glowSphere(
            name: "FieldLayer2",
            radius: 0.55 * unitScale,
            color: CoreColors.coreTeal,
            opacity: 0.12
        )
        fieldLayer2.scale = [1.0, 0.55, 1.0]
        fieldLayer2.isEnabled = false

        // Layer 7: Atmosphere - outer halo at 40%+.
        let atmosphere = glowSphere(
            name: "Atmosphere",
            radius: 0.75 * unitScale,
            color: CoreColors.coreTeal,
            opacity: 0.06
        )
        atmosphere.isEnabled = false

        // Add in order (outermost first for proper transparency).
        container.addChild(atmosphere)
        container.addChild(fieldLayer2)
        container.addChild(fieldLayer1)
        container.addChild(outerContainment)
        container.addChild(energyToroid)
        container.addChild(innerContainment)
        container.addChild(plasmaCenter)

        return ReactorCore(
            container: container,
            plasmaCenter: plasmaCenter,
            innerContainment: innerContainment,
            outerContainment: outerContainment,
            energyToroid: energyToroid,
            fieldLayer1: fieldLayer1,
            fieldLayer2: fieldLayer2,
            atmosphere: atmosphere,
            unitScale: unitScale
        )
    }

    // MARK: - Update

    func update(
        interpolator: StateInterpolator,
        pulse: MultiFrequencyPulse.PulseValues,
        deltaTime: Float,
        bloomMultiplier: Float
    ) {
        let adherence = interpolator.adherence
        let glow = interpolator.glowMultiplier * bloomMultiplier

        // Extract pulse values.
        let primary = pulse.primary
        let fast = pulse.fast
        let ultra = pulse.ultraFast

        // Update visibility thresholds.
        fieldLayer1.isEnabled = interpolator.showEnergyField1
        atmosphere.isEnabled = interpolator.showAtmosphere
        fieldLayer2.isEnabled = interpolator.showEnergyField2

        // Plasma center - always hot, shimmers with fast pulse. Boosted for more glow.
        updateLayer(
            plasmaCenter,
            color: CoreColors.whiteHot,
            opacity: clamp01(1.0 * (0.8 + 0.2 * glow) * (1.0 + fast * 0.8 + ultra * 0.4)),
            scale: lerp(1.0, 1.35, glow) * (1.0 + fast * 0.12)
        )

        // Inner containment - bright, shifts color at high adherence. Boosted.
        let innerColor = interpolator.innerCoreColor
        updateLayer(
            innerContainment,
            color: innerColor,
            opacity: clamp01(0.95 * glow * (1.0 + primary * 0.7 + fast * 0.3)),
            scale: lerp(1.0, 1.2, glow) * (1.0 + primary * 0.06)
        )

        // Outer containment - slower breathing. Boosted opacity.
        updateLayer(
            outerContainment,
            color: CoreColors.coreTeal,
            opacity: clamp01(0.70 * glow * (1.0 + primary * 0.8)),
            scale: lerp(1.0, 1.35, glow) * (1.0 + primary * 0.07)
        )

        // Energy toroid - spins fast. Boosted.
        toroidAngle = wrap(toroidAngle + deltaTime * lerp(1.5, 4.5, adherence))
        energyToroid.transform.rotation = simd_quatf(angle: toroidAngle, axis: [0, 1, 0])
        updateLayer(
            energyToroid,
            color: CoreColors.coreTeal,
            opacity: clamp01(0.88 * glow * (1.0 + primary * 0.9 + fast * 0.3)),
            scale: lerp(1.0, 1.18, glow) * (1.0 + primary * 0.05)
        )

        // Field layer 1 - slow tilt rotation. Boosted opacity.
        if fieldLayer1.isEnabled {
            field1Angle = wrap(field1Angle + deltaTime * lerp(0.25, 0.6, adherence))
            fieldLayer1.transform.rotation = simd_quatf(angle: field1Angle, axis: [0, 1, 0]) * field1Tilt
            updateLayer(
                fieldLayer1,
                color: CoreColors.coreTeal,
                opacity: clamp01(0.35 * glow * (1.0 + primary * 0.4)),
                scale: 1.0
            )
        }

        // Field layer 2 - counter-rotation. Boosted opacity.
        if fieldLayer2.isEnabled {
            field2Angle = wrap(field2Angle - deltaTime * lerp(0.2, 0.5, adherence))
            fieldLayer2.transform.rotation = simd_quatf(angle: field2Angle, axis: [0, 1, 0]) * field2Tilt
            updateLayer(
                fieldLayer2,
                color: CoreColors.coreTeal,
                opacity: clamp01(0.22 * glow * (1.0 + primary * 0.3)),
                scale: 1.0
            )
        }

        // Atmosphere - outer halo. Boosted for more dramatic bloom.
        if atmosphere.isEnabled {
            updateLayer(
                atmosphere,
                color: CoreColors.coreTeal,
                opacity: clamp01(0.12 * glow),
                scale: lerp(1.0, 1.6, glow)
            )
        }
    }

    // MARK: - Layer Helpers

    private static func glowSphere(name: String, radius: Float, color: UIColor, opacity: Float) -> ModelEntity {
        let mesh = MeshResource.generateSphere(radius: radius)
        var material = UnlitMaterial()
        material.color = .init(tint: CoreColors.withAlpha(color, opacity))
        material.blending = .transparent(opacity: .init(floatLiteral: opacity))

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = name
        return entity
    }

    private static func glowTorus(name: String, meanRadius: Float, tubeRadius: Float, color: UIColor, opacity: Float) -> ModelEntity {
        let mesh = MeshResource.generateTorus(meanRadius: meanRadius, tubeRadius: tubeRadius, segments: 64, tubeSegments: 16)
        var material = UnlitMaterial()
        material.color = .init(tint: CoreColors.withAlpha(color, opacity))
        material.blending = .transparent(opacity: .init(floatLiteral: opacity))

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = name
        return entity
    }

    private func updateLayer(_ entity: ModelEntity, color: UIColor, opacity: Float, scale: Float) {
        let clampedOpacity = clamp01(opacity)
        var material = UnlitMaterial()
        material.color = .init(tint: CoreColors.withAlpha(color, clampedOpacity))
        material.blending = .transparent(opacity: .init(floatLiteral: clampedOpacity))
        entity.model?.materials = [material]

        // Only update scale on non-flattened layers (fieldLayers have custom Y scale).
        if entity !== fieldLayer1 && entity !== fieldLayer2 {
            entity.scale = [scale, scale, scale]
        }
    }

    // MARK: - Utilities

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

// MARK: - Torus Mesh Generation

extension MeshResource {
    static func generateTorus(
        meanRadius: Float,
        tubeRadius: Float,
        segments: Int = 48,
        tubeSegments: Int = 24
    ) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []

        for i in 0...segments {
            let u = Float(i) / Float(segments)
            let theta = u * 2 * .pi

            let cosTheta = cos(theta)
            let sinTheta = sin(theta)

            for j in 0...tubeSegments {
                let v = Float(j) / Float(tubeSegments)
                let phi = v * 2 * .pi

                let cosPhi = cos(phi)
                let sinPhi = sin(phi)

                let x = (meanRadius + tubeRadius * cosPhi) * cosTheta
                let y = tubeRadius * sinPhi
                let z = (meanRadius + tubeRadius * cosPhi) * sinTheta

                positions.append([x, y, z])

                let nx = cosPhi * cosTheta
                let ny = sinPhi
                let nz = cosPhi * sinTheta
                normals.append(normalize([nx, ny, nz]))

                uvs.append([u, v])
            }
        }

        let tubeVertexCount = tubeSegments + 1
        for i in 0..<segments {
            for j in 0..<tubeSegments {
                let current = UInt32(i * tubeVertexCount + j)
                let next = UInt32((i + 1) * tubeVertexCount + j)

                indices.append(contentsOf: [
                    current, next, current + 1,
                    next, next + 1, current + 1,
                ])
            }
        }

        var descriptor = MeshDescriptor()
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.textureCoordinates = MeshBuffer(uvs)
        descriptor.primitives = .triangles(indices)

        return try! MeshResource.generate(from: [descriptor])
    }
}
