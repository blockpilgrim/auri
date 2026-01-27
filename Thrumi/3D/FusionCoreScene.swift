import Foundation
import RealityKit
import simd
import UIKit

/// Manages the Fusion Core 3D scene, including entity creation and material control.
@MainActor
final class FusionCoreScene {
    let rootEntity: Entity
    let outerRing: Entity
    let middleRing: Entity
    let innerRing: Entity
    let coilAssembly: Entity
    let centerCore: Entity

    // Point light for center glow
    private let centerLight: Entity

    // Store material references for runtime updates
    private var ringMaterials: [CoreComponent: PhysicallyBasedMaterial] = [:]
    private var emissiveMaterials: [CoreComponent: UnlitMaterial] = [:]

    private init(
        rootEntity: Entity,
        outerRing: Entity,
        middleRing: Entity,
        innerRing: Entity,
        coilAssembly: Entity,
        centerCore: Entity,
        centerLight: Entity
    ) {
        self.rootEntity = rootEntity
        self.outerRing = outerRing
        self.middleRing = middleRing
        self.innerRing = innerRing
        self.coilAssembly = coilAssembly
        self.centerCore = centerCore
        self.centerLight = centerLight
    }

    /// Creates and loads the Fusion Core scene with procedurally generated geometry.
    static func create() async -> FusionCoreScene {
        let root = Entity()
        root.name = "FusionCore"

        // Create the three concentric rings with industrial metallic look
        let outer = createRing(
            name: "OuterRing",
            majorRadius: 0.12,
            minorRadius: 0.012,
            color: .init(red: 0.75, green: 0.75, blue: 0.78, alpha: 1.0), // Palladium/steel
            metallic: 0.95,
            roughness: 0.25
        )

        let middle = createRing(
            name: "MiddleRing",
            majorRadius: 0.085,
            minorRadius: 0.010,
            color: .init(red: 0.72, green: 0.72, blue: 0.76, alpha: 1.0), // Brushed steel
            metallic: 0.92,
            roughness: 0.30
        )

        let inner = createRing(
            name: "InnerRing",
            majorRadius: 0.055,
            minorRadius: 0.008,
            color: .init(red: 0.78, green: 0.78, blue: 0.82, alpha: 1.0), // Polished steel
            metallic: 0.98,
            roughness: 0.15
        )

        // Create coil assembly (copper-colored emissive segments)
        let coils = createCoilAssembly()

        // Create glowing center core
        let center = createCenterCore()

        // Create point light for center glow effect
        let light = createCenterLight()

        // Parent all components to root
        root.addChild(outer)
        root.addChild(middle)
        root.addChild(inner)
        root.addChild(coils)
        root.addChild(center)
        root.addChild(light)

        // Slight tilt for visual interest (magnetic levitation aesthetic)
        outer.transform.rotation = simd_quatf(angle: .pi * 0.02, axis: [1, 0, 0])
        middle.transform.rotation = simd_quatf(angle: -.pi * 0.015, axis: [0, 0, 1])

        return FusionCoreScene(
            rootEntity: root,
            outerRing: outer,
            middleRing: middle,
            innerRing: inner,
            coilAssembly: coils,
            centerCore: center,
            centerLight: light
        )
    }

    // MARK: - Geometry Creation

    private static func createRing(
        name: String,
        majorRadius: Float,
        minorRadius: Float,
        color: UIColor,
        metallic: Float,
        roughness: Float
    ) -> Entity {
        // Create torus mesh for ring
        let mesh = MeshResource.generateTorus(
            meanRadius: majorRadius,
            tubeRadius: minorRadius
        )

        // Industrial metallic PBR material
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: color)
        material.metallic = .init(floatLiteral: metallic)
        material.roughness = .init(floatLiteral: roughness)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = name

