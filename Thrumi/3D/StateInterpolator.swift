import Foundation
import simd

/// Centralized mapping of adherence state to all Fusion Core parameters.
///
/// The StateInterpolator applies a non-linear reward curve to make 80% feel near-peak,
/// then provides continuous interpolation for all physics and visual parameters.
/// This is where "feel equals feedback" comes to life.
@Observable
@MainActor
final class StateInterpolator {
    // MARK: - Input State

    /// The current adherence state driving all interpolations
    var adherenceState: AdherenceState

    // MARK: - Reward Curve Configuration

    /// Exponent for the reward curve: power = 1 - (1 - adherence)^k
    /// Higher k makes gains feel more front-loaded (80% feels closer to 100%)
    private let rewardCurveK: Float = 2.5

    // MARK: - Computed Power

    /// Normalized power after applying the reward curve (0.0–1.0)
    /// This makes 80% adherence feel near-peak and 50% feel decent
    var normalizedPower: Float {
        let adherence = Float(adherenceState.coreAdherence)
        return 1 - pow(1 - adherence, rewardCurveK)
    }

    // MARK: - Physics Parameters

    /// Maximum angular velocity in rad/s (4.0 at 0%, 12.0 at 100%)
    var maxSpeed: Float {
        lerp(4.0, 12.0, normalizedPower)
    }

    /// Damping factor per frame (0.92 = fast decay at 0%, 0.995 = slow decay at 100%)
    var damping: Float {
        lerp(0.92, 0.995, normalizedPower)
    }

    /// Wobble suppression strength (0.3 at 0%, 0.95 at 100%)
    var stabilizationAuthority: Float {
        lerp(0.3, 0.95, normalizedPower)
    }

    /// Gesture responsiveness multiplier (0.7 at 0%, 1.2 at 100%)
    var torqueMultiplier: Float {
        lerp(0.7, 1.2, normalizedPower)
    }

    // MARK: - Visual Parameters

    /// Center core emissive intensity (0.2 dim to 1.0 bright)
    var emissiveIntensity: Float {
        lerp(0.2, 1.0, normalizedPower)
    }

    /// Bloom post-process strength (0.1 minimal to 0.6 rich)
    var bloomStrength: Float {
        lerp(0.1, 0.6, normalizedPower)
    }

    /// Copper coil emissive brightness (0.3 dim to 1.0 bright)
    var coilBrightness: Float {
        lerp(0.3, 1.0, normalizedPower)
    }

    /// Ring surface roughness (0.4 matte to 0.15 polished)
    var ringRoughness: Float {
        lerp(0.4, 0.15, normalizedPower)
    }

    /// Point light intensity multiplier (0.4 dim to 1.0 bright)
    var lightIntensity: Float {
        lerp(0.4, 1.0, normalizedPower)
    }

    /// Ring alignment precision (0.5 wobbly to 1.0 perfectly concentric)
    /// At lower adherence, rings have slight misalignment "jitter"
    var ringAlignmentPrecision: Float {
        lerp(0.5, 1.0, normalizedPower)
    }

    /// Ring alignment jitter amount (inverse of precision)
    var ringAlignmentJitter: Float {
        1.0 - ringAlignmentPrecision
    }

    // MARK: - Pulse Parameters

    /// Pulse amplitude (0.05 subtle to 0.2 pronounced)
    /// Note: pulse rate is CONSTANT (not tied to adherence) per PRODUCT.md
    var pulseAmplitude: Float {
        lerp(0.05, 0.2, normalizedPower)
    }

    /// Pulse sharpness (0.3 soft sine to 0.8 sharper triangular)
    /// Higher adherence = crisper, more defined pulses
    var pulseSharpness: Float {
        lerp(0.3, 0.8, normalizedPower)
    }

    // MARK: - Tier-Specific Visual Hints

    /// Whether to show "impossible" phase-lock details (only at 90%+)
    var showPhaseLockDetails: Bool {
        adherenceState.tier == .phaseLocked
    }

    /// Whether to show occasional "field noise" (50-69% tier)
    var showFieldNoise: Bool {
        adherenceState.tier == .stabilizing
    }

    // MARK: - Initialization

    init(adherenceState: AdherenceState = .empty) {
        self.adherenceState = adherenceState
    }

    // MARK: - Convenience Methods

    /// Updates the underlying adherence state
    func update(with state: AdherenceState) {
        self.adherenceState = state
    }

    /// Linear interpolation helper
    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * t
    }
}

// MARK: - SpinnerPhysics Integration

extension SpinnerPhysics {
    /// Applies all physics parameters from the state interpolator.
    /// Call this when adherence changes for smooth continuous updates.
    func applyParameters(from interpolator: StateInterpolator) {
        self.maxSpeed = interpolator.maxSpeed
        self.damping = interpolator.damping
        self.stabilizationAuthority = interpolator.stabilizationAuthority
        self.torqueMultiplier = interpolator.torqueMultiplier
    }
}
