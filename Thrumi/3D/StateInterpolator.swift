import Foundation
import simd
import UIKit

/// Centralized mapping of adherence (0–1) to Fusion Core visual/interaction parameters.
@Observable
@MainActor
final class StateInterpolator {
    var adherenceState: AdherenceState
    var adherence: Float {
        Float(adherenceState.coreAdherence)
    }

    // MARK: - Visual

    /// Bloom strength: 0% = 0.5, 50% = 1.4, 100% = 2.5 (boosted for more glow).
    var bloomStrength: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.5, yMid: 1.4, y1: 2.5)
    }

    /// Pulse amplitude: 0% = 0.08, 50% = 0.28, 100% = 0.55 (boosted for more dramatic pulse).
    var pulseAmplitude: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.08, yMid: 0.28, y1: 0.55)
    }

    /// Overall core glow multiplier (used to scale layer opacity/size).
    var glowMultiplier: Float {
        // Keep Safe Mode elegant, but dramatically scale at high adherence.
        // Boosted range for more dramatic glow.
        lerp(0.65, 1.6, bloomStrength / 2.5)
    }

    /// At 80%+ adherence, inner core shifts toward white (max 30% at 100%).
    var innerCoreColor: UIColor {
        CoreColors.innerCoreColor(adherence: adherence)
    }

    /// Ring roughness (matte → polished).
    var ringRoughness: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.55, yMid: 0.30, y1: 0.18)
    }

    /// Coil glow intensity multiplier (boosted for more dramatic effect).
    var coilGlowIntensity: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.20, yMid: 0.60, y1: 1.25)
    }

    // MARK: - Lights

    /// Core point light intensity: 1.5 at 0% → 8.0 at 100% (boosted for more glow).
    var coreLightIntensity: Float {
        lerp(1.5, 8.0, adherence)
    }

    /// Coil point light intensity: 0.5 at 0% → 2.5 at 100% (boosted for more glow).
    var coilLightIntensity: Float {
        lerp(0.5, 2.5, adherence)
    }

    // MARK: - Particles

    var sparkIntensity: Float {
        intensity(after: 0.20)
    }

    var arcIntensity: Float {
        intensity(after: 0.50)
    }

    var flashIntensity: Float {
        intensity(after: 0.60)
    }

    // MARK: - Core Layer Visibility

    var showEnergyField1: Bool { adherence >= 0.30 }
    var showAtmosphere: Bool { adherence >= 0.40 }
    var showEnergyField2: Bool { adherence >= 0.50 }

    // MARK: - Interaction/Spin

    /// Max spin speed scales with adherence.
    var maxSpinSpeed: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 4.0, yMid: 10.0, y1: 18.0)
    }

    /// Damping per frame (tuned for a satisfying decay). Higher adherence = longer spin.
    var spinDampingPerFrame: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.972, yMid: 0.988, y1: 0.996)
    }

    var torqueMultiplier: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.65, yMid: 0.95, y1: 1.25)
    }

    // MARK: - Haptics

    var hapticIntensity: Float {
        lerp(0.3, 1.0, adherence)
    }

    var hapticSharpness: Float {
        lerp(0.3, 1.0, adherence)
    }

    // MARK: - Initialization

    init(adherenceState: AdherenceState = .empty) {
        self.adherenceState = adherenceState
    }

    // MARK: - Convenience Methods

    func update(with state: AdherenceState) {
        self.adherenceState = state
    }

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * clamp01(t)
    }

    private func piecewiseLerp(x: Float, xMid: Float, y0: Float, yMid: Float, y1: Float) -> Float {
        if x <= xMid {
            return lerp(y0, yMid, x / max(0.0001, xMid))
        } else {
            return lerp(yMid, y1, (x - xMid) / max(0.0001, 1.0 - xMid))
        }
    }

    private func intensity(after threshold: Float) -> Float {
        guard adherence > threshold else { return 0 }
        return clamp01((adherence - threshold) / (1.0 - threshold))
    }

    private func clamp01(_ x: Float) -> Float {
        max(0, min(1, x))
    }
}
