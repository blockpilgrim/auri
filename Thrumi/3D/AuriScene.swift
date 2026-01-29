import RealityKit
import UIKit
import simd

/// The Auri 3D scene - a luminous orb with orbiting sparks representing your inner light.
///
/// Design philosophy:
/// - Cel-shaded / stylized (NOT photorealistic)
/// - Flat colors using UnlitMaterial
/// - Soft, magical color palette (teals, purples, pinks, golds)
/// - Think: Biophotons visualized, Studio Ghibli magic, Ori and the Blind Forest
///
/// The number of sparks, their speed, brightness, and color richness
/// reflect adherence state. Users can flick to spin the sparks faster.
@MainActor
final class AuriScene {
    /// Unit scale converts design units to RealityKit meters.
    static let unitScale: Float = 0.06

    let rootEntity: Entity

    private var sparks: [Spark] = []
    private var targetSparkCount: Int = 5
    private var currentPalette: [UIColor] = SparkColors.palette(for: 0)
    private var currentPaletteHash: Int = 0
    private var lastBrightnessUpdateTime: Float = 0
    private let brightnessUpdateInterval: Float = 0.1 // Update brightness 10x/sec, not 60+

    /// Timing for spark spawn/despawn.
    private var lastSparkAdjustTime: Float = 0
    private let sparkAdjustInterval: Float = 0.3 // Adjust one spark per this interval

    /// Optional container outline (currently disabled per spec recommendation).
    private var containerEntity: ModelEntity?

    // MARK: - Interaction State

    /// Orbit scale multiplier (1.0 = normal, controlled by pinch)
    private(set) var orbitScale: Float = 1.0

    /// Target orbit scale (smoothly interpolated)
    private var targetOrbitScale: Float = 1.0

    /// Tilt offset from two-finger rotation
    private(set) var tiltOffset: simd_quatf = simd_quatf(angle: 0, axis: [1, 0, 0])

    /// Sparkle entities for burst effect
    private var sparkles: [SparkleParticle] = []

    /// Global excitement multiplier
    private var globalExcitement: Float = 1.0


    /// Ambient mote system for floating particles
    private var moteSystem: AmbientMoteSystem?



    /// Tier transition effect
    private var tierTransitionEffect: TierTransitionEffect?
    private var lastTier: OrbTier = .dreaming


    /// Accumulated time for mote animation
    private var accumulatedTime: Float = 0

    // MARK: - Initialization

    private init(rootEntity: Entity) {
        self.rootEntity = rootEntity
    }

    // MARK: - Factory

    static func create() async -> AuriScene {
        let root = Entity()
        root.name = "Auri"

        // Scale and position for hero presentation.
        root.scale = SIMD3<Float>(repeating: 5.0)
        root.position = [0, -0.06, -0.32]

        // Pitch the scene to simulate a fixed camera looking down at ~60°.
        let pitch: Float = 60.0 * .pi / 180.0
        root.transform.rotation = simd_quatf(angle: pitch, axis: [1, 0, 0])

        // Optional: Add subtle ambient light for depth.
        let ambientLight = createAmbientLight()
        root.addChild(ambientLight)

        // Create ambient mote system
        let moteSystem = AmbientMoteSystem(unitScale: unitScale)
        root.addChild(moteSystem.containerEntity)

        // Create tier transition effect
        let tierTransitionEffect = TierTransitionEffect(unitScale: unitScale)
        root.addChild(tierTransitionEffect.containerEntity)

        let scene = AuriScene(rootEntity: root)
        scene.moteSystem = moteSystem
        scene.tierTransitionEffect = tierTransitionEffect

        // Create initial sparks (low adherence default).
        await scene.initializeSparks(count: 5, palette: SparkColors.palette(for: 0))

        return scene
    }

    /// Creates initial spark population.
    private func initializeSparks(count: Int, palette: [UIColor]) async {
        targetSparkCount = count
        currentPalette = palette

        for _ in 0..<count {
            let spark = createNewSpark()
            sparks.append(spark)
            rootEntity.addChild(spark.entity)
        }
    }

    // MARK: - Update

