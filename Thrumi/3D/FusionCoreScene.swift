import RealityKit
import UIKit
import simd

@MainActor
final class FusionCoreScene {
    static let unitScale: Float = 0.05

    let rootEntity: Entity
    let particleManager: ParticleEffectsManager

    private let glowLayers: CoreGlowLayers
    private let coreLight: Entity
    private let coilLight: Entity

    private struct RingSpec {
        let innerRadius: Float
        let outerRadius: Float
        let direction: Float
        let speedMultiplier: Float
        let hasCoils: Bool
        let coilCount: Int
        let yOffset: Float
    }

    private struct RingNode {
        let entity: Entity
        let body: ModelEntity
        let detail: [ModelEntity]
        let coilGlows: [ModelEntity]
        let direction: Float
        let speedMultiplier: Float
    }

    private static let rings: [RingSpec] = [
        RingSpec(innerRadius: 0.55, outerRadius: 0.70, direction: 1, speedMultiplier: 1.00, hasCoils: true, coilCount: 8, yOffset: 0.000),
        RingSpec(innerRadius: 0.80, outerRadius: 0.95, direction: -1, speedMultiplier: 0.82, hasCoils: false, coilCount: 0, yOffset: 0.002),
        RingSpec(innerRadius: 1.05, outerRadius: 1.25, direction: 1, speedMultiplier: 0.68, hasCoils: true, coilCount: 12, yOffset: -0.002),
        RingSpec(innerRadius: 1.35, outerRadius: 1.50, direction: -1, speedMultiplier: 0.54, hasCoils: false, coilCount: 0, yOffset: 0.004),
        RingSpec(innerRadius: 1.60, outerRadius: 1.80, direction: 1, speedMultiplier: 0.40, hasCoils: false, coilCount: 0, yOffset: -0.004),
    ]

    private var ringNodes: [RingNode]
    private var coilGlowEntities: [ModelEntity]
    private var lastRingRoughness: Float = -1

    private init(
        rootEntity: Entity,
        glowLayers: CoreGlowLayers,
        ringNodes: [RingNode],
        coilGlowEntities: [ModelEntity],
        particleManager: ParticleEffectsManager,
        coreLight: Entity,
        coilLight: Entity
    ) {
        self.rootEntity = rootEntity
        self.glowLayers = glowLayers
        self.ringNodes = ringNodes
        self.coilGlowEntities = coilGlowEntities
        self.particleManager = particleManager
        self.coreLight = coreLight
        self.coilLight = coilLight
    }

    static func create() async -> FusionCoreScene {
        let root = Entity()
        root.name = "FusionCore"

        // Hero scale for UI presentation (RealityKit units are meters).
        // Tuned so the spinner reads large and central in the HUD.
        root.scale = SIMD3<Float>(repeating: 4.5)

        // Place the spinner in front of the default camera.
        // RealityKit units are meters; bring the scene closer so it reads at "hero" size.
        root.position = [0, -0.05, -0.25]
        // Simulate a fixed camera pitched down ~65° by pitching the scene up.
        let pitch: Float = 65.0 * .pi / 180.0
        root.transform.rotation = simd_quatf(angle: pitch, axis: [1, 0, 0])

        let glow = CoreGlowLayers.create(unitScale: unitScale)
        root.addChild(glow.container)

        var nodes: [RingNode] = []
        var coilGlows: [ModelEntity] = []

        for (index, spec) in rings.enumerated() {
            let ring = createRing(spec: spec, unitScale: unitScale, name: "Ring\(index + 1)")
            nodes.append(ring)
            coilGlows.append(contentsOf: ring.coilGlows)
            root.addChild(ring.entity)
        }

        let coreLight = createPointLight(
            name: "CoreLight",
            color: CoreColors.coreTeal,
            baseLumens: 1500,
            attenuationRadius: 0.60,
            position: [0, 0, 0]
        )

        let coilLight = createPointLight(
            name: "CoilLight",
            color: CoreColors.coilGlow,
            baseLumens: 900,
            attenuationRadius: 0.40,
            position: [0, 0, 0]
        )

        root.addChild(coreLight)
        root.addChild(coilLight)
        root.addChild(createDirectionalFillLight())

        let meanRadii = rings.map { (($0.innerRadius + $0.outerRadius) * 0.5) * unitScale }
        let particles = ParticleEffectsManager(ringRadii: meanRadii)
        root.addChild(particles.container)

        return FusionCoreScene(
            rootEntity: root,
            glowLayers: glow,
            ringNodes: nodes,
            coilGlowEntities: coilGlows,
            particleManager: particles,
            coreLight: coreLight,
            coilLight: coilLight
        )
    }

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
        glowLayers.update(
            interpolator: interpolator,
            pulse: pulse,
            deltaTime: deltaTime,
            bloomMultiplier: bloomMultiplier
        )

