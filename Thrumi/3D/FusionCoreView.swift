import RealityKit
import SwiftUI

/// A SwiftUI view that renders the Fusion Core 3D model using RealityKit.
///
/// The Fusion Core is a magnetically-levitated, industrial high-tech fidget spinner
/// that visualizes the user's adherence state. This view handles all gesture interactions
/// and drives the custom physics system.
struct FusionCoreView: View {
    /// The current adherence state that drives the Core's visual appearance.
    let adherenceState: AdherenceState

    // MARK: - Scene State

    @State private var scene: FusionCoreScene?
    @State private var physics = SpinnerPhysics()
    @State private var motionManager = MotionManager()

    // MARK: - Camera State

    @State private var cameraAngle: Float = 0
    @State private var cameraElevation: Float = 0.3

    // MARK: - Gesture State

    @State private var lastDragValue: CGSize = .zero
    @State private var isDragging: Bool = false
    @State private var dragStartTime: Date = .now
    @State private var lastDragLocation: CGPoint = .zero
    @State private var velocityTracker = VelocityTracker()

    // MARK: - Animation State

    @State private var displayLink: DisplayLinkController?
    @State private var pingAnimationProgress: Float = 1.0 // 1.0 = complete, 0.0 = just started
    @State private var isPinging: Bool = false

    var body: some View {
        GeometryReader { geometry in
            RealityView { content in
                // Create and add the Fusion Core scene
                let fusionCore = await FusionCoreScene.create()
                content.add(fusionCore.rootEntity)

                // Add ambient lighting
                let ambientLight = createAmbientLight()
                content.add(ambientLight)

                // Store scene reference for updates
                await MainActor.run {
                    scene = fusionCore
                    startPhysicsLoop()
                    motionManager.startUpdates()
                }
            } update: { content in
                // Update visual state based on adherence
                updateCoreAppearance()
            }
            .gesture(spinGesture)
            .gesture(twistGesture)
            .gesture(tapGesture)
            .ignoresSafeArea()
            .onDisappear {
                stopPhysicsLoop()
                motionManager.stopUpdates()
            }
            .onChange(of: adherenceState) { _, newState in
                physics.updateParameters(for: newState)
            }
        }
    }

    // MARK: - Gestures

    /// Flick/drag gesture for spinning the Core
    private var spinGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                let now = Date.now

                if !isDragging {
                    // Gesture started
                    isDragging = true
                    dragStartTime = now
                    lastDragLocation = value.startLocation
                    lastDragValue = .zero
                    velocityTracker.reset()
                    motionManager.resetReference()
                }

                // Calculate delta for camera rotation (slow drag = camera orbit)
                let delta = CGSize(
                    width: value.translation.width - lastDragValue.width,
                    height: value.translation.height - lastDragValue.height
                )

                // Track position for velocity calculation
                velocityTracker.addSample(position: value.location, time: now)

                // Get current velocity estimate
                let velocity = velocityTracker.velocity
                let speed = sqrt(velocity.width * velocity.width + velocity.height * velocity.height)

                if speed < 300 {
                    // Slow drag: orbit camera
                    cameraAngle += Float(delta.width) * 0.008
                    cameraElevation = max(-0.8, min(0.8, cameraElevation - Float(delta.height) * 0.004))
                } else {
                    // Fast drag: apply torque continuously
                    physics.applyFlickTorque(velocity: CGSize(width: delta.width * 2, height: delta.height * 2))
                }

