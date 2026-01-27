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

    /// Bloom strength: 0% = 0.3, 50% = 1.0, 100% = 1.8
    var bloomStrength: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.3, yMid: 1.0, y1: 1.8)
    }

    /// Pulse amplitude: 0% = 0.06, 50% = 0.20, 100% = 0.40
    var pulseAmplitude: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.06, yMid: 0.20, y1: 0.40)
    }

    /// Overall core glow multiplier (used to scale layer opacity/size).
    var glowMultiplier: Float {
        // Keep Safe Mode elegant, but dramatically scale at high adherence.
        lerp(0.55, 1.35, bloomStrength / 1.8)
    }

    /// At 80%+ adherence, inner core shifts toward white (max 30% at 100%).
    var innerCoreColor: UIColor {
        CoreColors.innerCoreColor(adherence: adherence)
    }

    /// Ring roughness (matte → polished).
    var ringRoughness: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.55, yMid: 0.30, y1: 0.18)
    }

    /// Coil glow intensity multiplier.
    var coilGlowIntensity: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.10, yMid: 0.45, y1: 1.00)
    }

    // MARK: - Lights

    /// Core point light intensity: 1.0 at 0% → 5.0 at 100%
    var coreLightIntensity: Float {
        lerp(1.0, 5.0, adherence)
    }

    /// Coil point light intensity: 0.3 at 0% → 1.5 at 100%
    var coilLightIntensity: Float {
        lerp(0.3, 1.5, adherence)
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
