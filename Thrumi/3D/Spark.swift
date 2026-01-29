import RealityKit
import UIKit
import simd

/// A single spark entity that orbits within your Auri.
///
/// Sparks are small luminous particles representing your cellular light (biophotons).
/// They orbit on individual tilted orbital planes using UnlitMaterial for
/// bright, saturated cel-shaded appearance.
@MainActor
final class Spark {
    // Shared mesh resource to avoid creating new meshes for each spark
    private static var sharedMesh: MeshResource?

    private static func getSharedMesh(radius: Float) -> MeshResource {
        if let mesh = sharedMesh {
            return mesh
        }
        let mesh = MeshResource.generateSphere(radius: radius)
        sharedMesh = mesh
        return mesh
    }

    let entity: ModelEntity

    // MARK: - Orbital Parameters

    /// Distance from center
    let orbitRadius: Float

    /// Individual speed multiplier (for organic variation)
    let speedMultiplier: Float

    /// Starting angle on orbit
    var orbitPhase: Float

    /// Tilted orbital plane quaternion
    let orbitTilt: simd_quatf

    // MARK: - Visual Parameters

    let baseColor: UIColor
    var brightness: Float
    let baseScale: Float

    // MARK: - Animation State

    private var breathingPhase: Float
    private var accumulatedOrbitAngle: Float = 0
    private var currentAngle: Float = 0

    // MARK: - Interaction State

    /// Offset from orbital position (for scatter/attract effects)
    var positionOffset: SIMD3<Float> = .zero

    /// Velocity for position offset (decays over time)
    var offsetVelocity: SIMD3<Float> = .zero

    /// Target position for attraction (nil = return to orbit)
    var attractionTarget: SIMD3<Float>? = nil

    /// Excitement multiplier (1.0 = normal, higher = more energetic)
    var excitement: Float = 1.0

    /// Chaos factor (0 = normal orbit, 1 = fully chaotic)
    var chaosFactor: Float = 0

    /// Random chaos direction for this spark
    private var chaosDirection: SIMD3<Float> = .zero

    // MARK: - Fade State

    private(set) var isFadingIn: Bool = false
    private(set) var isFadingOut: Bool = false
    private(set) var isFullyFaded: Bool = false
    private var fadeProgress: Float = 0
    private var fadeDuration: Float = 0.5

    // MARK: - Material Cache

    private var cachedMaterial: UnlitMaterial
    private var lastOpacityStep: Int = -1

    // MARK: - Initialization

    private init(
        entity: ModelEntity,
        orbitRadius: Float,
        speedMultiplier: Float,
        orbitPhase: Float,
        orbitTilt: simd_quatf,
        baseColor: UIColor,
        brightness: Float,
        baseScale: Float,
        breathingPhase: Float,
        material: UnlitMaterial
    ) {
        self.entity = entity
        self.orbitRadius = orbitRadius
        self.speedMultiplier = speedMultiplier
        self.orbitPhase = orbitPhase
        self.orbitTilt = orbitTilt
        self.baseColor = baseColor
        self.brightness = brightness
        self.baseScale = baseScale
        self.breathingPhase = breathingPhase
        self.cachedMaterial = material
    }

    // MARK: - Factory

    /// Creates a new spark with randomized orbital parameters.
    ///
    /// - Parameters:
    ///   - color: The spark's base color (from SparkColors palette)
    ///   - orbitRadius: Base orbit radius (varied slightly for organic feel)
    ///   - brightness: Brightness multiplier based on adherence
    ///   - unitScale: Scene unit scale
    static func create(
        color: UIColor,
        orbitRadius: Float,
        brightness: Float,
        unitScale: Float
    ) -> Spark {
        // Use shared mesh for teardrop/flame shape (reuse across all sparks).
        let baseRadius: Float = 0.025 * unitScale
        let mesh = getSharedMesh(radius: baseRadius)

        // Bright UnlitMaterial - cel-shaded look.
        var material = UnlitMaterial()
        let tintColor = SparkColors.withAlpha(color, brightness)
        material.color = .init(tint: tintColor)
        material.blending = .transparent(opacity: .init(floatLiteral: brightness))

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "Spark"

        // Elongate slightly for teardrop shape.
        entity.scale = [1.0, 1.4, 1.0]

        // Randomized orbital parameters for organic feel.
        let radiusVariation = Float.random(in: 0.85...1.15)
        let speedVariation = Float.random(in: 0.8...1.2)
        let phase = Float.random(in: 0...(2 * .pi))
        let breathPhase = Float.random(in: 0...(2 * .pi))

        // Random orbital plane tilt (not all on same plane).
        let tiltX = Float.random(in: -0.5...0.5)
        let tiltZ = Float.random(in: -0.5...0.5)
        let tiltAxis = normalize(SIMD3<Float>(tiltX, 0.3, tiltZ))
        let tiltAngle = Float.random(in: 0.2...0.8)
        let orbitTilt = simd_quatf(angle: tiltAngle, axis: tiltAxis)

        // Base scale with slight variation.
        let scaleVariation = Float.random(in: 0.8...1.2)

        return Spark(
            entity: entity,
            orbitRadius: orbitRadius * radiusVariation,
            speedMultiplier: speedVariation,
            orbitPhase: phase,
            orbitTilt: orbitTilt,
            baseColor: color,
            brightness: brightness,
            baseScale: scaleVariation,
            breathingPhase: breathPhase,
            material: material
        )
    }