    /// Main update method called each frame.
    ///
    /// - Parameters:
    ///   - interpolator: State interpolator with adherence-based parameters
    ///   - spinAngle: Global spin angle from physics (user flick response)
    ///   - deltaTime: Frame delta time
    ///   - breathingPulse: Pulse value for breathing animation
    ///   - motionConfig: Reduced motion configuration (optional, defaults to normal)
    func update(
        interpolator: StateInterpolator,
        spinAngle: Float,
        deltaTime: Float,
        breathingPulse: Float,
        motionConfig: ReducedMotionConfig = .normal
    ) {
        // Update target spark count and palette from interpolator.
        let newTarget = interpolator.sparkCount
        if newTarget != targetSparkCount {
            targetSparkCount = newTarget
        }

        // Check palette change via hash (much faster than color comparison).
        let newPaletteHash = interpolator.colorPalette.count
        if newPaletteHash != currentPaletteHash {
            currentPalette = interpolator.colorPalette
            currentPaletteHash = newPaletteHash
        }

        // Gradually adjust spark count.
        adjustSparkCount(deltaTime: deltaTime)

        // Smooth orbit scale toward target.
        orbitScale += (targetOrbitScale - orbitScale) * min(1.0, deltaTime * 8.0)

        // Decay global excitement (approximation of pow(0.96, dt*60)).
        let excitementDecay = 1.0 - deltaTime * 2.4
        globalExcitement = 1.0 + (globalExcitement - 1.0) * max(0, excitementDecay)

        // Update each spark.
        // Note: Each spark accumulates its own orbital angle internally.
        // spinAngle is the user interaction (flick) component only.
        for spark in sparks {
            spark.update(
                deltaTime: deltaTime,
                globalSpinAngle: spinAngle,
                baseOrbitSpeed: interpolator.baseOrbitSpeed * globalExcitement,
                breathingPulse: breathingPulse,
                breathingAmplitude: interpolator.breathingAmplitude,
                orbitScale: orbitScale
            )
        }

        // Update sparkles.
        updateSparkles(deltaTime: deltaTime)

        // Update ambient mote system (respects reduced motion).
        accumulatedTime += deltaTime
        let showMotes = motionConfig.showMotes
        if showMotes {
            moteSystem?.update(
                deltaTime: deltaTime,
                targetCount: interpolator.moteCount,
                brightness: interpolator.moteBrightness,
                palette: currentPalette,
                time: accumulatedTime
            )
        } else {
            moteSystem?.removeAllMotes()
        }

        // Check for tier transition and update effect (respects reduced motion).
        let currentTier = OrbTier.from(adherence: Double(interpolator.adherence))
        if currentTier != lastTier {
            let isUpgrade = tierValue(currentTier) > tierValue(lastTier)
            if motionConfig.showTierTransitions {
                tierTransitionEffect?.trigger(isUpgrade: isUpgrade, palette: currentPalette)
            }
            lastTier = currentTier
        }

        if motionConfig.showTierTransitions, let transitionEffect = tierTransitionEffect {
            let shouldSparkle = transitionEffect.update(deltaTime: deltaTime)
            if shouldSparkle {
                // Trigger a mini sparkle burst for the celebration
                triggerDoubleTapBurst()
            }
        }

        // Remove fully faded sparks (iterate backwards to avoid index issues).
        var i = sparks.count - 1
        while i >= 0 {
            if sparks[i].isFullyFaded {
                sparks[i].entity.removeFromParent()
                sparks.remove(at: i)
            }
            i -= 1
        }

        // Update brightness on sparks (throttled to reduce material updates).
        lastBrightnessUpdateTime += deltaTime
        if lastBrightnessUpdateTime >= brightnessUpdateInterval {
            lastBrightnessUpdateTime = 0
            let brightness = interpolator.sparkBrightness
            for spark in sparks where !spark.isFadingOut {
                spark.updateBrightness(brightness)
            }
        }
    }

    // MARK: - Spark Management

    /// Gradually adjusts spark count toward target.
    private func adjustSparkCount(deltaTime: Float) {
        lastSparkAdjustTime += deltaTime

        guard lastSparkAdjustTime >= sparkAdjustInterval else { return }
        lastSparkAdjustTime = 0

        let activeSparks = sparks.filter { !$0.isFullyFaded && !$0.isFadingOut }
        let activeCount = activeSparks.count

        if activeCount < targetSparkCount {
            // Add a spark.
            let spark = createNewSpark()
            spark.fadeIn(duration: 0.4)
            sparks.append(spark)
            rootEntity.addChild(spark.entity)
        } else if activeCount > targetSparkCount {
            // Remove a spark (fade out the oldest non-fading one).
            if let sparkToRemove = activeSparks.first {
                sparkToRemove.fadeOut(duration: 0.5)
            }
        }
    }