                lastDragValue = value.translation
                lastDragLocation = value.location
            }
            .onEnded { _ in
                isDragging = false

                // Calculate final velocity for flick
                let velocity = velocityTracker.velocity
                let speed = sqrt(velocity.width * velocity.width + velocity.height * velocity.height)

                // Only apply flick if it was a fast gesture
                if speed > 200 {
                    physics.applyFlickTorque(velocity: velocity)
                }

                lastDragValue = .zero
                velocityTracker.reset()
            }
    }

    /// Two-finger rotation gesture for precise spin control
    private var twistGesture: some Gesture {
        RotationGesture()
            .onChanged { angle in
                // Direct velocity control during twist
                let angularVelocity = Float(angle.radians) * 3.0
                physics.setYawVelocity(angularVelocity)
            }
            .onEnded { _ in
                // Let physics continue with current velocity
            }
    }

    /// Tap gesture for coil ping effect
    private var tapGesture: some Gesture {
        TapGesture()
            .onEnded { _ in
                triggerPing()
            }
    }

    // MARK: - Physics Loop

    private func startPhysicsLoop() {
        displayLink = DisplayLinkController { deltaTime in
            Task { @MainActor in
                updatePhysics(deltaTime: deltaTime)
            }
        }
        displayLink?.start()
    }

    private func stopPhysicsLoop() {
        displayLink?.stop()
        displayLink = nil
    }

    private func updatePhysics(deltaTime: Float) {
        guard let scene else { return }

        // Apply device motion precession
        if motionManager.isActive && physics.isSpinning {
            physics.applyPrecession(pitch: motionManager.pitch, roll: motionManager.roll)
            scene.applyPrecessionWobble(
                pitch: motionManager.pitch,
                roll: motionManager.roll,
                intensity: physics.normalizedSpinSpeed
            )
        }

        // Update physics simulation
        physics.update(deltaTime: deltaTime)

        // Apply physics state to 3D entities
        scene.applyRingRotations(physics.ringRotations)

        // Update camera rotation
        scene.rootEntity.transform.rotation = simd_quatf(angle: -cameraAngle, axis: [0, 1, 0])
            * simd_quatf(angle: -cameraElevation, axis: [1, 0, 0])

        // Update ping animation
        if isPinging {
            pingAnimationProgress += deltaTime * 3.0 // 0.33 second animation
            if pingAnimationProgress >= 1.0 {
                pingAnimationProgress = 1.0
                isPinging = false
                let baseIntensity = Float(0.3 + applyRewardCurve(adherenceState.coreAdherence) * 0.7) * 0.8
                scene.resetCoilPing(to: baseIntensity)
            }
        }
    }

    // MARK: - Scene Setup

    private func createAmbientLight() -> Entity {
        let light = Entity()
        light.name = "AmbientLight"

        // Directional light for key lighting
        var directionalLight = DirectionalLightComponent()
        directionalLight.color = .init(white: 0.9, alpha: 1.0)
        directionalLight.intensity = 1500

        light.components.set(directionalLight)
        light.transform.rotation = simd_quatf(angle: -.pi / 4, axis: [1, 0, 0])

        return light
    }

    // MARK: - State Updates

    private func updateCoreAppearance() {
        guard let scene else { return }

        // Map adherence to visual parameters using the reward curve
        let power = applyRewardCurve(adherenceState.coreAdherence)

        // Update emissive intensity (center glow and coils)
        let glowIntensity = Float(0.3 + power * 0.7)
        scene.setEmissiveIntensity(glowIntensity, for: .center)

        // Only update coils if not pinging
        if !isPinging {
            scene.setEmissiveIntensity(glowIntensity * 0.8, for: .coils)
        }

        // Update light intensity
        scene.setLightIntensity(Float(0.4 + power * 0.6))

        // Update ring roughness (higher adherence = shinier)
        let roughness = Float(0.4 - power * 0.25)
        scene.setMetallicRoughness(roughness, for: .outerRing)
        scene.setMetallicRoughness(roughness * 0.9, for: .middleRing)
        scene.setMetallicRoughness(roughness * 0.8, for: .innerRing)
    }

    // MARK: - Visual Effects

    private func triggerPing() {
        guard let scene, !isPinging else { return }

        isPinging = true
        pingAnimationProgress = 0.0
        scene.triggerCoilPing()
        physics.addPingImpulse()
    }

    /// Applies the reward curve to make 80% feel awesome.
    /// power = 1 - (1 - adherence)^k where k ~ 2.5
    private func applyRewardCurve(_ adherence: Double) -> Double {
        let k = 2.5
        return 1 - pow(1 - adherence, k)
    }
}

