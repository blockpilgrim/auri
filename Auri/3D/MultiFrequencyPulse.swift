import Foundation

/// Multi-frequency pulse system.
///
/// Tempo is constant at all adherence levels; only amplitude changes.
struct MultiFrequencyPulse {
    private var primaryPhase: Float = 0
    private var fastPhase: Float = 0
    private var ultraFastPhase: Float = 0

    // Calm, slow breathing pulse rates.
    private let primaryHz: Float = 0.4
    private let fastHz: Float = 1.0
    private let ultraFastHz: Float = 2.5

    private let ultraFastThreshold: Float = 0.70

    struct PulseValues {
        let primary: Float
        let fast: Float
        let ultraFast: Float
    }

    mutating func update(
        deltaTime: Float,
        amplitude: Float,
        adherence: Float
    ) -> PulseValues {
        primaryPhase = wrap(primaryPhase + deltaTime * primaryHz * 2 * .pi)
        fastPhase = wrap(fastPhase + deltaTime * fastHz * 2 * .pi)
        ultraFastPhase = wrap(ultraFastPhase + deltaTime * ultraFastHz * 2 * .pi)

        // Primary pulse dominates for calm, steady breathing.
        let primary = sin(primaryPhase) * amplitude
        let fast = sin(fastPhase) * amplitude * 0.35

        let ultraT = clamp01((adherence - ultraFastThreshold) / (1.0 - ultraFastThreshold))
        let ultraFast = sin(ultraFastPhase) * amplitude * 0.18 * ultraT

        return PulseValues(primary: primary, fast: fast, ultraFast: ultraFast)
    }

    mutating func reset() {
        primaryPhase = 0
        fastPhase = 0
        ultraFastPhase = 0
    }

    private func wrap(_ radians: Float) -> Float {
        let twoPi = Float.pi * 2
        return radians.truncatingRemainder(dividingBy: twoPi)
    }

    private func clamp01(_ x: Float) -> Float {
        max(0, min(1, x))
    }
}
