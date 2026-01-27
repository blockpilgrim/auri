import Foundation

/// Identifies the distinct components of the Fusion Core for animation and material control.
enum CoreComponent: String, CaseIterable {
    // MARK: - Ring Components
    case outerRing
    case middleRing
    case innerRing
    case coils

    // MARK: - Core Glow Layers (per implementation directive)
    /// Hot white center - always visible, scales with power
    case hotCenter
    /// Inner core - always visible, shifts to white at 80%+
    case innerCore
    /// Outer glow - always visible, pulses slower
    case outerGlow
    /// Energy field 1 - visible at 30%+, rotates slowly
    case energyField1
    /// Energy field 2 - visible at 50%+, counter-rotates
    case energyField2
    /// Atmosphere - visible at 40%+, outermost halo
    case atmosphere
    /// Energy ring - horizontal torus, rotates fast
    case energyRing
}