    // MARK: - Update

    /// Updates the spark's position and appearance.
    ///
    /// - Parameters:
    ///   - deltaTime: Frame delta time
    ///   - globalSpinAngle: Global spin angle from physics (flick response)
    ///   - baseOrbitSpeed: Base orbit speed from state interpolator
    ///   - breathingPulse: Breathing animation pulse value (-1 to 1)
    ///   - breathingAmplitude: Breathing scale amplitude
    ///   - orbitScale: Multiplier for orbit radius (for pinch gesture)
    func update(
        deltaTime: Float,
        globalSpinAngle: Float,
        baseOrbitSpeed: Float,
        breathingPulse: Float,
        breathingAmplitude: Float,
        orbitScale: Float = 1.0
    ) {
        // Update fade state.
        updateFade(deltaTime: deltaTime)

        guard !isFullyFaded else { return }

        // Update breathing phase (faster when excited).
        let breathingSpeed: Float = 0.5 * excitement
        breathingPhase += deltaTime * 2.0 * .pi * breathingSpeed
        if breathingPhase > 2 * .pi {
            breathingPhase -= 2 * .pi
        }

        // Decay excitement back to normal (approximation of pow(0.95, dt*60)).
        let excitementDecay = 1.0 - deltaTime * 3.0 // ~0.95^60 per second
        excitement = 1.0 + (excitement - 1.0) * max(0, excitementDecay)

        // Decay chaos factor.
        let chaosDecay = 1.0 - deltaTime * 1.8 // ~0.97^60 per second
        chaosFactor *= max(0, chaosDecay)
        if chaosFactor < 0.01 { chaosFactor = 0 }

        // Accumulate orbital angle internally (avoids jump when global angle wraps).
        let effectiveSpeed = baseOrbitSpeed * speedMultiplier * excitement
        accumulatedOrbitAngle += deltaTime * effectiveSpeed

        // Prevent precision loss over very long sessions (wrap at large value).
        if accumulatedOrbitAngle > 1000 * .pi {
            accumulatedOrbitAngle -= 1000 * .pi
        }

        // Calculate current orbital angle.
        // Combines internal accumulated angle with global spin from user interaction.
        currentAngle = orbitPhase + accumulatedOrbitAngle + globalSpinAngle * speedMultiplier

        // Calculate base position on circular orbit.
        let effectiveRadius = orbitRadius * orbitScale
        var orbitalPosition = SIMD3<Float>(
            effectiveRadius * cos(currentAngle),
            0,
            effectiveRadius * sin(currentAngle)
        )

        // Apply individual orbital tilt.
        orbitalPosition = orbitTilt.act(orbitalPosition)

        // Apply chaos perturbation.
        if chaosFactor > 0 {
            let chaosOffset = chaosDirection * chaosFactor * effectiveRadius * 0.5
            orbitalPosition += chaosOffset
        }

        // Calculate attraction force if target exists.
        if let target = attractionTarget {
            let toTarget = target - orbitalPosition
            let distance = length(toTarget)
            if distance > 0.001 {
                let attractionStrength: Float = 8.0
                let force = normalize(toTarget) * attractionStrength * deltaTime
                offsetVelocity += force
            }
        } else {
            // Return to orbit - spring force toward zero offset.
            let returnStrength: Float = 12.0
            offsetVelocity -= positionOffset * returnStrength * deltaTime
        }

        // Update position offset with velocity.
        positionOffset += offsetVelocity * deltaTime

        // Apply damping to velocity (approximation of pow(0.92, dt*60)).
        let damping = 1.0 - deltaTime * 5.0 // ~0.92^60 per second
        offsetVelocity *= max(0, damping)

        // Clamp offset to prevent sparks going too far.
        let maxOffset = effectiveRadius * 2.0
        let offsetLengthSq = simd_length_squared(positionOffset)
        let maxOffsetSq = maxOffset * maxOffset
        if offsetLengthSq > maxOffsetSq {
            positionOffset *= maxOffset / sqrt(offsetLengthSq)
        }

        // Final position.
        let finalPosition = orbitalPosition + positionOffset
        entity.position = finalPosition

        // Orient spark along direction of travel (optimized).
        let velocityLengthSq = simd_length_squared(offsetVelocity)
        var movementDirection: SIMD3<Float>

        if velocityLengthSq < 0.0001 {
            // Use orbital tangent when not moving (precomputed sin/cos already available).
            let tangent = SIMD3<Float>(-sin(currentAngle), 0, cos(currentAngle))
            movementDirection = orbitTilt.act(tangent)
        } else {
            movementDirection = offsetVelocity
        }

        let moveLengthSq = simd_length_squared(movementDirection)
        if moveLengthSq > 0.000001 {
            let invLen = 1.0 / sqrt(moveLengthSq)
            let forward = movementDirection * invLen

            let up = SIMD3<Float>(0, 1, 0)
            var right = cross(up, forward)
            let rightLengthSq = simd_length_squared(right)

            if rightLengthSq < 0.000001 {
                right = SIMD3<Float>(1, 0, 0)
            } else {
                right *= 1.0 / sqrt(rightLengthSq)
            }
            let correctedUp = cross(forward, right)

            let rotationMatrix = simd_float3x3(columns: (right, correctedUp, forward))
            entity.transform.rotation = simd_quatf(rotationMatrix)
        }

        // Apply breathing scale animation (amplified by excitement).
        let breathAmplitude = breathingAmplitude * (1.0 + (excitement - 1.0) * 0.5)
        let breathScale = 1.0 + sin(breathingPhase) * breathAmplitude
        let fadeScale = isFadingIn ? fadeProgress : (isFadingOut ? 1.0 - fadeProgress : 1.0)
        let totalScale = baseScale * breathScale * fadeScale
        entity.scale = [totalScale, totalScale * 1.4, totalScale] // Maintain elongation
    }

