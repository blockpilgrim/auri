import RealityKit
import UIKit
import simd

/// A single wisp entity that orbits within the Orb of Wisps.
///
/// Wisps are small teardrop/flame-shaped spirits that orbit the center
/// on individual tilted orbital planes. They use UnlitMaterial for
/// bright, saturated cel-shaded appearance.
@MainActor
final class Wisp {
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
    private var currentAngle: Float = 0

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

    /// Creates a new wisp with randomized orbital parameters.
    ///
    /// - Parameters:
    ///   - color: The wisp's base color (from WispColors palette)
    ///   - orbitRadius: Base orbit radius (varied slightly for organic feel)
    ///   - brightness: Brightness multiplier based on adherence
    ///   - unitScale: Scene unit scale
    static func create(
        color: UIColor,
        orbitRadius: Float,
        brightness: Float,
        unitScale: Float
    ) -> Wisp {
        // Create elongated sphere mesh for teardrop/flame shape.
        // Scale Y axis for elongation.
        let baseRadius: Float = 0.025 * unitScale
        let mesh = MeshResource.generateSphere(radius: baseRadius)

        // Bright UnlitMaterial - cel-shaded look.
        var material = UnlitMaterial()
        let tintColor = WispColors.withAlpha(color, brightness)
        material.color = .init(tint: tintColor)
        material.blending = .transparent(opacity: .init(floatLiteral: brightness))

        let entity = ModelEntity(mesh: mesh, materials: [material])
        entity.name = "Wisp"

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

        return Wisp(
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

    /// Updates the wisp's position and appearance.
    ///
    /// - Parameters:
    ///   - deltaTime: Frame delta time
    ///   - globalSpinAngle: Global spin angle from physics (flick response)
    ///   - baseOrbitSpeed: Base orbit speed from state interpolator
    ///   - breathingPulse: Breathing animation pulse value (-1 to 1)
    ///   - breathingAmplitude: Breathing scale amplitude
    func update(
        deltaTime: Float,
        globalSpinAngle: Float,
        baseOrbitSpeed: Float,
        breathingPulse: Float,
        breathingAmplitude: Float
    ) {
        // Update fade state.
        updateFade(deltaTime: deltaTime)

        guard !isFullyFaded else { return }

        // Update breathing phase.
        breathingPhase += deltaTime * 2.0 * .pi * 0.5 // 0.5 Hz breathing
        if breathingPhase > 2 * .pi {
            breathingPhase -= 2 * .pi
        }

        // Calculate current orbital angle.
        // Combines base orbit speed with global spin from user interaction.
        currentAngle = orbitPhase + globalSpinAngle * speedMultiplier + baseOrbitSpeed * speedMultiplier

        // Calculate position on circular orbit.
        var position = SIMD3<Float>(
            orbitRadius * cos(currentAngle),
            0,
            orbitRadius * sin(currentAngle)
        )

        // Apply individual orbital tilt.
        position = orbitTilt.act(position)

        entity.position = position

        // Orient wisp along direction of travel (tangent).
        let tangent = SIMD3<Float>(-sin(currentAngle), 0, cos(currentAngle))
        let tiltedTangent = orbitTilt.act(tangent)
        if length(tiltedTangent) > 0.001 {
            // Point the elongated end in direction of travel.
            let forward = normalize(tiltedTangent)
            let up = SIMD3<Float>(0, 1, 0)
            let right = normalize(cross(up, forward))
            let correctedUp = cross(forward, right)

            let rotationMatrix = simd_float3x3(columns: (right, correctedUp, forward))
            entity.transform.rotation = simd_quatf(rotationMatrix)
        }

        // Apply breathing scale animation.
        let breathScale = 1.0 + sin(breathingPhase) * breathingAmplitude
        let fadeScale = isFadingIn ? fadeProgress : (isFadingOut ? 1.0 - fadeProgress : 1.0)
        let totalScale = baseScale * breathScale * fadeScale
        entity.scale = [totalScale, totalScale * 1.4, totalScale] // Maintain elongation
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

        cachedMaterial.color = .init(tint: WispColors.withAlpha(baseColor, clampedOpacity))
        cachedMaterial.blending = .transparent(opacity: .init(floatLiteral: clampedOpacity))
        entity.model?.materials = [cachedMaterial]
    }
}
