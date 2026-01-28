import Foundation
import simd
import UIKit

/// Centralized mapping of adherence (0–1) to Orb of Wisps visual/interaction parameters.
///
/// Replaces Fusion Core parameters with wisp-specific values:
/// - wispCount: Number of wisps to display
/// - baseOrbitSpeed: Base orbital speed multiplier
/// - wispBrightness: Brightness of wisps
/// - colorPalette: Color palette for current adherence level
/// - breathingAmplitude: Scale pulse amplitude for wisp "breathing"
/// - showTrails: Whether to show particle trails (high adherence only)
@Observable
@MainActor
final class StateInterpolator {
    var adherenceState: AdherenceState

    var adherence: Float {
        Float(adherenceState.coreAdherence)
    }

    // MARK: - Wisp Count

    /// Number of wisps to display based on adherence.
    ///
    /// | Adherence | Count |
    /// |-----------|-------|
    /// | 0-20%     | 3-5   |
    /// | 20-50%    | 6-12  |
    /// | 50-80%    | 12-22 |
    /// | 80-100%   | 22-30 |
    var wispCount: Int {
        switch adherence {
        case 0..<0.2:
            return Int(lerp(3, 5, adherence / 0.2))
        case 0.2..<0.5:
            return Int(lerp(6, 12, (adherence - 0.2) / 0.3))
        case 0.5..<0.8:
            return Int(lerp(12, 22, (adherence - 0.5) / 0.3))
        default:
            return Int(lerp(22, 30, (adherence - 0.8) / 0.2))
        }
    }

    // MARK: - Orbital Speed

    /// Base orbital speed multiplier.
    /// 0% = slow drift, 50% = moderate, 100% = energetic
    var baseOrbitSpeed: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.3, yMid: 0.7, y1: 1.2)
    }

    // MARK: - Brightness

    /// Wisp brightness multiplier (0.4 at 0%, 1.0 at 100%).
    var wispBrightness: Float {
        lerp(0.4, 1.0, adherence)
    }

    // MARK: - Color Palette

    /// Color palette for current adherence level.
    var colorPalette: [UIColor] {
        WispColors.palette(for: adherence)
    }

    // MARK: - Breathing Animation

    /// Breathing/pulse amplitude for wisp scale animation.
    /// Subtle at low adherence, more pronounced at high.
    var breathingAmplitude: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.02, yMid: 0.06, y1: 0.12)
    }

    // MARK: - Pulse Amplitude (for MultiFrequencyPulse)

    /// Pulse amplitude passed to the pulse system.
    var pulseAmplitude: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.08, yMid: 0.20, y1: 0.40)
    }

    // MARK: - Trails (Future Enhancement)

    /// Whether to show particle trails (70%+ adherence).
    var showTrails: Bool {
        adherence >= 0.7
    }

    // MARK: - Interaction/Spin

    /// Max spin speed scales with adherence.
    /// Higher adherence = can spin faster and longer.
    var maxSpinSpeed: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 4.0, yMid: 10.0, y1: 18.0)
    }

    /// Damping per frame. Higher adherence = longer spin persistence.
    var spinDampingPerFrame: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.972, yMid: 0.988, y1: 0.996)
    }

    /// Torque multiplier for flick response.
    var torqueMultiplier: Float {
        piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.65, yMid: 0.95, y1: 1.25)
    }

    // MARK: - Haptics

    /// Haptic intensity multiplier (softer at low, crisper at high).
    var hapticIntensity: Float {
        lerp(0.3, 1.0, adherence)
    }

    /// Haptic sharpness multiplier.
    var hapticSharpness: Float {
        lerp(0.3, 1.0, adherence)
    }

    // MARK: - Initialization

    init(adherenceState: AdherenceState = .empty) {
        self.adherenceState = adherenceState
    }

    // MARK: - Update

    func update(with state: AdherenceState) {
        self.adherenceState = state
    }

    // MARK: - Interpolation Helpers

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

    private func clamp01(_ x: Float) -> Float {
        max(0, min(1, x))
    }
}
