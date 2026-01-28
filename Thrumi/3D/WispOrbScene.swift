import RealityKit
import UIKit
import simd

/// The Orb of Wisps 3D scene - a magical orb with orbiting spirit-like elements.
///
/// Design philosophy:
/// - Cel-shaded / stylized (NOT photorealistic)
/// - Flat colors using UnlitMaterial
/// - Soft, magical color palette (teals, purples, pinks, golds)
/// - Think: Studio Ghibli magic, Ori and the Blind Forest, fantasy mana orbs
///
/// The number of wisps, their speed, brightness, and color richness
/// reflect adherence state. Users can flick to spin the wisps faster.
@MainActor
final class WispOrbScene {
    /// Unit scale converts design units to RealityKit meters.
    static let unitScale: Float = 0.06

    let rootEntity: Entity

    private var wisps: [Wisp] = []
    private var targetWispCount: Int = 5
    private var currentPalette: [UIColor] = WispColors.palette(for: 0)
    private var currentPaletteHash: Int = 0
    private var lastBrightnessUpdateTime: Float = 0
    private let brightnessUpdateInterval: Float = 0.1 // Update brightness 10x/sec, not 60+

    /// Accumulated orbit angle for base orbital motion (separate from spin).
    private var baseOrbitAngle: Float = 0

    /// Timing for wisp spawn/despawn.
    private var lastWispAdjustTime: Float = 0
    private let wispAdjustInterval: Float = 0.3 // Adjust one wisp per this interval

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

    // MARK: - Initialization

    private init(rootEntity: Entity) {
        self.rootEntity = rootEntity
    }

    // MARK: - Factory

    static func create() async -> WispOrbScene {
        let root = Entity()
        root.name = "WispOrb"

        // Scale and position for hero presentation.
        root.scale = SIMD3<Float>(repeating: 5.0)
        root.position = [0, -0.06, -0.32]

        // Pitch the scene to simulate a fixed camera looking down at ~60°.
        let pitch: Float = 60.0 * .pi / 180.0
        root.transform.rotation = simd_quatf(angle: pitch, axis: [1, 0, 0])

        // Optional: Add subtle ambient light for depth.
        let ambientLight = createAmbientLight()
        root.addChild(ambientLight)

        let scene = WispOrbScene(rootEntity: root)

        // Create initial wisps (low adherence default).
        await scene.initializeWisps(count: 5, palette: WispColors.palette(for: 0))

        return scene
    }