    // MARK: - Interaction Methods

    /// Applies a scatter impulse away from a point.
    func scatter(from point: SIMD3<Float>, strength: Float = 1.0) {
        let direction = entity.position - point
        let distance = length(direction)
        guard distance > 0.001 else { return }

        let normalizedDir = normalize(direction)
        let force = normalizedDir * strength * (1.0 / max(distance, 0.1))
        offsetVelocity += force
        excitement = min(3.0, excitement + 0.5)
    }

    /// Sets attraction target (nil to release).
    func attract(to point: SIMD3<Float>?) {
        attractionTarget = point
        if point != nil {
            excitement = min(2.5, excitement + 0.3)
        }
    }

    /// Applies chaos (random perturbation).
    func applyChaosFactor(_ chaos: Float) {
        chaosFactor = min(1.0, chaosFactor + chaos)
        // Generate new random chaos direction.
        chaosDirection = normalize(SIMD3<Float>(
            Float.random(in: -1...1),
            Float.random(in: -0.5...0.5),
            Float.random(in: -1...1)
        ))
        excitement = min(3.0, excitement + chaos)
    }

    /// Applies a ripple disturbance from a nearby point.
    func ripple(from point: SIMD3<Float>, radius: Float, strength: Float) {
        let distance = length(entity.position - point)
        guard distance < radius else { return }

        let falloff = 1.0 - (distance / radius)
        let perpendicular = normalize(cross(entity.position - point, SIMD3<Float>(0, 1, 0)))
        offsetVelocity += perpendicular * strength * falloff
        excitement = min(2.0, excitement + 0.2 * falloff)
    }

    // MARK: - Fade Animations

    /// Starts a fade-in animation.
    func fadeIn(duration: Float = 0.5) {
        isFadingIn = true
        isFadingOut = false
        fadeProgress = 0
        fadeDuration = duration
        entity.scale = [0.01, 0.01, 0.01] // Start invisible
        updateMaterialOpacity(0.01)
    }

    /// Starts a fade-out animation. Returns true when fully faded.
    func fadeOut(duration: Float = 0.5) {
        isFadingOut = true
        isFadingIn = false
        fadeProgress = 0
        fadeDuration = duration
    }

    private func updateFade(deltaTime: Float) {
        guard isFadingIn || isFadingOut else { return }

        fadeProgress += deltaTime / fadeDuration
        fadeProgress = min(fadeProgress, 1.0)

        if isFadingIn {
            let opacity = brightness * fadeProgress
            updateMaterialOpacity(opacity)

            if fadeProgress >= 1.0 {
                isFadingIn = false
            }
        } else if isFadingOut {
            let opacity = brightness * (1.0 - fadeProgress)
            updateMaterialOpacity(opacity)

            if fadeProgress >= 1.0 {
                isFadingOut = false
                isFullyFaded = true
            }
        }
    }

    /// Updates brightness (call when adherence changes).
    func updateBrightness(_ newBrightness: Float) {
        brightness = newBrightness
        updateMaterialOpacity(brightness)
    }

    private func updateMaterialOpacity(_ opacity: Float) {
        let clampedOpacity = max(0, min(1, opacity))

        // Only update when opacity changes significantly (10 steps).
        let step = Int(clampedOpacity * 10)
        guard step != lastOpacityStep else { return }
        lastOpacityStep = step

        cachedMaterial.color = .init(tint: SparkColors.withAlpha(baseColor, clampedOpacity))
        cachedMaterial.blending = .transparent(opacity: .init(floatLiteral: clampedOpacity))
        entity.model?.materials = [cachedMaterial]
    }
}