    /// Creates a new spark with current palette colors.
    private func createNewSpark() -> Spark {
        let color = SparkColors.randomColor(from: currentPalette)

        // Vary orbit radius for depth - larger area for more visual impact.
        let baseRadius: Float = 0.6 * Self.unitScale
        let radiusVariation = Float.random(in: 0.5...1.5)

        return Spark.create(
            color: color,
            orbitRadius: baseRadius * radiusVariation,
            brightness: SparkColors.brightness(for: 0.5), // Will be updated
            unitScale: Self.unitScale
        )
    }

    // MARK: - Micro-Feedback

    /// Triggers on-track feedback: sparks briefly accelerate and pulse brighter.
    func triggerOnTrackFeedback() {
        // Briefly increase brightness and add a new spark faster.
        for spark in sparks where !spark.isFadingOut {
            spark.updateBrightness(min(1.0, spark.brightness + 0.2))
        }

        // Add a new spark immediately if under target.
        let activeCount = sparks.filter { !$0.isFullyFaded && !$0.isFadingOut }.count
        if activeCount <= targetSparkCount {
            let spark = createNewSpark()
            spark.fadeIn(duration: 0.3)
            sparks.append(spark)
            rootEntity.addChild(spark.entity)
        }
    }

    /// Triggers off-track feedback: sparks briefly slow and one fades out.
    func triggerOffTrackFeedback() {
        // Fade out one spark.
        let activeSparks = sparks.filter { !$0.isFullyFaded && !$0.isFadingOut }
        if let sparkToRemove = activeSparks.last {
            sparkToRemove.fadeOut(duration: 0.6)
        }
    }

    // MARK: - Interactive Gestures

    /// Called when user taps - scatters sparks outward from center.
    func triggerTapScatter() {
        let center = SIMD3<Float>.zero
        for spark in sparks where !spark.isFullyFaded {
            spark.scatter(from: center, strength: 0.15)
        }
        globalExcitement = min(2.0, globalExcitement + 0.3)
    }

    /// Called when user double-taps - creates sparkle burst.
    func triggerDoubleTapBurst() {
        // Create sparkle particles.
        let sparkleCount = 12
        for _ in 0..<sparkleCount {
            let sparkle = SparkleParticle.create(
                color: SparkColors.randomColor(from: currentPalette),
                unitScale: Self.unitScale
            )
            sparkles.append(sparkle)
            rootEntity.addChild(sparkle.entity)
        }

        // Energize all sparks.
        for spark in sparks where !spark.isFullyFaded {
            spark.excitement = min(3.0, spark.excitement + 1.0)
            spark.scatter(from: .zero, strength: 0.08)
        }

        globalExcitement = min(2.5, globalExcitement + 0.5)
    }

    /// Called during long press - attracts sparks toward a point.
    /// - Parameter point: Attraction point in scene coordinates (nil to release)
    func setAttractionPoint(_ point: SIMD3<Float>?) {
        for spark in sparks where !spark.isFullyFaded {
            spark.attract(to: point)
        }
    }

    /// Called during pinch - scales orbit radius.
    /// - Parameter scale: Scale multiplier (1.0 = normal)
    func setPinchScale(_ scale: Float) {
        targetOrbitScale = max(0.4, min(2.0, scale))
    }

    /// Called when pinch ends - smoothly return to normal.
    func releasePinchScale() {
        targetOrbitScale = 1.0
    }

    /// Called during two-finger rotation - tilts orbital plane.
    /// - Parameter angle: Rotation angle in radians
    func setTwistAngle(_ angle: Float) {
        let clampedAngle = max(-0.5, min(0.5, angle))
        tiltOffset = simd_quatf(angle: clampedAngle, axis: [0, 0, 1])

        // Apply to root entity.
        let basePitch: Float = 60.0 * .pi / 180.0
        let baseRotation = simd_quatf(angle: basePitch, axis: [1, 0, 0])
        rootEntity.transform.rotation = baseRotation * tiltOffset
    }

    /// Called when twist ends - smoothly return to normal.
    func releaseTwist() {
        // Animate back via update loop.
        tiltOffset = simd_quatf(angle: 0, axis: [0, 0, 1])
        let basePitch: Float = 60.0 * .pi / 180.0
        rootEntity.transform.rotation = simd_quatf(angle: basePitch, axis: [1, 0, 0])
    }

