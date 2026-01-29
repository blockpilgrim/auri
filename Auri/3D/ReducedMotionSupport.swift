import SwiftUI

/// Environment key for Auri reduced motion mode.
///
/// When true, Auri displays a "calm mode" experience:
/// - Slower animation speeds
/// - Less orbital motion
/// - Fewer secondary effects
/// - State differentiation preserved via color/intensity (not motion)
private struct AuriReducedMotionKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// Whether Auri should use reduced motion mode.
    /// Automatically syncs with system Reduce Motion setting.
    var auriReducedMotion: Bool {
        get { self[AuriReducedMotionKey.self] }
        set { self[AuriReducedMotionKey.self] = newValue }
    }
}

// MARK: - Reduced Motion Configuration

/// Configuration for reduced motion mode effects.
struct ReducedMotionConfig {
    /// Multiplier for animation speeds (1.0 = normal, 0.5 = half speed)
    let animationSpeed: Float

    /// Multiplier for precession effects (0.0 = none, 1.0 = normal)
    let precessionIntensity: Float

    /// Whether to show the breathing pulse animation
    let showPulse: Bool

    /// Whether to show particle effects (trails at high adherence)
    let showParticles: Bool

    /// Whether to show ambient motes (floating dust particles)
    let showMotes: Bool

    /// Whether to show tier transition effects
    let showTierTransitions: Bool

    /// Multiplier for jitter effects (0.0 = none, 1.0 = normal)
    let jitterIntensity: Float

    /// Whether to show micro-feedback animations
    let showMicroFeedback: Bool

    // MARK: - Presets

    /// Normal mode - full effects
    static let normal = ReducedMotionConfig(
        animationSpeed: 1.0,
        precessionIntensity: 1.0,
        showPulse: true,
        showParticles: true,
        showMotes: true,
        showTierTransitions: true,
        jitterIntensity: 1.0,
        showMicroFeedback: true
    )

    /// Reduced motion mode - calm experience
    static let reduced = ReducedMotionConfig(
        animationSpeed: 0.3,
        precessionIntensity: 0.0,
        showPulse: false,
        showParticles: false,
        showMotes: false,
        showTierTransitions: false,
        jitterIntensity: 0.0,
        showMicroFeedback: false
    )
}

// MARK: - View Modifier

/// Applies reduced motion settings to the Auri view hierarchy.
struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .environment(\.auriReducedMotion, reduceMotion)
    }
}

extension View {
    /// Applies system Reduce Motion preference to Auri effects.
    func respectsReduceMotion() -> some View {
        modifier(ReducedMotionModifier())
    }
}

// MARK: - Motion Settings Provider

/// Provides motion-related settings based on accessibility preferences.
@Observable
@MainActor
final class MotionSettingsProvider {
    /// Current motion configuration
    private(set) var config: ReducedMotionConfig = .normal

    /// Whether reduced motion is enabled
    private(set) var isReducedMotionEnabled: Bool = false

    // MARK: - Updates

    /// Updates configuration based on reduce motion preference.
    /// - Parameter reduceMotion: Whether reduce motion is enabled
    func update(reduceMotion: Bool) {
        isReducedMotionEnabled = reduceMotion
        config = reduceMotion ? .reduced : .normal
    }

    // MARK: - Convenience Accessors

    /// Animation speed multiplier
    var animationSpeed: Float { config.animationSpeed }

    /// Precession intensity multiplier
    var precessionIntensity: Float { config.precessionIntensity }

    /// Whether to show pulse animation
    var showPulse: Bool { config.showPulse }

    /// Whether to show particle effects (trails at high adherence)
    var showParticles: Bool { config.showParticles }

    /// Whether to show ambient motes
    var showMotes: Bool { config.showMotes }

    /// Whether to show tier transition effects
    var showTierTransitions: Bool { config.showTierTransitions }

    /// Jitter intensity multiplier
    var jitterIntensity: Float { config.jitterIntensity }

    /// Whether to show micro-feedback
    var showMicroFeedback: Bool { config.showMicroFeedback }
}

// MARK: - State Differentiation Without Motion

/// Provides alternative state communication for reduced motion mode.
///
/// When motion is reduced, state differentiation is preserved through:
/// - Color intensity (brighter = higher adherence)
/// - Spark count (more sparks = higher adherence)
/// - Color palette (warmer colors = higher adherence)
///
/// These non-motion cues ensure Auri remains informative even
/// when animations are minimized.
struct ReducedMotionStateHints {
    /// Whether the Orb is in a "high energy" state (70%+ adherence)
    let isHighEnergy: Bool

    /// Whether the Orb is in peak state (85%+ adherence)
    let isPeakState: Bool

    /// Suggested static brightness (0.4 to 1.0)
    let staticBrightness: Float

    /// Creates hints from adherence value
    /// - Parameters:
    ///   - coreAdherence: Raw core adherence value (0.0 to 1.0)
    init(coreAdherence: Double) {
        isHighEnergy = coreAdherence >= 0.70
        isPeakState = coreAdherence >= 0.85

        // Map adherence to static brightness (no pulse, just steady brightness)
        staticBrightness = 0.4 + (Float(coreAdherence) * 0.6)
    }
}
