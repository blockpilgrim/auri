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

    /// Accumulated orbit angle for base orbital motion (separate from spin).
    private var baseOrbitAngle: Float = 0

    /// Timing for wisp spawn/despawn.
    private var lastWispAdjustTime: Float = 0
    private let wispAdjustInterval: Float = 0.3 // Adjust one wisp per this interval

    /// Optional container outline (currently disabled per spec recommendation).
    private var containerEntity: ModelEntity?

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
        let newPalette = interpolator.colorPalette

        if newTarget != targetWispCount || paletteChanged(newPalette) {
            targetWispCount = newTarget
            currentPalette = newPalette
        }

        // Gradually adjust wisp count.
        adjustWispCount(deltaTime: deltaTime)

        // Update base orbit angle.
        baseOrbitAngle += deltaTime * interpolator.baseOrbitSpeed
        if baseOrbitAngle > 2 * .pi {
            baseOrbitAngle -= 2 * .pi
        }

        // Update each wisp.
        let combinedAngle = baseOrbitAngle + spinAngle

        for wisp in wisps {
            wisp.update(
                deltaTime: deltaTime,
                globalSpinAngle: combinedAngle,
                baseOrbitSpeed: interpolator.baseOrbitSpeed,
                breathingPulse: breathingPulse,
                breathingAmplitude: interpolator.breathingAmplitude
            )
        }

        // Remove fully faded wisps.
        wisps.removeAll { wisp in
            if wisp.isFullyFaded {
                wisp.entity.removeFromParent()
                return true
            }
            return false
        }

        // Update brightness on all wisps.
        let brightness = interpolator.wispBrightness
        for wisp in wisps where !wisp.isFadingOut {
            wisp.updateBrightness(brightness)
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

    /// Checks if palette has changed.
    private func paletteChanged(_ newPalette: [UIColor]) -> Bool {
        guard newPalette.count == currentPalette.count else { return true }

        for (i, color) in newPalette.enumerated() {
            if !colorsEqual(color, currentPalette[i]) {
                return true
            }
        }
        return false
    }

    private func colorsEqual(_ a: UIColor, _ b: UIColor) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        a.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        b.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return abs(r1 - r2) < 0.01 && abs(g1 - g2) < 0.01 && abs(b1 - b2) < 0.01
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