        return entity
    }

    private static func createCoilAssembly() -> Entity {
        let assembly = Entity()
        assembly.name = "CoilAssembly"

        // Create copper coil segments between rings
        let coilCount = 8
        let innerCoilRadius: Float = 0.068
        let outerCoilRadius: Float = 0.102

        for i in 0..<coilCount {
            let angle = Float(i) * (2 * .pi / Float(coilCount))

            // Inner coil segment
            let innerCoil = createCoilSegment(
                radius: innerCoilRadius,
                angle: angle,
                height: 0.015,
                intensity: 0.8
            )
            assembly.addChild(innerCoil)

            // Outer coil segment
            let outerCoil = createCoilSegment(
                radius: outerCoilRadius,
                angle: angle,
                height: 0.018,
                intensity: 0.6
            )
            assembly.addChild(outerCoil)
        }

        return assembly
    }

    private static func createCoilSegment(
        radius: Float,
        angle: Float,
        height: Float,
        intensity: Float
    ) -> Entity {
        let mesh = MeshResource.generateCylinder(height: height, radius: 0.004)

        // Copper emissive material (warm orange glow)
        var material = UnlitMaterial()
        let copperColor = UIColor(
            red: CGFloat(0.85 * intensity + 0.15),
            green: CGFloat(0.45 * intensity),
            blue: CGFloat(0.15 * intensity),
            alpha: 1.0
        )
        material.color = .init(tint: copperColor)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "Coil"

        // Position around the ring
        let x = radius * cos(angle)
        let z = radius * sin(angle)
        entity.position = [x, 0, z]

        return entity
    }

    private static func createCenterCore() -> Entity {
        let container = Entity()
        container.name = "CenterCore"

        // Outer translucent shell (ceramic/glass containment)
        let shellMesh = MeshResource.generateSphere(radius: 0.035)
        var shellMaterial = PhysicallyBasedMaterial()
        shellMaterial.baseColor = .init(tint: .init(white: 0.9, alpha: 0.3))
        shellMaterial.metallic = .init(floatLiteral: 0.1)
        shellMaterial.roughness = .init(floatLiteral: 0.05)
        shellMaterial.blending = .transparent(opacity: 0.3)

        let shell = ModelEntity(mesh: shellMesh, materials: [shellMaterial])
        shell.name = "CenterShell"

        // Inner energy core (emissive glow)
        let coreMesh = MeshResource.generateSphere(radius: 0.022)
        var coreMaterial = UnlitMaterial()
        // Electric blue-white glow
        coreMaterial.color = .init(tint: .init(red: 0.6, green: 0.85, blue: 1.0, alpha: 1.0))

        let core = ModelEntity(mesh: coreMesh, materials: [coreMaterial])
        core.name = "EnergyCore"

        container.addChild(shell)
        container.addChild(core)

        return container
    }

    private static func createCenterLight() -> Entity {
        let light = Entity()
        light.name = "CenterLight"

        // Point light component for glow effect
        var pointLight = PointLightComponent()
        pointLight.color = .init(red: 0.6, green: 0.85, blue: 1.0, alpha: 1.0)
        pointLight.intensity = 800
        pointLight.attenuationRadius = 0.3

        light.components.set(pointLight)

        return light
    }

    // MARK: - Material Control

    /// Sets the emissive intensity for the specified component.
    /// - Parameters:
    ///   - intensity: Intensity value from 0.0 (dim) to 1.0 (bright)
    ///   - component: The core component to modify
    func setEmissiveIntensity(_ intensity: Float, for component: CoreComponent) {
        switch component {
        case .center:
            updateCenterGlow(intensity: intensity)
        case .coils:
            updateCoilGlow(intensity: intensity)
        default:
            break
        }
    }

    /// Sets the metallic roughness for ring components.
    /// - Parameters:
    ///   - roughness: Roughness value from 0.0 (mirror) to 1.0 (matte)
    ///   - component: The core component to modify
    func setMetallicRoughness(_ roughness: Float, for component: CoreComponent) {
        guard let modelEntity = entityFor(component) as? ModelEntity else { return }
        guard var material = modelEntity.model?.materials.first as? PhysicallyBasedMaterial else { return }

        material.roughness = .init(floatLiteral: roughness)
        modelEntity.model?.materials = [material]
    }

    /// Updates the center light intensity.
    func setLightIntensity(_ intensity: Float) {
        guard var light = centerLight.components[PointLightComponent.self] else { return }
        light.intensity = intensity * 1200
        centerLight.components.set(light)
    }

    private func updateCenterGlow(intensity: Float) {
        guard let coreEntity = centerCore.findEntity(named: "EnergyCore") as? ModelEntity else { return }

        var material = UnlitMaterial()
        // Scale color brightness with intensity
        let r = 0.4 + (0.6 * intensity)
        let g = 0.7 + (0.3 * intensity)
        let b = 0.9 + (0.1 * intensity)
        material.color = .init(tint: .init(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0))

        coreEntity.model?.materials = [material]
    }

    private func updateCoilGlow(intensity: Float) {
        for child in coilAssembly.children {
            guard let modelEntity = child as? ModelEntity else { continue }

            var material = UnlitMaterial()
            // Copper glow scales with intensity
            let r = 0.3 + (0.7 * intensity)
            let g = 0.15 + (0.35 * intensity)
            let b = 0.05 + (0.15 * intensity)
            material.color = .init(tint: .init(red: CGFloat(r), green: CGFloat(g), blue: CGFloat(b), alpha: 1.0))

            modelEntity.model?.materials = [material]
        }
    }

    private func entityFor(_ component: CoreComponent) -> Entity? {
        switch component {
        case .outerRing: outerRing
        case .middleRing: middleRing
        case .innerRing: innerRing
        case .coils: coilAssembly
        case .center: centerCore
        }
    }
}

// MARK: - MeshResource Extensions

extension MeshResource {
    /// Generates a torus mesh (ring shape).
    static func generateTorus(meanRadius: Float, tubeRadius: Float, segments: Int = 48, tubeSegments: Int = 24) -> MeshResource {
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

                // Position on torus surface
                let x = (meanRadius + tubeRadius * cosPhi) * cosTheta
                let y = tubeRadius * sinPhi
                let z = (meanRadius + tubeRadius * cosPhi) * sinTheta

                positions.append([x, y, z])

                // Normal pointing outward from tube center
                let nx = cosPhi * cosTheta
                let ny = sinPhi
                let nz = cosPhi * sinTheta
                normals.append(normalize([nx, ny, nz]))

                uvs.append([u, v])
            }
        }

        // Generate triangle indices
        let tubeVertexCount = tubeSegments + 1
        for i in 0..<segments {
            for j in 0..<tubeSegments {
                let current = UInt32(i * tubeVertexCount + j)
                let next = UInt32((i + 1) * tubeVertexCount + j)

                // Two triangles per quad
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
