import Foundation

/// Monitors device thermal state and provides effect reduction recommendations.
///
/// Per BUILD-STRATEGY.md Section 6, the app should reduce effects gracefully under thermal pressure:
/// - Nominal/Fair: Full effects
/// - Serious: Reduce particle count, lower bloom (30% reduction)
/// - Critical: Minimal effects to prevent throttling (60% reduction)
@Observable
@MainActor
final class ThermalManager {
    // MARK: - State

    /// Current thermal state of the device
    private(set) var thermalState: ProcessInfo.ThermalState = .nominal

    /// Effect intensity multiplier based on thermal state (1.0 = full, 0.4 = minimal)
    var effectMultiplier: Float {
        switch thermalState {
        case .nominal, .fair:
            return 1.0
        case .serious:
            return 0.7 // 30% reduction
        case .critical:
            return 0.4 // 60% reduction
        @unknown default:
            return 1.0
        }
    }

    /// Whether effects should be reduced
    var shouldReduceEffects: Bool {
        thermalState == .serious || thermalState == .critical
    }

    /// Whether effects should be minimal (critical state)
    var shouldMinimizeEffects: Bool {
        thermalState == .critical
    }

    // MARK: - Observation

    private var observerToken: (any NSObjectProtocol)?

    // MARK: - Initialization

    init() {
        // Get initial state
        thermalState = ProcessInfo.processInfo.thermalState

        // Observe thermal state changes
        observerToken = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.updateThermalState()
            }
        }
    }

    /// Removes the thermal state observer. Call before the manager is deallocated.
    func stopObserving() {
        if let token = observerToken {
            NotificationCenter.default.removeObserver(token)
            observerToken = nil
        }
    }

    // MARK: - Updates

    private func updateThermalState() {
        thermalState = ProcessInfo.processInfo.thermalState
    }

    /// Manually refreshes the thermal state (call before intensive operations)
    func refresh() {
        updateThermalState()
    }

    // MARK: - Effect Recommendations

    /// Returns recommended bloom intensity multiplier
    var bloomMultiplier: Float {
        switch thermalState {
        case .nominal, .fair:
            return 1.0
        case .serious:
            return 0.6
        case .critical:
            return 0.3
        @unknown default:
            return 1.0
        }
    }

    /// Returns recommended particle count multiplier
    var particleMultiplier: Float {
        switch thermalState {
        case .nominal, .fair:
            return 1.0
        case .serious:
            return 0.5
        case .critical:
            return 0.2
        @unknown default:
            return 1.0
        }
    }

    /// Returns recommended animation complexity (1.0 = full, 0.0 = minimal)
    var animationComplexity: Float {
        switch thermalState {
        case .nominal:
            return 1.0
        case .fair:
            return 0.9
        case .serious:
            return 0.6
        case .critical:
            return 0.3
        @unknown default:
            return 1.0
        }
    }

    /// Returns recommended frame rate (for display link)
    var recommendedFrameRate: Int {
        switch thermalState {
        case .nominal, .fair:
            return 120 // ProMotion max
        case .serious:
            return 60
        case .critical:
            return 30
        @unknown default:
            return 120
        }
    }
}

// MARK: - Thermal State Description

extension ThermalManager {
    /// Returns a human-readable description of the current thermal state
    var thermalStateDescription: String {
        switch thermalState {
        case .nominal:
            return "Nominal"
        case .fair:
            return "Fair"
        case .serious:
            return "Serious"
        case .critical:
            return "Critical"
        @unknown default:
            return "Unknown"
        }
    }
}