    /// Creates initial wisp population.
    private func initializeWisps(count: Int, palette: [UIColor]) async {
        targetWispCount = count
        currentPalette = palette

        for _ in 0..<count {
            let wisp = createNewWisp()
            wisps.append(wisp)
            rootEntity.addChild(wisp.entity)
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
    func update(
        interpolator: StateInterpolator,
        spinAngle: Float,
        deltaTime: Float,
        breathingPulse: Float
    ) {
        // Update target wisp count and palette from interpolator.
        let newTarget = interpolator.wispCount
        if newTarget != targetWispCount {
            targetWispCount = newTarget
        }

        // Check palette change via hash (much faster than color comparison).
        let newPaletteHash = interpolator.colorPalette.count
        if newPaletteHash != currentPaletteHash {
            currentPalette = interpolator.colorPalette
            currentPaletteHash = newPaletteHash
        }

        // Gradually adjust wisp count.
        adjustWispCount(deltaTime: deltaTime)

        // Update base orbit angle.
        baseOrbitAngle += deltaTime * interpolator.baseOrbitSpeed
        if baseOrbitAngle > 2 * .pi {
            baseOrbitAngle -= 2 * .pi
        }

        // Smooth orbit scale toward target.
        orbitScale += (targetOrbitScale - orbitScale) * min(1.0, deltaTime * 8.0)

        // Decay global excitement (approximation of pow(0.96, dt*60)).
        let excitementDecay = 1.0 - deltaTime * 2.4
        globalExcitement = 1.0 + (globalExcitement - 1.0) * max(0, excitementDecay)

        // Update each wisp.
        let combinedAngle = baseOrbitAngle + spinAngle

        for wisp in wisps {
            wisp.update(
                deltaTime: deltaTime,
                globalSpinAngle: combinedAngle,
                baseOrbitSpeed: interpolator.baseOrbitSpeed * globalExcitement,
                breathingPulse: breathingPulse,
                breathingAmplitude: interpolator.breathingAmplitude,
                orbitScale: orbitScale
            )
        }

        // Update sparkles.
        updateSparkles(deltaTime: deltaTime)

        // Remove fully faded wisps (iterate backwards to avoid index issues).
        var i = wisps.count - 1
        while i >= 0 {
            if wisps[i].isFullyFaded {
                wisps[i].entity.removeFromParent()
                wisps.remove(at: i)
            }
            i -= 1
        }

        // Update brightness on wisps (throttled to reduce material updates).
        lastBrightnessUpdateTime += deltaTime
        if lastBrightnessUpdateTime >= brightnessUpdateInterval {
            lastBrightnessUpdateTime = 0
            let brightness = interpolator.wispBrightness
            for wisp in wisps where !wisp.isFadingOut {
                wisp.updateBrightness(brightness)
            }
        }
    }

    // MARK: - Wisp Management

    /// Gradually adjusts wisp count toward target.
    private func adjustWispCount(deltaTime: Float) {
        lastWispAdjustTime += deltaTime

        guard lastWispAdjustTime >= wispAdjustInterval else { return }
        lastWispAdjustTime = 0

        let activeWisps = wisps.filter { !$0.isFullyFaded && !$0.isFadingOut }
        let activeCount = activeWisps.count

        if activeCount < targetWispCount {
            // Add a wisp.
            let wisp = createNewWisp()
            wisp.fadeIn(duration: 0.4)
            wisps.append(wisp)
            rootEntity.addChild(wisp.entity)
        } else if activeCount > targetWispCount {
            // Remove a wisp (fade out the oldest non-fading one).
            if let wispToRemove = activeWisps.first {
                wispToRemove.fadeOut(duration: 0.5)
            }
        }
    }

    /// Creates a new wisp with current palette colors.
    private func createNewWisp() -> Wisp {
        let color = WispColors.randomColor(from: currentPalette)

        // Vary orbit radius for depth.
        let baseRadius: Float = 0.4 * Self.unitScale
        let radiusVariation = Float.random(in: 0.6...1.4)

        return Wisp.create(
            color: color,
            orbitRadius: baseRadius * radiusVariation,
            brightness: WispColors.brightness(for: 0.5), // Will be updated
            unitScale: Self.unitScale
        )
    }

    // MARK: - Micro-Feedback

    /// Triggers on-track feedback: wisps briefly accelerate and pulse brighter.
    func triggerOnTrackFeedback() {
        // Briefly increase brightness and add a new wisp faster.
        for wisp in wisps where !wisp.isFadingOut {
            wisp.updateBrightness(min(1.0, wisp.brightness + 0.2))
        }

        // Add a new wisp immediately if under target.
        let activeCount = wisps.filter { !$0.isFullyFaded && !$0.isFadingOut }.count
        if activeCount <= targetWispCount {
            let wisp = createNewWisp()
            wisp.fadeIn(duration: 0.3)
            wisps.append(wisp)
            rootEntity.addChild(wisp.entity)
        }
    }

    /// Triggers off-track feedback: wisps briefly slow and one fades out.
    func triggerOffTrackFeedback() {
        // Fade out one wisp.
        let activeWisps = wisps.filter { !$0.isFullyFaded && !$0.isFadingOut }
        if let wispToRemove = activeWisps.last {
            wispToRemove.fadeOut(duration: 0.6)
        }
    }

    // MARK: - Interactive Gestures

    /// Called when user taps - scatters wisps outward from center.
    func triggerTapScatter() {
        let center = SIMD3<Float>.zero
        for wisp in wisps where !wisp.isFullyFaded {
            wisp.scatter(from: center, strength: 0.15)
        }
        globalExcitement = min(2.0, globalExcitement + 0.3)
    }

    /// Called when user double-taps - creates sparkle burst.
    func triggerDoubleTapBurst() {
        // Create sparkle particles.
        let sparkleCount = 12
        for _ in 0..<sparkleCount {
            let sparkle = SparkleParticle.create(
                color: WispColors.randomColor(from: currentPalette),
                unitScale: Self.unitScale
            )
            sparkles.append(sparkle)
            rootEntity.addChild(sparkle.entity)
        }

        // Energize all wisps.
        for wisp in wisps where !wisp.isFullyFaded {
            wisp.excitement = min(3.0, wisp.excitement + 1.0)
            wisp.scatter(from: .zero, strength: 0.08)
        }

        globalExcitement = min(2.5, globalExcitement + 0.5)
    }

    /// Called during long press - attracts wisps toward a point.
    /// - Parameter point: Attraction point in scene coordinates (nil to release)
    func setAttractionPoint(_ point: SIMD3<Float>?) {
        for wisp in wisps where !wisp.isFullyFaded {
            wisp.attract(to: point)
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

        for wisp in wisps where !wisp.isFullyFaded {
            wisp.ripple(from: point, radius: rippleRadius, strength: rippleStrength)
        }
    }

    /// Called when device is shaken - triggers chaos mode.
    func triggerShakeChaos(intensity: Float = 1.0) {
        let chaosAmount = min(1.0, intensity * 0.4)

        for wisp in wisps where !wisp.isFullyFaded {
            wisp.applyChaosFactor(chaosAmount)
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
