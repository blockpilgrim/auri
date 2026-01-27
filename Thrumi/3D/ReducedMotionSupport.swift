import SwiftUI

/// Environment key for Fusion Core reduced motion mode.
///
/// When true, the Core displays a "calm mode" experience:
/// - Slower animation speeds
/// - Less precession
/// - Static glow instead of pulsing
/// - Fewer secondary effects
/// - State differentiation preserved via color/intensity (not motion)
private struct FusionCoreReducedMotionKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    /// Whether the Fusion Core should use reduced motion mode.
    /// Automatically syncs with system Reduce Motion setting.
    var fusionCoreReducedMotion: Bool {
        get { self[FusionCoreReducedMotionKey.self] }
        set { self[FusionCoreReducedMotionKey.self] = newValue }
    }
}

// MARK: - Reduced Motion Configuration

/// Configuration for reduced motion mode effects.
struct ReducedMotionConfig {
    /// Multiplier for animation speeds (1.0 = normal, 0.5 = half speed)
    let animationSpeed: Float

    /// Multiplier for precession effects (0.0 = none, 1.0 = normal)
    let precessionIntensity: Float

    /// Whether to show the reactor pulse animation
    let showPulse: Bool

    /// Multiplier for jitter effects (0.0 = none, 1.0 = normal)
    let jitterIntensity: Float

    /// Whether to show micro-feedback animations
    let showMicroFeedback: Bool

    /// Multiplier for glow transitions (higher = faster transitions)
    let glowTransitionSpeed: Float

    // MARK: - Presets

    /// Normal mode - full effects
    static let normal = ReducedMotionConfig(
        animationSpeed: 1.0,
        precessionIntensity: 1.0,
        showPulse: true,
        jitterIntensity: 1.0,
        showMicroFeedback: true,
        glowTransitionSpeed: 1.0
    )

    /// Reduced motion mode - calm experience
    static let reduced = ReducedMotionConfig(
        animationSpeed: 0.3,
        precessionIntensity: 0.0,
        showPulse: false,
        jitterIntensity: 0.0,
        showMicroFeedback: false,
        glowTransitionSpeed: 2.0 // Faster transitions = less motion
    )
}

// MARK: - View Modifier

/// Applies reduced motion settings to the Fusion Core view hierarchy.
struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .environment(\.fusionCoreReducedMotion, reduceMotion)
    }
}

extension View {
    /// Applies system Reduce Motion preference to Fusion Core effects.
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
/// - Light brightness (more glow = higher adherence)
/// - Ring roughness (shinier = higher adherence)
///
/// These non-motion cues ensure the Core remains informative even
/// when animations are minimized.
struct ReducedMotionStateHints {
    /// Whether the Core is in a "high power" state (70%+ adherence)
    let isHighPower: Bool

    /// Whether the Core is in peak state (90%+ adherence)
    let isPeakState: Bool

    /// Suggested static glow intensity (0.2 to 1.0)
    let staticGlowIntensity: Float

    /// Suggested ring shine level (0.15 to 0.4 roughness)
    let ringRoughness: Float

    /// Creates hints from normalized power value
    /// - Parameters:
    ///   - normalizedPower: Normalized power from StateInterpolator (0.0 to 1.0)
    ///   - coreAdherence: Raw core adherence value (0.0 to 1.0)
    init(normalizedPower: Float, coreAdherence: Double) {
        isHighPower = coreAdherence >= 0.70
        isPeakState = coreAdherence >= 0.90

        // Map power to static glow (no pulse, just steady brightness)
        staticGlowIntensity = 0.2 + (normalizedPower * 0.8)

        // Map power to roughness (inverted - lower roughness = shinier)
        ringRoughness = 0.4 - (normalizedPower * 0.25)
    }
}
