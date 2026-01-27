import CoreHaptics
import Foundation

/// Manages haptic feedback for the Fusion Core interactions.
///
/// Per PRODUCT.md Section 8, haptics amplify "machined precision":
/// - High adherence: crisp micro-impulses on phase-lock events and clean collisions
/// - Low adherence: softer, more damped feedback
///
/// Haptics are modulated by the current adherence state to reinforce the "feel equals feedback" philosophy.
@MainActor
final class HapticsManager {
    // MARK: - Engine State

    private var engine: CHHapticEngine?
    private var isEngineRunning: Bool = false

    // MARK: - Adherence State

    /// Current haptic intensity multiplier based on adherence (0.3 to 1.0)
    var intensityMultiplier: Float = 0.7

    /// Current haptic sharpness based on adherence (0.3 to 1.0)
    var sharpnessMultiplier: Float = 0.7

    // MARK: - Configuration

    /// Whether haptics are enabled (respects user settings)
    var isEnabled: Bool = true

    // MARK: - Initialization

    init() {
        setupEngine()
    }

    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("HapticsManager: Device does not support haptics")
            return
        }

        do {
            engine = try CHHapticEngine()
            engine?.playsHapticsOnly = true

            // Handle engine reset
            engine?.resetHandler = { [weak self] in
                Task { @MainActor in
                    self?.restartEngine()
                }
            }

            // Handle engine stopped (e.g., app backgrounded)
            engine?.stoppedHandler = { [weak self] reason in
                Task { @MainActor in
                    self?.isEngineRunning = false
                    print("HapticsManager: Engine stopped - \(reason)")
                }
            }

            try engine?.start()
            isEngineRunning = true
        } catch {
            print("HapticsManager: Failed to create engine - \(error.localizedDescription)")
        }
    }

    private func restartEngine() {
        do {
            try engine?.start()
            isEngineRunning = true
        } catch {
            print("HapticsManager: Failed to restart engine - \(error.localizedDescription)")
        }
    }

    // MARK: - State Updates

    /// Updates haptic parameters based on the state interpolator values.
    /// - Parameters:
    ///   - intensity: Normalized intensity (0.0 to 1.0)
    ///   - sharpness: Normalized sharpness (0.0 to 1.0)
    func updateParameters(intensity: Float, sharpness: Float) {
        intensityMultiplier = intensity
        sharpnessMultiplier = sharpness
    }

    // MARK: - Spin Feedback

    /// Plays haptic feedback when the user flicks to spin.
    /// Intensity scales with velocity.
    /// - Parameter velocity: The flick velocity magnitude
    func playSpinFeedback(velocity: Float) {
        guard isEnabled, isEngineRunning else { return }

        let normalizedVelocity = min(abs(velocity) / 10.0, 1.0)
        let intensity = normalizedVelocity * 0.5 * intensityMultiplier
        let sharpness = 0.6 * sharpnessMultiplier

        playTransient(intensity: intensity, sharpness: sharpness)
    }

    // MARK: - Tap Ping

    /// Plays a crisp ping when the user taps the Core.
    /// Crispness varies with adherence.
    func playTapPing() {
        guard isEnabled, isEngineRunning else { return }

        let intensity = 0.6 * intensityMultiplier
        let sharpness = 0.8 * sharpnessMultiplier

        playTransient(intensity: intensity, sharpness: sharpness)
    }

    // MARK: - Phase-Lock Pulse

    /// Plays a sharp, satisfying pulse when phase-lock state is achieved.
    /// Only appropriate at high adherence (70%+).
    func playPhaseLockPulse() {
        guard isEnabled, isEngineRunning else { return }

        // Phase-lock is a premium moment - always crisp
        let intensity: Float = 0.8
        let sharpness: Float = 1.0

        playTransient(intensity: intensity, sharpness: sharpness)
    }

    // MARK: - Micro-Feedback

    /// Plays haptic feedback for meal logging micro-feedback.
    /// - Parameter isOnTrack: Whether the meal was marked as on-track
    func playMicroFeedback(isOnTrack: Bool) {
        guard isEnabled, isEngineRunning else { return }

        if isOnTrack {
            // On-track: crisp alignment beat, intensity varies with adherence
            let intensity = 0.6 * intensityMultiplier
            let sharpness = 0.8 * sharpnessMultiplier
            playTransient(intensity: intensity, sharpness: sharpness)
        } else {
            // Off-track: soft damped pulse, always gentle
            let intensity: Float = 0.4
            let sharpness: Float = 0.3
            playTransient(intensity: intensity, sharpness: sharpness)
        }
    }

    // MARK: - Continuous Feedback (for sustained gestures)

    /// Plays subtle continuous feedback during twist gesture.
    /// - Parameter angularVelocity: Current angular velocity magnitude
    func playTwistFeedback(angularVelocity: Float) {
        guard isEnabled, isEngineRunning else { return }

        // Only play feedback at notable velocities
        guard abs(angularVelocity) > 0.5 else { return }

        let normalizedVelocity = min(abs(angularVelocity) / 5.0, 1.0)
        let intensity = normalizedVelocity * 0.3 * intensityMultiplier
        let sharpness = 0.5 * sharpnessMultiplier

        playTransient(intensity: intensity, sharpness: sharpness)
    }

    // MARK: - Low-Level Haptic Playback

    private func playTransient(intensity: Float, sharpness: Float) {
        guard let engine, isEngineRunning else { return }

        // Clamp values to valid range
        let clampedIntensity = max(0.0, min(1.0, intensity))
        let clampedSharpness = max(0.0, min(1.0, sharpness))

        // Skip very weak haptics (imperceptible)
        guard clampedIntensity > 0.1 else { return }

        let intensityParam = CHHapticEventParameter(
            parameterID: .hapticIntensity,
            value: clampedIntensity
        )
        let sharpnessParam = CHHapticEventParameter(
            parameterID: .hapticSharpness,
            value: clampedSharpness
        )

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("HapticsManager: Failed to play haptic - \(error.localizedDescription)")
        }
    }

    /// Plays a continuous haptic pattern (for sustained effects).
    /// - Parameters:
    ///   - intensity: Base intensity (0.0 to 1.0)
    ///   - sharpness: Base sharpness (0.0 to 1.0)
    ///   - duration: Duration in seconds
    private func playContinuous(intensity: Float, sharpness: Float, duration: TimeInterval) {
        guard let engine, isEngineRunning else { return }

        let clampedIntensity = max(0.0, min(1.0, intensity))
        let clampedSharpness = max(0.0, min(1.0, sharpness))

        guard clampedIntensity > 0.1 else { return }

        let intensityParam = CHHapticEventParameter(
            parameterID: .hapticIntensity,
            value: clampedIntensity
        )
        let sharpnessParam = CHHapticEventParameter(
            parameterID: .hapticSharpness,
            value: clampedSharpness
        )

        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0,
            duration: duration
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("HapticsManager: Failed to play continuous haptic - \(error.localizedDescription)")
        }
    }

    // MARK: - Engine Lifecycle

    /// Starts the haptic engine (call when app becomes active).
    func start() {
        guard !isEngineRunning else { return }
        restartEngine()
    }

    /// Stops the haptic engine (call when app enters background).
    func stop() {
        engine?.stop()
        isEngineRunning = false
    }
}

// MARK: - Hardware Capability Check

extension HapticsManager {
    /// Returns true if the device supports haptics
    static var isSupported: Bool {
        CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
}