// MARK: - Display Link Controller

/// Wrapper around CADisplayLink for driving the physics update loop.
@MainActor
final class DisplayLinkController {
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private let onUpdate: (Float) -> Void

    init(onUpdate: @escaping (Float) -> Void) {
        self.onUpdate = onUpdate
    }

    func start() {
        displayLink = CADisplayLink(target: DisplayLinkTarget(handler: { [weak self] link in
            self?.handleDisplayLink(link)
        }), selector: #selector(DisplayLinkTarget.handleDisplayLink(_:)))

        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 60, maximum: 120, preferred: 120)
        displayLink?.add(to: .main, forMode: .common)
        lastTimestamp = 0
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func handleDisplayLink(_ link: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = link.timestamp
            return
        }

        let deltaTime = Float(link.timestamp - lastTimestamp)
        lastTimestamp = link.timestamp

        // Cap delta time to prevent physics explosions after app pause
        let cappedDelta = min(deltaTime, 1.0 / 30.0)
        onUpdate(cappedDelta)
    }
}

/// Helper class to allow CADisplayLink callback (requires @objc selector)
private class DisplayLinkTarget {
    let handler: (CADisplayLink) -> Void

    init(handler: @escaping (CADisplayLink) -> Void) {
        self.handler = handler
    }

    @objc func handleDisplayLink(_ link: CADisplayLink) {
        handler(link)
    }
}

// MARK: - Velocity Tracker

/// Tracks touch positions over time to calculate velocity for flick gestures.
struct VelocityTracker {
    private struct Sample {
        let position: CGPoint
        let time: Date
    }

    private var samples: [Sample] = []
    private let maxSamples = 5
    private let maxAge: TimeInterval = 0.1 // Only consider samples from last 100ms

    /// Current velocity estimate in points per second
    var velocity: CGSize {
        // Remove old samples
        let now = Date.now
        let recentSamples = samples.filter { now.timeIntervalSince($0.time) < maxAge }

        guard recentSamples.count >= 2 else {
            return .zero
        }

        // Calculate velocity from first to last recent sample
        let first = recentSamples.first!
        let last = recentSamples.last!

        let dt = last.time.timeIntervalSince(first.time)
        guard dt > 0.001 else { return .zero }

        let dx = last.position.x - first.position.x
        let dy = last.position.y - first.position.y

        return CGSize(width: dx / dt, height: dy / dt)
    }

    mutating func addSample(position: CGPoint, time: Date) {
        samples.append(Sample(position: position, time: time))

        // Keep only recent samples
        if samples.count > maxSamples {
            samples.removeFirst()
        }
    }

    mutating func reset() {
        samples.removeAll()
    }
}

// MARK: - Previews

#Preview("Phase-Locked (100%)") {
    FusionCoreView(adherenceState: AdherenceState(
        todayAdherence: 1.0,
        rolling7Adherence: 1.0,
        rolling30Adherence: 1.0
    ))
    .background(Color.black)
}

#Preview("Online (80%)") {
    FusionCoreView(adherenceState: AdherenceState(
        todayAdherence: 0.8,
        rolling7Adherence: 0.8,
        rolling30Adherence: 0.8
    ))
    .background(Color.black)
}

#Preview("Stabilizing (60%)") {
    FusionCoreView(adherenceState: AdherenceState(
        todayAdherence: 0.6,
        rolling7Adherence: 0.6,
        rolling30Adherence: 0.6
    ))
    .background(Color.black)
}

#Preview("Safe Mode (20%)") {
    FusionCoreView(adherenceState: AdherenceState(
        todayAdherence: 0.2,
        rolling7Adherence: 0.2,
        rolling30Adherence: 0.2
    ))
    .background(Color.black)
}
