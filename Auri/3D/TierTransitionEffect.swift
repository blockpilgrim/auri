import RealityKit
import UIKit
import simd

/// Visual effect that plays when crossing tier thresholds (upgrades only).
///
/// Creates an expanding ring effect with a sparkle burst to celebrate
/// positive tier transitions.
@MainActor
final class TierTransitionEffect {
    /// Container entity for the effect
    let containerEntity: Entity

    /// The expanding ring entity
    private var ringEntity: ModelEntity?
    private var ringMaterial: UnlitMaterial?

    /// Animation state
    private var isAnimating: Bool = false
    private var animationProgress: Float = 0
    private let animationDuration: Float = 0.6

    /// Ring parameters
    private let unitScale: Float
    private var targetColor: UIColor = SparkColors.gold

    // MARK: - Initialization

    init(unitScale: Float) {
        self.unitScale = unitScale
        self.containerEntity = Entity()
        containerEntity.name = "TierTransitionEffect"
    }

    // MARK: - Trigger

    /// Triggers the tier transition effect.
    ///
    /// - Parameters:
    ///   - fromTier: The previous tier
    ///   - toTier: The new tier
    ///   - isUpgrade: Whether this is an upgrade (only upgrades trigger effect)
    ///   - palette: Current color palette for the effect
    func trigger(isUpgrade: Bool, palette: [UIColor]) {
        // Only animate upgrades (per emotional design: avoid punishment visuals)
        guard isUpgrade else { return }

        // Don't interrupt existing animation
        guard !isAnimating else { return }

        isAnimating = true
        animationProgress = 0

        // Choose a warm color for the ring
        targetColor = palette.first { color in
            // Prefer gold/pink/white for celebration
            color == SparkColors.gold || color == SparkColors.pink || color == SparkColors.white
        } ?? SparkColors.gold

        // Create the ring entity
        createRing()
    }

    private func createRing() {
        // Use a torus mesh for the ring
        let torusMesh = MeshResource.generateTorus(
            meanRadius: 0.1 * unitScale,
            tubeRadius: 0.008 * unitScale
        )

        var material = UnlitMaterial()
        material.color = .init(tint: targetColor.withAlphaComponent(0.6))
        material.blending = .transparent(opacity: 0.6)

        let entity = ModelEntity(mesh: torusMesh, materials: [material])
        entity.name = "TransitionRing"
        entity.scale = SIMD3<Float>(repeating: 1.0)

        containerEntity.addChild(entity)
        ringEntity = entity
        ringMaterial = material
    }

    // MARK: - Update

    /// Updates the effect animation.
    ///
    /// - Parameter deltaTime: Frame delta time
    /// - Returns: True if effect triggered a sparkle burst this frame
    func update(deltaTime: Float) -> Bool {
        guard isAnimating else { return false }

        animationProgress += deltaTime / animationDuration

        if animationProgress >= 1.0 {
            // Animation complete
            isAnimating = false
            ringEntity?.removeFromParent()
            ringEntity = nil
            ringMaterial = nil
            return false
        }

        // Ease-out curve for smooth expansion
        let t = 1.0 - pow(1.0 - animationProgress, 2.0)

        // Expand the ring
        let scale = 1.0 + t * 3.0 // Expand to 4x original size
        ringEntity?.scale = SIMD3<Float>(repeating: scale)

        // Fade out opacity
        let opacity = (1.0 - t) * 0.6
        if var material = ringMaterial {
            material.blending = .transparent(opacity: .init(floatLiteral: max(0.01, opacity)))
            ringEntity?.model?.materials = [material]
            ringMaterial = material
        }

        // Return true on first frame to trigger sparkle burst
        return animationProgress < deltaTime / animationDuration + 0.01
    }

    /// Whether the effect is currently animating.
    var isActive: Bool { isAnimating }
}

// MARK: - Torus Mesh Extension

extension MeshResource {
    /// Generates a torus mesh.
    ///
    /// - Parameters:
    ///   - meanRadius: Distance from center to tube center
    ///   - tubeRadius: Radius of the tube
    ///   - segments: Number of segments around the main ring
    ///   - tubeSegments: Number of segments around the tube
    static func generateTorus(
        meanRadius: Float,
        tubeRadius: Float,
        segments: Int = 32,
        tubeSegments: Int = 16
    ) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []

        for i in 0...segments {
            let u = Float(i) / Float(segments)
            let theta = u * 2.0 * .pi

            let cosTheta = cos(theta)
            let sinTheta = sin(theta)

            for j in 0...tubeSegments {
                let v = Float(j) / Float(tubeSegments)
                let phi = v * 2.0 * .pi

                let cosPhi = cos(phi)
                let sinPhi = sin(phi)

                // Position on torus
                let x = (meanRadius + tubeRadius * cosPhi) * cosTheta
                let y = tubeRadius * sinPhi
                let z = (meanRadius + tubeRadius * cosPhi) * sinTheta

                positions.append(SIMD3<Float>(x, y, z))

                // Normal (points outward from tube center)
                let nx = cosPhi * cosTheta
                let ny = sinPhi
                let nz = cosPhi * sinTheta
                normals.append(SIMD3<Float>(nx, ny, nz))

                // UV coordinates
                uvs.append(SIMD2<Float>(u, v))
            }
        }

        // Generate indices
        for i in 0..<segments {
            for j in 0..<tubeSegments {
                let a = UInt32(i * (tubeSegments + 1) + j)
                let b = UInt32((i + 1) * (tubeSegments + 1) + j)
                let c = UInt32((i + 1) * (tubeSegments + 1) + j + 1)
                let d = UInt32(i * (tubeSegments + 1) + j + 1)

                // Two triangles per quad
                indices.append(contentsOf: [a, b, c])
                indices.append(contentsOf: [a, c, d])
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
