import RealityKit
import UIKit
import simd

/// The spinning ring structure of the Fusion Core.
///
/// Industrial design elements (per PRODUCT.md):
/// - Brushed palladium/steel material
/// - Machined chamfers and grooves
/// - Exposed copper coils
/// - Segmented ring structure (like turbine blades)
///
/// The rings spin at different speeds and directions to create
/// a gyroscopic, magnetically-levitated impression.
@MainActor
final class SpinnerRings {
    let container: Entity

    /// Mean radii of each ring for particle spawn positions.
    let ringRadii: [Float]

    private var rings: [RingAssembly] = []
    private var coilEntities: [ModelEntity] = []
    private var lastRoughness: Float = -1

    private let unitScale: Float

    /// Ring specification.
    private struct RingSpec {
        let innerRadius: Float
        let outerRadius: Float
        let thickness: Float
        let direction: Float // 1 = CW, -1 = CCW
        let speedMultiplier: Float
        let segmentCount: Int
        let hasCoils: Bool
        let coilCount: Int
    }

    /// A ring assembly with its sub-components.
    private struct RingAssembly {
        let group: Entity
        let body: ModelEntity
        let innerGroove: ModelEntity
        let outerGroove: ModelEntity
        let segments: [ModelEntity]
        let coils: [ModelEntity]
        let direction: Float
        let speedMultiplier: Float
    }

    // Ring configuration - 3 main rings with industrial detail.
    private static let ringSpecs: [RingSpec] = [
        // Inner ring - fastest, CW, with coils.
        RingSpec(
            innerRadius: 0.48, outerRadius: 0.62, thickness: 0.055,
            direction: 1, speedMultiplier: 1.0,
            segmentCount: 12, hasCoils: true, coilCount: 6
        ),
        // Middle ring - medium speed, CCW.
        RingSpec(
            innerRadius: 0.72, outerRadius: 0.88, thickness: 0.045,
            direction: -1, speedMultiplier: 0.72,
            segmentCount: 16, hasCoils: true, coilCount: 8
        ),
        // Outer ring - slowest, CW, with coils.
        RingSpec(
            innerRadius: 0.98, outerRadius: 1.18, thickness: 0.038,
            direction: 1, speedMultiplier: 0.48,
            segmentCount: 20, hasCoils: true, coilCount: 10
        ),
    ]

    private init(container: Entity, rings: [RingAssembly], coilEntities: [ModelEntity], ringRadii: [Float], unitScale: Float) {
        self.container = container
        self.rings = rings
        self.coilEntities = coilEntities
        self.ringRadii = ringRadii
        self.unitScale = unitScale
    }

    // MARK: - Factory

    static func create(unitScale: Float) -> SpinnerRings {
        let container = Entity()
        container.name = "SpinnerRings"

        var assemblies: [RingAssembly] = []
        var allCoils: [ModelEntity] = []
        var radii: [Float] = []

        for (index, spec) in ringSpecs.enumerated() {
            let assembly = createRingAssembly(spec: spec, unitScale: unitScale, index: index)
            assemblies.append(assembly)
            allCoils.append(contentsOf: assembly.coils)
            container.addChild(assembly.group)

            // Calculate mean radius for particle spawning.
            let meanRadius = ((spec.innerRadius + spec.outerRadius) / 2.0) * unitScale
            radii.append(meanRadius)
        }

        return SpinnerRings(
            container: container,
            rings: assemblies,
            coilEntities: allCoils,
            ringRadii: radii,
            unitScale: unitScale
        )
    }

    // MARK: - Update

    func update(
        spinAngle: Float,
        interpolator: StateInterpolator,
        pulse: MultiFrequencyPulse.PulseValues,
        deltaTime: Float
    ) {
        // Spin each ring.
        for ring in rings {
            let angle = spinAngle * ring.speedMultiplier * ring.direction
            ring.group.transform.rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
        }

        // Update ring material roughness if changed.
        let roughness = interpolator.ringRoughness
        if abs(roughness - lastRoughness) > 0.002 {
            lastRoughness = roughness
            updateRingMaterials(roughness: roughness)
        }

        // Update coil glow.
        updateCoilGlow(interpolator: interpolator, pulse: pulse)
    }

