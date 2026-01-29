import Foundation
import CoreGraphics

/// Minimal spin physics for an interactive fidget spinner.
///
/// Uses delta-based spin tracking to avoid wrapping discontinuities.
/// Each frame produces a `spinDelta` that consumers fold into their own
/// accumulated angles, preventing jitter when multiplied by per-spark speed multipliers.
@Observable
@MainActor
final class SpinnerPhysics {
    /// Per-frame angle change from user spin. Consumers should accumulate this
    /// into their own angles rather than using an absolute spin angle.
    private(set) var spinDelta: Float = 0
    private(set) var spinVelocity: Float = 0

    var maxSpinSpeed: Float = 10
    var dampingPerFrame: Float = 0.988
    var torqueMultiplier: Float = 1.0

    private let stopThreshold: Float = 0.02

    func update(deltaTime: Float) {
        let frameScale = max(0, min(2.0, deltaTime * 60.0))
        spinVelocity *= pow(dampingPerFrame, frameScale)

        if abs(spinVelocity) < stopThreshold {
            spinVelocity = 0
        }

        spinVelocity = clamp(spinVelocity, -maxSpinSpeed, maxSpinSpeed)
        spinDelta = spinVelocity * deltaTime
    }

    func applyFlick(velocity: CGSize) {
        let v = Float(velocity.width)
        spinVelocity += v * 0.006 * torqueMultiplier
        spinVelocity = clamp(spinVelocity, -maxSpinSpeed, maxSpinSpeed)
    }

    func stop() {
        spinVelocity = 0
    }

    private func clamp(_ x: Float, _ lo: Float, _ hi: Float) -> Float {
        max(lo, min(hi, x))
    }
}
