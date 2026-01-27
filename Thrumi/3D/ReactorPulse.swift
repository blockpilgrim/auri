import Foundation

/// Generates the reactor pulse animation for the Fusion Core center glow.
///
/// Per PRODUCT.md, the Core has a slow, steady "power pulse" that suggests a running system:
/// - Pulse RATE is CONSTANT (not tied to adherence) to avoid "heart rate" associations
/// - Pulse AMPLITUDE and SHARPNESS vary with adherence
///
/// The pulse is purely visual—a gentle emissive swell that makes the Core feel alive.
struct ReactorPulse {
    // MARK: - Phase Tracking

    /// Current phase of the pulse cycle (0 to 2π)
    private var phase: Float = 0

    // MARK: - Configuration

    /// Pulse frequency in Hz (constant, slow, calming)
    /// 0.5 Hz = one full cycle every 2 seconds
    let frequency: Float = 0.5

    // MARK: - Update

    /// Updates the pulse phase and returns the current pulse value.
    ///
    /// - Parameters:
    ///   - deltaTime: Time since last update in seconds
    ///   - amplitude: Current pulse amplitude (from StateInterpolator, varies with adherence)
    ///   - sharpness: Current pulse sharpness (from StateInterpolator, varies with adherence)
    /// - Returns: Pulse value in range [-amplitude, +amplitude], centered at 0
    mutating func update(deltaTime: Float, amplitude: Float, sharpness: Float) -> Float {
        // Advance phase
        phase += deltaTime * frequency * 2 * .pi

        // Wrap phase to prevent float overflow after long sessions
        if phase > 2 * .pi {
            phase -= 2 * .pi
        }

        // Generate base sine wave
        let rawPulse = sin(phase)

        // Shape the wave based on sharpness
        // At low sharpness (0.3), wave stays smooth and sinusoidal
        // At high sharpness (0.8), wave becomes more triangular/peaked
        let shapedPulse = shapeWave(rawPulse, sharpness: sharpness)

        return shapedPulse * amplitude
    }

    /// Returns the current pulse value without advancing time.
    /// Useful for getting the pulse value at any point in the frame.
    func currentValue(amplitude: Float, sharpness: Float) -> Float {
        let rawPulse = sin(phase)
        let shapedPulse = shapeWave(rawPulse, sharpness: sharpness)
        return shapedPulse * amplitude
    }

    /// Shapes the wave to be more triangular at higher sharpness values.
    private func shapeWave(_ raw: Float, sharpness: Float) -> Float {
        // Use power function to reshape the wave
        // sharpness 0.3 → exponent ~1.25 (gentle shaping)
        // sharpness 0.8 → exponent ~0.77 (sharper peaks)
        let exponent = 1.0 / (sharpness + 0.5)

        // Preserve sign while shaping magnitude
        let sign: Float = raw >= 0 ? 1 : -1
        let magnitude = pow(abs(raw), exponent)

        return sign * magnitude
    }

    /// Resets the pulse phase (e.g., on app resume)
    mutating func reset() {
        phase = 0
    }

    /// Returns whether the pulse is currently in its "up" phase (above zero)
    var isInUpPhase: Bool {
        sin(phase) >= 0
    }

    /// Returns the normalized phase position (0 to 1 through the cycle)
    var normalizedPhase: Float {
        phase / (2 * .pi)
    }
}

// MARK: - Pulse Application

extension ReactorPulse {
    /// Calculates the emissive intensity with pulse applied.
    ///
    /// - Parameters:
    ///   - baseIntensity: The base emissive intensity from StateInterpolator
    ///   - pulseValue: The current pulse value (output from `update`)
    /// - Returns: Final emissive intensity with pulse modulation
    static func applyToEmissive(baseIntensity: Float, pulseValue: Float) -> Float {
        // Pulse modulates around the base intensity
        // At base 0.5 with pulse value 0.1: ranges 0.4 to 0.6
        // Clamp to valid range
        return max(0.0, min(1.0, baseIntensity + pulseValue))
    }

    /// Calculates the light intensity with pulse applied.
    ///
    /// - Parameters:
    ///   - baseIntensity: The base light intensity from StateInterpolator
    ///   - pulseValue: The current pulse value (output from `update`)
    /// - Returns: Final light intensity with pulse modulation
    static func applyToLight(baseIntensity: Float, pulseValue: Float) -> Float {
        // Light pulses more subtly than emissive (50% of pulse effect)
        return max(0.0, min(1.0, baseIntensity + pulseValue * 0.5))
    }
}