    // MARK: - Ring Creation

    private static func createRingAssembly(spec: RingSpec, unitScale: Float, index: Int) -> RingAssembly {
        let group = Entity()
        group.name = "Ring\(index + 1)"

        let midRadius = ((spec.innerRadius + spec.outerRadius) / 2.0) * unitScale
        let tubeRadius = ((spec.outerRadius - spec.innerRadius) / 2.0) * unitScale

        // Main ring body - brushed metal torus.
        let bodyMesh = MeshResource.generateTorus(
            meanRadius: midRadius,
            tubeRadius: tubeRadius,
            segments: 96,
            tubeSegments: 20
        )
        let body = ModelEntity(mesh: bodyMesh, materials: [ringBodyMaterial(roughness: 0.35)])
        body.name = "Body"
        group.addChild(body)

        // Inner machined groove.
        let innerGrooveMesh = MeshResource.generateTorus(
            meanRadius: midRadius - tubeRadius * 0.4,
            tubeRadius: max(0.0008, tubeRadius * 0.12),
            segments: 80,
            tubeSegments: 12
        )
        let innerGroove = ModelEntity(mesh: innerGrooveMesh, materials: [grooveMaterial(roughness: 0.18)])
        innerGroove.name = "InnerGroove"
        group.addChild(innerGroove)

        // Outer machined groove.
        let outerGrooveMesh = MeshResource.generateTorus(
            meanRadius: midRadius + tubeRadius * 0.45,
            tubeRadius: max(0.0008, tubeRadius * 0.10),
            segments: 80,
            tubeSegments: 12
        )
        let outerGroove = ModelEntity(mesh: outerGrooveMesh, materials: [grooveMaterial(roughness: 0.18)])
        outerGroove.name = "OuterGroove"
        group.addChild(outerGroove)

        // Segment dividers - creates turbine blade look.
        var segments: [ModelEntity] = []
        for i in 0..<spec.segmentCount {
            let angle = Float(i) / Float(spec.segmentCount) * 2 * .pi
            let segment = createSegmentDivider(
                radius: midRadius,
                tubeRadius: tubeRadius,
                angle: angle,
                thickness: spec.thickness * unitScale
            )
            segments.append(segment)
            group.addChild(segment)
        }

        // Copper coils.
        var coils: [ModelEntity] = []
        if spec.hasCoils {
            for i in 0..<spec.coilCount {
                let angle = Float(i) / Float(spec.coilCount) * 2 * .pi
                // Offset from segment dividers.
                let offsetAngle = angle + (.pi / Float(spec.coilCount))
                let coil = createCoilModule(
                    radius: midRadius,
                    tubeRadius: tubeRadius,
                    angle: offsetAngle
                )
                coils.append(coil)
                group.addChild(coil)
            }
        }

        // Slight Y offset for visual layering.
        let yOffset: Float = Float(index) * 0.002 - 0.002
        group.position.y = yOffset

        return RingAssembly(
            group: group,
            body: body,
            innerGroove: innerGroove,
            outerGroove: outerGroove,
            segments: segments,
            coils: coils,
            direction: spec.direction,
            speedMultiplier: spec.speedMultiplier
        )
    }

    private static func createSegmentDivider(radius: Float, tubeRadius: Float, angle: Float, thickness: Float) -> ModelEntity {
        let width = tubeRadius * 0.08
        let height = tubeRadius * 1.6
        let depth = thickness * 0.15

        let mesh = MeshResource.generateBox(width: width, height: height, depth: depth)
        let entity = ModelEntity(mesh: mesh, materials: [grooveMaterial(roughness: 0.22)])
        entity.name = "Segment"

        // Position on ring surface.
        let radial = SIMD3<Float>(cos(angle), 0, sin(angle))
        entity.position = radial * radius + SIMD3<Float>(0, tubeRadius * 0.1, 0)
        entity.transform.rotation = simd_quatf(angle: angle, axis: [0, 1, 0])

        return entity
    }

