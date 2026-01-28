import RealityKit
import UIKit
import simd

/// A system that manages ambient floating motes (dust-like particles) around the orb.
///
/// Motes create a sense of magical atmosphere even when wisps are few.
/// They drift slowly with slight turbulence, fading in and out over time.
@MainActor
final class AmbientMoteSystem {
    // Shared mesh resource for all motes
    private static var sharedMesh: MeshResource?

    private static func getSharedMesh(radius: Float) -> MeshResource {
        if let mesh = sharedMesh {
            return mesh
        }
        let mesh = MeshResource.generateSphere(radius: radius)
        sharedMesh = mesh
        return mesh
    }

    /// Container entity for all motes
    let containerEntity: Entity

    /// Active motes
    private var motes: [Mote] = []

    /// Object pool of inactive motes for reuse
    private var motePool: [Mote] = []

    /// Maximum motes (absolute cap)
    private let maxMotes: Int = 40

    /// Current target mote count
    private var targetMoteCount: Int = 8

    /// Timing for mote spawn
    private var lastSpawnTime: Float = 0
    private let spawnInterval: Float = 0.15

    /// Scene parameters
    private let unitScale: Float
    private let spawnRadius: Float

    /// Current palette for spawning motes
    private var currentPalette: [UIColor] = WispColors.palette(for: 0)

    // MARK: - Mote

    /// A single ambient mote.
    private class Mote {
        let entity: ModelEntity
        var position: SIMD3<Float>
        var velocity: SIMD3<Float>
        var lifetime: Float = 0
        var maxLifetime: Float
        var noiseOffset: SIMD3<Float>
        var cachedMaterial: UnlitMaterial
        var lastOpacityStep: Int = -1

        init(
            entity: ModelEntity,
            position: SIMD3<Float>,
            velocity: SIMD3<Float>,
            maxLifetime: Float,
            noiseOffset: SIMD3<Float>,
            material: UnlitMaterial
        ) {
            self.entity = entity
            self.position = position
            self.velocity = velocity
            self.maxLifetime = maxLifetime
            self.noiseOffset = noiseOffset
            self.cachedMaterial = material
        }

        var isExpired: Bool { lifetime >= maxLifetime }

        /// Progress through lifetime (0 to 1)
        var progress: Float { lifetime / maxLifetime }

        /// Opacity based on fade in/out
        var opacity: Float {
            // Fade in first 20%, fade out last 20%
            let fadeInEnd: Float = 0.2
            let fadeOutStart: Float = 0.8

            if progress < fadeInEnd {
                return progress / fadeInEnd
            } else if progress > fadeOutStart {
                return 1.0 - (progress - fadeOutStart) / (1.0 - fadeOutStart)
            } else {
                return 1.0
            }
        }

        func reset(
            position: SIMD3<Float>,
            velocity: SIMD3<Float>,
            maxLifetime: Float,
            noiseOffset: SIMD3<Float>,
            color: UIColor
        ) {
            self.position = position
            self.velocity = velocity
            self.lifetime = 0
            self.maxLifetime = maxLifetime
            self.noiseOffset = noiseOffset
            self.lastOpacityStep = -1

            // Reset material color
            cachedMaterial.color = .init(tint: color.withAlphaComponent(0.01))
            cachedMaterial.blending = .transparent(opacity: 0.01)
            entity.model?.materials = [cachedMaterial]
            entity.position = position
            entity.scale = SIMD3<Float>(repeating: 0.01)
        }
    }

    // MARK: - Initialization

    init(unitScale: Float) {
        self.unitScale = unitScale
        self.spawnRadius = 0.5 * unitScale // Slightly larger than wisp orbit radius

        containerEntity = Entity()
        containerEntity.name = "AmbientMotes"
    }

    // MARK: - Update

    /// Updates the mote system.
    ///
    /// - Parameters:
    ///   - deltaTime: Frame delta time
    ///   - targetCount: Target mote count from StateInterpolator
    ///   - brightness: Mote brightness from StateInterpolator
    ///   - palette: Current color palette
    ///   - time: Accumulated time for noise animation
    func update(
        deltaTime: Float,
        targetCount: Int,
        brightness: Float,
        palette: [UIColor],
        time: Float
    ) {
        targetMoteCount = min(targetCount, maxMotes)
        currentPalette = palette

        // Update spawn timing
        lastSpawnTime += deltaTime

        // Spawn new motes if needed
        if motes.count < targetMoteCount && lastSpawnTime >= spawnInterval {
            lastSpawnTime = 0
            spawnMote()
        }

        // Update existing motes
        for mote in motes {
            updateMote(mote, deltaTime: deltaTime, brightness: brightness, time: time)
        }

        // Remove expired motes and return to pool
        motes.removeAll { mote in
            if mote.isExpired {
                mote.entity.removeFromParent()
                motePool.append(mote)
                return true
            }
            return false
        }

        // If we have too many motes, let them expire naturally (don't force remove)
    }