        updateRingTransforms(spinAngle: spinAngle)
        updateRingMaterialsIfNeeded(interpolator: interpolator)
        updateCoilGlow(interpolator: interpolator, pulse: pulse)
        updateLights(interpolator: interpolator, pulse: pulse)

        particleManager.update(
            interpolator: interpolator,
            deltaTime: deltaTime,
            currentTime: currentTime,
            thermalParticleMultiplier: thermalParticleMultiplier,
            showParticles: showParticles
        )
    }

    private func updateRingTransforms(spinAngle: Float) {
        for ring in ringNodes {
            let angle = spinAngle * ring.speedMultiplier * ring.direction
            ring.entity.transform.rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
        }
    }

    private func updateRingMaterialsIfNeeded(interpolator: StateInterpolator) {
        let roughness = interpolator.ringRoughness
        guard abs(roughness - lastRingRoughness) > 0.002 else { return }
        lastRingRoughness = roughness

        for ring in ringNodes {
            ring.body.model?.materials = [makeRingBodyMaterial(roughness: roughness)]
            for detail in ring.detail {
                detail.model?.materials = [makeRingDetailMaterial(roughness: max(0.12, roughness - 0.10))]
            }
        }
    }

    private func updateCoilGlow(interpolator: StateInterpolator, pulse: MultiFrequencyPulse.PulseValues) {
        let base = interpolator.coilGlowIntensity
        let pulsed = clamp01(base * (1.0 + pulse.primary * 0.8 + pulse.fast * 0.35 + pulse.ultraFast * 0.25))
        let alpha = clamp01(0.15 + pulsed * 0.85)

        var glowMaterial = UnlitMaterial()
        glowMaterial.color = .init(tint: CoreColors.withAlpha(CoreColors.coilGlow, alpha))
        glowMaterial.blending = .transparent(opacity: .init(floatLiteral: alpha))

        for glow in coilGlowEntities {
            glow.model?.materials = [glowMaterial]
        }
    }

    private func updateLights(interpolator: StateInterpolator, pulse: MultiFrequencyPulse.PulseValues) {
        let lightPulse = 1.0 + pulse.primary * 0.5

        if var core = coreLight.components[PointLightComponent.self] {
            core.intensity = 1500 * interpolator.coreLightIntensity * lightPulse
            core.attenuationRadius = lerp(0.30, 0.70, interpolator.adherence)
            coreLight.components.set(core)
        }

        if var coil = coilLight.components[PointLightComponent.self] {
            coil.intensity = 900 * interpolator.coilLightIntensity * (1.0 + pulse.fast * 0.35)
            coil.attenuationRadius = lerp(0.22, 0.50, interpolator.adherence)
            coilLight.components.set(coil)
        }
    }

    private static func createRing(spec: RingSpec, unitScale: Float, name: String) -> RingNode {
        let group = Entity()
        group.name = name

        let midRadius = ((spec.innerRadius + spec.outerRadius) * 0.5) * unitScale
        let tubeRadius = ((spec.outerRadius - spec.innerRadius) * 0.5) * unitScale

        let bodyMesh = MeshResource.generateTorus(meanRadius: midRadius, tubeRadius: tubeRadius, segments: 96, tubeSegments: 18)
        let body = ModelEntity(mesh: bodyMesh, materials: [makeRingBodyMaterial(roughness: 0.35)])
        body.name = "Body"
        group.addChild(body)

        // Machined details (groove bands)
        let grooveA = ModelEntity(
            mesh: MeshResource.generateTorus(meanRadius: midRadius - tubeRadius * 0.25, tubeRadius: max(0.0005, tubeRadius * 0.18), segments: 80, tubeSegments: 14),
            materials: [makeRingDetailMaterial(roughness: 0.22)]
        )
        grooveA.name = "GrooveA"
        group.addChild(grooveA)

        let grooveB = ModelEntity(
            mesh: MeshResource.generateTorus(meanRadius: midRadius + tubeRadius * 0.28, tubeRadius: max(0.0005, tubeRadius * 0.14), segments: 80, tubeSegments: 14),
            materials: [makeRingDetailMaterial(roughness: 0.22)]
        )
        grooveB.name = "GrooveB"
        group.addChild(grooveB)

        group.position.y = spec.yOffset

        var coilGlows: [ModelEntity] = []
        if spec.hasCoils {
            let coilGroup = createCoils(radius: midRadius, tubeRadius: tubeRadius, count: spec.coilCount)
            group.addChild(coilGroup.group)
            coilGlows = coilGroup.glowStrips
        }

        return RingNode(
            entity: group,
            body: body,
            detail: [grooveA, grooveB],
            coilGlows: coilGlows,
            direction: spec.direction,
            speedMultiplier: spec.speedMultiplier
        )
    }

    private static func createCoils(radius: Float, tubeRadius: Float, count: Int) -> (group: Entity, glowStrips: [ModelEntity]) {
        let group = Entity()
        group.name = "Coils"

        let baseW = max(0.002, tubeRadius * 1.10)
        let baseH = max(0.0015, tubeRadius * 0.60)
        let baseD = max(0.002, tubeRadius * 0.90)

        let glowW = baseW * 0.80
        let glowH = baseH * 0.55
        let glowD = baseD * 0.65

        let baseMesh = MeshResource.generateBox(width: baseW, height: baseH, depth: baseD)
        let glowMesh = MeshResource.generateBox(width: glowW, height: glowH, depth: glowD)

        var baseMaterial = PhysicallyBasedMaterial()
        baseMaterial.baseColor = .init(tint: CoreColors.copperBase)
        baseMaterial.metallic = .init(floatLiteral: 0.85)
        baseMaterial.roughness = .init(floatLiteral: 0.35)

        var glowMaterial = UnlitMaterial()
        glowMaterial.color = .init(tint: CoreColors.withAlpha(CoreColors.coilGlow, 0.25))
        glowMaterial.blending = .transparent(opacity: 0.25)

        var glows: [ModelEntity] = []

        for i in 0..<max(1, count) {
            let angle = Float(i) / Float(max(1, count)) * 2 * .pi
            let radial = SIMD3<Float>(cos(angle), 0, sin(angle))

            let base = ModelEntity(mesh: baseMesh, materials: [baseMaterial])
            base.name = "CoilBase"
            base.position = radial * (radius + tubeRadius * 0.55) + SIMD3<Float>(0, tubeRadius * 0.18, 0)
            base.transform.rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
            group.addChild(base)

            let glow = ModelEntity(mesh: glowMesh, materials: [glowMaterial])
            glow.name = "CoilGlow"
            glow.position = base.position
            glow.transform.rotation = base.transform.rotation
            group.addChild(glow)
            glows.append(glow)
        }

        return (group: group, glowStrips: glows)
    }

    private static func createPointLight(
        name: String,
        color: UIColor,
        baseLumens: Float,
        attenuationRadius: Float,
        position: SIMD3<Float>
    ) -> Entity {
        let lightEntity = Entity()
        lightEntity.name = name
        lightEntity.position = position

        var light = PointLightComponent()
        light.color = .init(cgColor: color.cgColor)
        light.intensity = baseLumens
        light.attenuationRadius = attenuationRadius
        lightEntity.components.set(light)

        return lightEntity
    }

    private static func createDirectionalFillLight() -> Entity {
        let lightEntity = Entity()
        lightEntity.name = "FillLight"

        var light = DirectionalLightComponent()
        light.color = .init(white: 0.95, alpha: 1.0)
        light.intensity = 650
        lightEntity.components.set(light)

        lightEntity.transform.rotation = simd_quatf(angle: -.pi / 3.2, axis: [1, 0, 0]) * simd_quatf(angle: .pi / 8, axis: [0, 1, 0])
        return lightEntity
    }

    private static func makeRingBodyMaterial(roughness: Float) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(red: 0.54, green: 0.61, blue: 0.66, alpha: 1.0))
        material.metallic = .init(floatLiteral: 0.92)
        material.roughness = .init(floatLiteral: max(0.05, min(1, roughness)))
        return material
    }

    private static func makeRingDetailMaterial(roughness: Float) -> PhysicallyBasedMaterial {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: UIColor(red: 0.18, green: 0.22, blue: 0.28, alpha: 1.0))
        material.metallic = .init(floatLiteral: 0.95)
        material.roughness = .init(floatLiteral: max(0.05, min(1, roughness)))
        return material
    }

    private func makeRingBodyMaterial(roughness: Float) -> PhysicallyBasedMaterial {
        Self.makeRingBodyMaterial(roughness: roughness)
    }

    private func makeRingDetailMaterial(roughness: Float) -> PhysicallyBasedMaterial {
        Self.makeRingDetailMaterial(roughness: roughness)
    }

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * clamp01(t)
    }

    private func clamp01(_ x: Float) -> Float {
        max(0, min(1, x))
    }
}

// MARK: - Mesh

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