    private static func createCoilModule(radius: Float, tubeRadius: Float, angle: Float) -> ModelEntity {
        // Coil base dimensions.
        let baseWidth = tubeRadius * 0.9
        let baseHeight = tubeRadius * 0.5
        let baseDepth = tubeRadius * 0.7

        let mesh = MeshResource.generateBox(width: baseWidth, height: baseHeight, depth: baseDepth, cornerRadius: baseWidth * 0.1)
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: CoreColors.copperBase)
        material.metallic = .init(floatLiteral: 0.88)
        material.roughness = .init(floatLiteral: 0.32)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "Coil"

        // Position on top of ring.
        let radial = SIMD3<Float>(cos(angle), 0, sin(angle))
        entity.position = radial * (radius + tubeRadius * 0.55) + SIMD3<Float>(0, tubeRadius * 0.25, 0)
        entity.transform.rotation = simd_quatf(angle: angle, axis: [0, 1, 0])

        return entity
    }

    // MARK: - Materials

    private static func ringBodyMaterial(roughness: Float) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        // Brushed palladium/steel color.
        material.baseColor = .init(tint: UIColor(red: 0.58, green: 0.64, blue: 0.68, alpha: 1.0))
        material.metallic = .init(floatLiteral: 0.94)
        material.roughness = .init(floatLiteral: max(0.08, min(0.6, roughness)))
        return material
    }

    private static func grooveMaterial(roughness: Float) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        // Darker machined groove.
        material.baseColor = .init(tint: UIColor(red: 0.15, green: 0.18, blue: 0.22, alpha: 1.0))
        material.metallic = .init(floatLiteral: 0.96)
        material.roughness = .init(floatLiteral: max(0.05, min(0.35, roughness)))
        return material
    }

    // MARK: - Material Updates

    private func updateRingMaterials(roughness: Float) {
        for ring in rings {
            ring.body.model?.materials = [Self.ringBodyMaterial(roughness: roughness)]
            ring.innerGroove.model?.materials = [Self.grooveMaterial(roughness: max(0.10, roughness - 0.15))]
            ring.outerGroove.model?.materials = [Self.grooveMaterial(roughness: max(0.10, roughness - 0.15))]
            for segment in ring.segments {
                segment.model?.materials = [Self.grooveMaterial(roughness: max(0.12, roughness - 0.10))]
            }
        }
    }

    private func updateCoilGlow(interpolator: StateInterpolator, pulse: MultiFrequencyPulse.PulseValues) {
        let baseIntensity = interpolator.coilGlowIntensity
        let pulsed = clamp01(baseIntensity * (1.0 + pulse.primary * 0.6 + pulse.fast * 0.25))

        // Blend copper toward orange glow.
        let glowStrength = pulsed * 0.4
        let baseColor = CoreColors.copperBase
        let glowColor = CoreColors.blend(baseColor, CoreColors.coilGlow, t: glowStrength)

        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: glowColor)
        material.metallic = .init(floatLiteral: 0.88)
        material.roughness = .init(floatLiteral: lerp(0.35, 0.22, pulsed))
        // Add emissive glow at higher adherence.
        if pulsed > 0.3 {
            material.emissiveColor = .init(color: CoreColors.withAlpha(CoreColors.coilGlow, pulsed * 0.5))
            material.emissiveIntensity = pulsed * 0.6
        }

        for coil in coilEntities {
            coil.model?.materials = [material]
        }
    }

    // MARK: - Utilities

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * clamp01(t)
    }

    private func clamp01(_ x: Float) -> Float {
        max(0, min(1, x))
    }
}
