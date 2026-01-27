import CoreMotion
import Foundation

/// Manages device motion updates for gyroscopic precession effects on the Fusion Core.
///
/// Uses CMMotionManager to detect device tilt and orientation, which creates
/// subtle precession effects on the spinning rings.
@Observable
@MainActor
final class MotionManager {
    // MARK: - Motion State

    /// Current device pitch (forward/backward tilt) in radians
    private(set) var pitch: Float = 0

    /// Current device roll (left/right tilt) in radians
    private(set) var roll: Float = 0

    /// Reference attitude captured when tracking starts
    private var referenceAttitude: CMAttitude?

    /// Whether motion updates are currently active
    private(set) var isActive: Bool = false

    // MARK: - Private

    private let motionManager = CMMotionManager()
    private let updateInterval: TimeInterval = 1.0 / 60.0 // 60 Hz

    // MARK: - Lifecycle

    /// Starts device motion updates.
    /// Motion values are relative to the device orientation when started.
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("Device motion not available")
            return
        }

        guard !isActive else { return }

        motionManager.deviceMotionUpdateInterval = updateInterval

        // Use reference frame that accounts for device orientation
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: .main
        ) { [weak self] motion, error in
            Task { @MainActor in
                self?.handleMotionUpdate(motion, error: error)
            }
        }

        isActive = true
    }

    /// Stops device motion updates.
    func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
        isActive = false
        referenceAttitude = nil
        pitch = 0
        roll = 0
    }

    /// Resets the reference attitude to the current device orientation.
    /// Call this when the user starts interacting to establish a "neutral" position.
    func resetReference() {
        referenceAttitude = motionManager.deviceMotion?.attitude.copy() as? CMAttitude
    }

    // MARK: - Private

    private func handleMotionUpdate(_ motion: CMDeviceMotion?, error: Error?) {
        guard let motion else {
            if let error {
                print("Motion update error: \(error.localizedDescription)")
            }
            return
        }

        // Capture reference attitude on first update if not set
        if referenceAttitude == nil {
            referenceAttitude = motion.attitude.copy() as? CMAttitude
        }

        // Calculate relative attitude
        let attitude = motion.attitude
        if let reference = referenceAttitude {
            attitude.multiply(byInverseOf: reference)
        }

        // Extract pitch and roll, applying smoothing
        let smoothingFactor: Float = 0.3
        let newPitch = Float(attitude.pitch)
        let newRoll = Float(attitude.roll)

        pitch = pitch + smoothingFactor * (newPitch - pitch)
        roll = roll + smoothingFactor * (newRoll - roll)
    }
}

// MARK: - Device Motion Availability

extension MotionManager {
    /// Returns true if device motion is available on this device
    static var isAvailable: Bool {
        CMMotionManager().isDeviceMotionAvailable
    }
}
