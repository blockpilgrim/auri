import Foundation
import simd

/// Custom kinematic physics system for the Fusion Core fidget spinner.
///
/// This provides direct control over angular velocity, damping, speed ceilings, and stabilization
/// rather than using RealityKit's built-in physics. This allows us to tune the "feel" precisely
/// based on adherence state.
@Observable
@MainActor
final class SpinnerPhysics {
    // MARK: - Current State

    /// Angular velocity in radians/second for each axis (x, y, z)
    /// Primary spin is on Y axis (vertical)
    var angularVelocity: SIMD3<Float> = .zero

    /// Current rotation angles for each ring (outer, middle, inner)
    var ringRotations: SIMD3<Float> = .zero

    // MARK: - Physics Parameters (driven by adherence)

    /// Maximum angular speed in rad/s. Higher adherence = higher ceiling.
    var maxSpeed: Float = 10.0

    /// Damping factor per frame (0.98 = slow decay, 0.90 = fast decay)
    var damping: Float = 0.98

    /// Wobble suppression strength (0.0 = no suppression, 1.0 = full suppression)
    var stabilizationAuthority: Float = 0.8

    /// Gesture responsiveness multiplier
    var torqueMultiplier: Float = 1.0

    /// Minimum speed below which we stop completely (prevents endless tiny rotation)
    private let velocityThreshold: Float = 0.01

    // MARK: - Ring Speed Ratios

    /// Inner rings spin faster than outer rings for visual interest
    /// [outer, middle, inner]
    static let ringSpeedRatios: SIMD3<Float> = [1.0, 1.3, 1.6]

    // MARK: - Tier-Based Parameter Presets

    /// Parameters tuned for each adherence tier
    struct TierParameters {
        let maxSpeed: Float
        let damping: Float
        let stabilizationAuthority: Float
        let torqueMultiplier: Float
    }

    static let tierPresets: [CoreTier: TierParameters] = [
        .phaseLocked: TierParameters(maxSpeed: 15.0, damping: 0.992, stabilizationAuthority: 0.95, torqueMultiplier: 1.2),
        .online: TierParameters(maxSpeed: 12.0, damping: 0.988, stabilizationAuthority: 0.85, torqueMultiplier: 1.1),
        .stabilizing: TierParameters(maxSpeed: 9.0, damping: 0.982, stabilizationAuthority: 0.70, torqueMultiplier: 1.0),
        .standby: TierParameters(maxSpeed: 6.0, damping: 0.970, stabilizationAuthority: 0.50, torqueMultiplier: 0.85),
        .safeMode: TierParameters(maxSpeed: 4.0, damping: 0.950, stabilizationAuthority: 0.30, torqueMultiplier: 0.7),
    ]

    // MARK: - Update Loop

    /// Updates physics state. Called every frame.
    /// - Parameter deltaTime: Time since last update in seconds
    func update(deltaTime: Float) {
        // Apply damping (exponential decay)
        angularVelocity *= damping

        // Apply stabilization - suppress non-primary axes (wobble reduction)
        applyStabilization()

        // Clamp to max speed
        angularVelocity = clampVelocity(angularVelocity, maxSpeed: maxSpeed)

        // Stop if below threshold
        if length(angularVelocity) < velocityThreshold {
            angularVelocity = .zero
        }

        // Update ring rotations
        // Primary spin axis is Y, each ring spins at its own ratio
        let baseRotation = angularVelocity.y * deltaTime
        ringRotations += SIMD3<Float>(
            baseRotation * Self.ringSpeedRatios.x,
            baseRotation * Self.ringSpeedRatios.y,
            baseRotation * Self.ringSpeedRatios.z
        )

        // Normalize rotations to prevent float overflow after long sessions
        ringRotations = normalizeRotations(ringRotations)
    }

    // MARK: - Torque Application

    /// Applies torque from a gesture (e.g., flick)
    /// - Parameter torque: Torque vector in rad/s^2
    func applyTorque(_ torque: SIMD3<Float>) {
        angularVelocity += torque * torqueMultiplier
    }

    /// Applies torque from a flick gesture velocity
    /// - Parameter velocity: Velocity from DragGesture in points/second
    func applyFlickTorque(velocity: CGSize) {
        // Convert 2D gesture velocity to 3D torque
        // Horizontal swipe → Y-axis rotation (primary spin)
        // Vertical swipe → X-axis rotation (tilt wobble)
        let torqueScale: Float = 0.008 // Tuned for good feel

        let torque = SIMD3<Float>(
            Float(velocity.height) * torqueScale * 0.3, // Subtle tilt from vertical swipe
            Float(velocity.width) * torqueScale,        // Primary spin from horizontal swipe
            0
        )

        applyTorque(torque)
    }

    /// Sets angular velocity directly (for twist gesture)
    /// - Parameter velocity: Angular velocity to set on Y axis
    func setYawVelocity(_ velocity: Float) {
        angularVelocity.y = velocity * torqueMultiplier
    }