    private func updateMote(_ mote: Mote, deltaTime: Float, brightness: Float, time: Float) {
        mote.lifetime += deltaTime

        // Simple noise-based drift using sin waves at different frequencies
        let noiseTime = time + mote.noiseOffset.x
        let noiseX = sin(noiseTime * 0.5 + mote.noiseOffset.y) * 0.02
        let noiseY = sin(noiseTime * 0.3 + mote.noiseOffset.z) * 0.015
        let noiseZ = cos(noiseTime * 0.4 + mote.noiseOffset.x) * 0.02

        let noise = SIMD3<Float>(noiseX, noiseY, noiseZ) * unitScale

        // Update position with base velocity plus noise
        mote.position += (mote.velocity + noise) * deltaTime
        mote.entity.position = mote.position

        // Calculate opacity (fade in/out + base brightness)
        let baseOpacity = mote.opacity * brightness
        let clampedOpacity = max(0.01, min(1.0, baseOpacity))

        // Throttle material updates
        let step = Int(clampedOpacity * 10)
        if step != mote.lastOpacityStep {
            mote.lastOpacityStep = step
            mote.cachedMaterial.blending = .transparent(opacity: .init(floatLiteral: clampedOpacity))
            mote.entity.model?.materials = [mote.cachedMaterial]
        }

        // Scale: slightly larger when fully visible
        let scale = 0.5 + mote.opacity * 0.5
        mote.entity.scale = SIMD3<Float>(repeating: scale)
    }

    private func spawnMote() {
        let mote: Mote

        if let pooledMote = motePool.popLast() {
            // Reuse from pool
            mote = pooledMote
            resetMote(mote)
            containerEntity.addChild(mote.entity)
        } else {
            // Create new mote
            mote = createNewMote()
            containerEntity.addChild(mote.entity)
        }

        motes.append(mote)
    }

    private func createNewMote() -> Mote {
        let radius: Float = 0.003 * unitScale
        let mesh = Self.getSharedMesh(radius: radius)

        let color = WispColors.randomColor(from: currentPalette)

        var material = UnlitMaterial()
        material.color = .init(tint: color.withAlphaComponent(0.01))
        material.blending = .transparent(opacity: 0.01)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "Mote"

        let (position, velocity, maxLifetime, noiseOffset) = randomMoteParams()

        entity.position = position
        entity.scale = SIMD3<Float>(repeating: 0.01)

        return Mote(
            entity: entity,
            position: position,
            velocity: velocity,
            maxLifetime: maxLifetime,
            noiseOffset: noiseOffset,
            material: material
        )
    }

    private func resetMote(_ mote: Mote) {
        let (position, velocity, maxLifetime, noiseOffset) = randomMoteParams()
        let color = WispColors.randomColor(from: currentPalette)

        mote.reset(
            position: position,
            velocity: velocity,
            maxLifetime: maxLifetime,
            noiseOffset: noiseOffset,
            color: color
        )
    }

    private func randomMoteParams() -> (position: SIMD3<Float>, velocity: SIMD3<Float>, maxLifetime: Float, noiseOffset: SIMD3<Float>) {
        // Random position within spawn sphere
        let theta = Float.random(in: 0...(2 * .pi))
        let phi = Float.random(in: -Float.pi/2...Float.pi/2)
        let r = Float.random(in: 0.3...1.0) * spawnRadius

        let position = SIMD3<Float>(
            r * cos(phi) * cos(theta),
            r * sin(phi),
            r * cos(phi) * sin(theta)
        )

        // Slow drift velocity (mostly upward with some random horizontal)
        let velocity = SIMD3<Float>(
            Float.random(in: -0.005...0.005) * unitScale,
            Float.random(in: 0.002...0.008) * unitScale,  // Upward drift
            Float.random(in: -0.005...0.005) * unitScale
        )

        let maxLifetime = Float.random(in: 3.0...6.0)

        // Random offset for noise function
        let noiseOffset = SIMD3<Float>(
            Float.random(in: 0...100),
            Float.random(in: 0...100),
            Float.random(in: 0...100)
        )

        return (position, velocity, maxLifetime, noiseOffset)
    }

    /// Removes all motes (for cleanup or reduced motion mode).
    func removeAllMotes() {
        for mote in motes {
            mote.entity.removeFromParent()
            motePool.append(mote)
        }
        motes.removeAll()
    }
}