    /// Called when drag passes through scene - creates ripple.
    /// - Parameter point: Touch point in scene coordinates
    func triggerRipple(at point: SIMD3<Float>) {
        let rippleRadius: Float = 0.08
        let rippleStrength: Float = 0.12

        for spark in sparks where !spark.isFullyFaded {
            spark.ripple(from: point, radius: rippleRadius, strength: rippleStrength)
        }
    }

    /// Called when device is shaken - triggers chaos mode.
    func triggerShakeChaos(intensity: Float = 1.0) {
        let chaosAmount = min(1.0, intensity * 0.4)

        for spark in sparks where !spark.isFullyFaded {
            spark.applyChaosFactor(chaosAmount)
        }

        globalExcitement = min(3.0, globalExcitement + intensity * 0.5)
    }

    // MARK: - Sparkle System

    private func updateSparkles(deltaTime: Float) {
        sparkles.removeAll { sparkle in
            sparkle.update(deltaTime: deltaTime)
            if sparkle.isExpired {
                sparkle.entity.removeFromParent()
                return true
            }
            return false
        }
    }

    // MARK: - Lighting

    private static func createAmbientLight() -> Entity {
        let entity = Entity()
        entity.name = "AmbientLight"

        var light = DirectionalLightComponent()
        light.color = .init(white: 0.3, alpha: 1.0)
        light.intensity = 200
        entity.components.set(light)

        entity.transform.rotation = simd_quatf(angle: -.pi / 4, axis: [1, 0, 0])

        return entity
    }

    // MARK: - Tier Helpers

    private func tierValue(_ tier: OrbTier) -> Int {
        switch tier {
        case .dreaming: return 0
        case .resting: return 1
        case .awakening: return 2
        case .vibrant: return 3
        case .radiant: return 4
        }
    }

}

// MARK: - Sparkle Particle

/// A short-lived sparkle particle for burst effects.
@MainActor
final class SparkleParticle {
    // Shared mesh resource for all sparkles
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
    private var lifetime: Float = 0
    private let maxLifetime: Float
    private var velocity: SIMD3<Float>
    private let initialScale: Float

    // Cached material for performance
    private var cachedMaterial: UnlitMaterial
    private var lastOpacityStep: Int = 10

    var isExpired: Bool { lifetime >= maxLifetime }

    private init(entity: ModelEntity, velocity: SIMD3<Float>, maxLifetime: Float, initialScale: Float, material: UnlitMaterial) {
        self.entity = entity
        self.velocity = velocity
        self.maxLifetime = maxLifetime
        self.initialScale = initialScale
        self.cachedMaterial = material
    }

    static func create(color: UIColor, unitScale: Float) -> SparkleParticle {
        let radius: Float = 0.012 * unitScale
        let mesh = getSharedMesh(radius: radius)

        var material = UnlitMaterial()
        material.color = .init(tint: color)
        material.blending = .transparent(opacity: 1.0)

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "Sparkle"

        // Random outward velocity (precompute trig).
        let speed = Float.random(in: 0.08...0.18)
        let theta = Float.random(in: 0...(2 * .pi))
        let phi = Float.random(in: -0.5...0.5)
        let cosTheta = cos(theta)
        let sinTheta = sin(theta)
        let cosPhi = cos(phi)
        let sinPhi = sin(phi)
        let velocity = SIMD3<Float>(
            cosTheta * cosPhi * speed,
            sinPhi * speed * 0.5,
            sinTheta * cosPhi * speed
        )

        let maxLifetime = Float.random(in: 0.4...0.8)
        let initialScale = Float.random(in: 0.6...1.2)

        return SparkleParticle(
            entity: entity,
            velocity: velocity,
            maxLifetime: maxLifetime,
            initialScale: initialScale,
            material: material
        )
    }

    func update(deltaTime: Float) {
        lifetime += deltaTime

        // Move outward.
        entity.position += velocity * deltaTime

        // Slow down (approximation of pow(0.92, dt*60)).
        let drag = 1.0 - deltaTime * 5.0
        velocity *= max(0, drag)

        // Fade and shrink.
        let progress = lifetime / maxLifetime
        let scale = initialScale * (1.0 - progress * 0.8)

        entity.scale = SIMD3<Float>(repeating: max(0.01, scale))

        // Update material opacity only when it changes significantly (5 steps).
        let opacityStep = Int((1.0 - progress) * 5)
        if opacityStep != lastOpacityStep {
            lastOpacityStep = opacityStep
            let opacity = Float(opacityStep) / 5.0
            cachedMaterial.blending = .transparent(opacity: .init(floatLiteral: opacity))
            entity.model?.materials = [cachedMaterial]
        }
    }
}