    /// Adds a small impulse (for tap ping)
    func addPingImpulse() {
        // Brief acceleration burst on all rings
        let pingStrength: Float = 0.5
        angularVelocity.y += pingStrength
    }

    // MARK: - Precession (Device Tilt)

    /// Applies subtle precession based on device tilt
    /// - Parameters:
    ///   - pitch: Device pitch (forward/back tilt) in radians
    ///   - roll: Device roll (left/right tilt) in radians
    func applyPrecession(pitch: Float, roll: Float) {
        // Only apply precession when spinning
        let spinSpeed = abs(angularVelocity.y)
        guard spinSpeed > 0.5 else { return }

        // Precession strength scales with spin speed and stabilization authority
        let precessionStrength: Float = 0.15 * (1.0 - stabilizationAuthority) * min(spinSpeed / 5.0, 1.0)

        // Tilt causes cross-axis wobble
        angularVelocity.x += roll * precessionStrength
        angularVelocity.z += pitch * precessionStrength
    }

    // MARK: - Parameter Updates

    /// Updates physics parameters based on adherence state
    /// - Parameter state: Current adherence state
    func updateParameters(for state: AdherenceState) {
        guard let preset = Self.tierPresets[state.tier] else { return }

        // Smooth interpolation within tiers based on exact adherence
        let tierProgress = tierProgress(for: state.coreAdherence, tier: state.tier)

        // Get adjacent tier for interpolation (if not at extremes)
        let (lowerPreset, upperPreset) = getInterpolationPresets(for: state.tier)

        maxSpeed = lerp(lowerPreset.maxSpeed, upperPreset.maxSpeed, t: tierProgress)
        damping = lerp(lowerPreset.damping, upperPreset.damping, t: tierProgress)
        stabilizationAuthority = lerp(lowerPreset.stabilizationAuthority, upperPreset.stabilizationAuthority, t: tierProgress)
        torqueMultiplier = lerp(lowerPreset.torqueMultiplier, upperPreset.torqueMultiplier, t: tierProgress)
    }

    // MARK: - Private Helpers

    private func applyStabilization() {
        // Suppress X and Z axis rotation (wobble) based on authority
        // Higher authority = more wobble suppression
        let suppressionFactor = 1.0 - stabilizationAuthority * 0.15

        angularVelocity.x *= suppressionFactor
        angularVelocity.z *= suppressionFactor
    }

    private func clampVelocity(_ velocity: SIMD3<Float>, maxSpeed: Float) -> SIMD3<Float> {
        var clamped = velocity

        // Clamp each axis independently
        clamped.x = max(-maxSpeed * 0.3, min(maxSpeed * 0.3, clamped.x)) // Wobble axes limited
        clamped.y = max(-maxSpeed, min(maxSpeed, clamped.y))             // Primary axis full range
        clamped.z = max(-maxSpeed * 0.3, min(maxSpeed * 0.3, clamped.z)) // Wobble axes limited

        return clamped
    }

    private func normalizeRotations(_ rotations: SIMD3<Float>) -> SIMD3<Float> {
        let twoPi = Float.pi * 2
        return SIMD3<Float>(
            rotations.x.truncatingRemainder(dividingBy: twoPi),
            rotations.y.truncatingRemainder(dividingBy: twoPi),
            rotations.z.truncatingRemainder(dividingBy: twoPi)
        )
    }

    private func tierProgress(for adherence: Double, tier: CoreTier) -> Float {
        // Calculate progress within the current tier (0.0 to 1.0)
        let ranges: [CoreTier: (lower: Double, upper: Double)] = [
            .safeMode: (0.0, 0.30),
            .standby: (0.30, 0.50),
            .stabilizing: (0.50, 0.70),
            .online: (0.70, 0.90),
            .phaseLocked: (0.90, 1.0),
        ]

        guard let range = ranges[tier] else { return 0.5 }
        let rangeWidth = range.upper - range.lower
        guard rangeWidth > 0 else { return 1.0 }

        return Float((adherence - range.lower) / rangeWidth)
    }

    private func getInterpolationPresets(for tier: CoreTier) -> (lower: TierParameters, upper: TierParameters) {
        let preset = Self.tierPresets[tier]!

        // For interpolation, we use the current tier's preset
        // The tier progress handles smooth transitions within the tier
        return (preset, preset)
    }

    private func lerp(_ a: Float, _ b: Float, t: Float) -> Float {
        a + (b - a) * t
    }

    // MARK: - State Queries

    /// Returns true if the spinner is currently spinning
    var isSpinning: Bool {
        length(angularVelocity) > velocityThreshold
    }

    /// Returns the current spin speed (absolute Y velocity)
    var spinSpeed: Float {
        abs(angularVelocity.y)
    }

    /// Returns normalized spin speed (0.0 to 1.0 based on max speed)
    var normalizedSpinSpeed: Float {
        min(spinSpeed / maxSpeed, 1.0)
    }
}
