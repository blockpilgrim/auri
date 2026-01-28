import CoreMotion
import RealityKit
import SwiftUI
import UIKit

/// Renders the Orb of Wisps 3D experience.
///
/// A magical orb with orbiting spirit-like wisps that respond to adherence state.
/// Rich interactivity: flick to spin, tap to scatter, double-tap for sparkle burst,
/// long press to attract, pinch to breathe, twist to tilt, shake for chaos.
struct WispOrbView: View {
    let adherenceState: AdherenceState

    var adherenceEngine: AdherenceEngine?
    var hapticsManager: HapticsManager?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scene: WispOrbScene?
    @State private var physics = SpinnerPhysics()
    @State private var stateInterpolator = StateInterpolator()
    @State private var pulseSystem = MultiFrequencyPulse()
    @State private var thermalManager = ThermalManager()
    @State private var motionSettings = MotionSettingsProvider()
    @State private var displayLink: DisplayLinkController?
    @State private var currentTime: TimeInterval = 0

    @State private var velocityTracker = VelocityTracker()
    @State private var isDragging: Bool = false

    // Optional external trigger for haptics-only micro-feedback.
    @State private var pendingMicroFeedback: Bool? = nil

    // MARK: - Gesture State

    @State private var pinchScale: CGFloat = 1.0
    @State private var lastPinchScale: CGFloat = 1.0
    @State private var rotationAngle: Angle = .zero
    @State private var lastRotationAngle: Angle = .zero
    @State private var isLongPressing: Bool = false
    @State private var longPressLocation: CGPoint = .zero
    @State private var lastTapTime: Date = .distantPast
    @State private var tapCount: Int = 0

    // MARK: - Motion Detection

    @State private var motionManager: CMMotionManager?
    @State private var lastAcceleration: CMAcceleration?

    var body: some View {
        GeometryReader { geometry in
            RealityView { content in
                let wispOrb = await WispOrbScene.create()
                content.add(wispOrb.rootEntity)

                await MainActor.run {
                    scene = wispOrb

                    stateInterpolator.update(with: adherenceState)
                    applyPhysicsParameters()

                    motionSettings.update(reduceMotion: reduceMotion)

                    hapticsManager?.updateParameters(
                        intensity: stateInterpolator.hapticIntensity,
                        sharpness: stateInterpolator.hapticSharpness
                    )

                    startLoopIfNeeded()
                    startShakeDetection()
                }
            } update: { _ in
                // Updates are driven by CADisplayLink.
            }
            .gesture(combinedGestures(in: geometry.size))
            .ignoresSafeArea()
            .onDisappear {
                stopLoop()
                stopShakeDetection()
                thermalManager.stopObserving()
            }
            .onChange(of: adherenceState) { _, newState in
                stateInterpolator.update(with: newState)
                applyPhysicsParameters()

                hapticsManager?.updateParameters(
                    intensity: stateInterpolator.hapticIntensity,
                    sharpness: stateInterpolator.hapticSharpness
                )
            }
            .onChange(of: reduceMotion) { _, newValue in
                motionSettings.update(reduceMotion: newValue)
            }
        }
    }

    // MARK: - External micro-feedback

    func triggerMicroFeedback(isOnTrack: Bool) {
        pendingMicroFeedback = isOnTrack
    }

    // MARK: - Combined Gestures

    private func combinedGestures(in size: CGSize) -> some Gesture {
        // Layer gestures for rich interactivity
        SimultaneousGesture(
            SimultaneousGesture(
                spinAndTapGesture(in: size),
                longPressGesture(in: size)
            ),
            SimultaneousGesture(
                pinchGesture,
                rotationGesture
            )
        )
    }

    // MARK: - Spin & Tap Gesture

    private func spinAndTapGesture(in size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let now = Date.now

                // Detect tap vs drag
                if !isDragging {
                    isDragging = true
                    velocityTracker.reset()
                }

                velocityTracker.addSample(position: value.location, time: now)

                let v = velocityTracker.velocity
                let speed = sqrt(v.width * v.width + v.height * v.height)

                // Apply spin for fast movement
                if speed > 80 {
                    physics.applyFlick(velocity: v)

                    // Ripple effect as finger moves through
                    if let scene {
                        let scenePoint = screenToScenePoint(value.location, in: size)
                        scene.triggerRipple(at: scenePoint)
                    }
                }
            }
            .onEnded { value in
                let now = Date.now
                isDragging = false

                let v = velocityTracker.velocity
                let speed = sqrt(v.width * v.width + v.height * v.height)

                // Fast flick = spin
                if speed > 120 {
                    physics.applyFlick(velocity: v)
                    hapticsManager?.playSpinFeedback(velocity: Float(speed) / 800.0)
                }
                // Slow/no movement = tap
                else if speed < 50 {
                    let timeSinceLastTap = now.timeIntervalSince(lastTapTime)

                    if timeSinceLastTap < 0.3 {
                        // Double tap - sparkle burst!
                        tapCount = 0
                        scene?.triggerDoubleTapBurst()
                        hapticsManager?.playPhaseLockPulse()
                    } else {
                        // Single tap - scatter
                        tapCount = 1
                        scene?.triggerTapScatter()
                        hapticsManager?.playTapPing()
                    }

                    lastTapTime = now
                }

                velocityTracker.reset()
            }
    }

    // MARK: - Long Press Gesture

    private func longPressGesture(in size: CGSize) -> some Gesture {
        LongPressGesture(minimumDuration: 0.3)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                switch value {
                case .first(true):
                    // Long press started
                    isLongPressing = true
                    hapticsManager?.playTapPing()

                case .second(true, let drag):
                    // Dragging while long pressing - attract to finger
                    if let drag, let scene {
                        longPressLocation = drag.location
                        let scenePoint = screenToScenePoint(drag.location, in: size)
                        scene.setAttractionPoint(scenePoint)
                    }

                default:
                    break
                }
            }
            .onEnded { _ in
                // Release attraction
                isLongPressing = false
                scene?.setAttractionPoint(nil)
            }
    }

    // MARK: - Pinch Gesture

    private var pinchGesture: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                let combinedScale = lastPinchScale * scale
                pinchScale = combinedScale
                scene?.setPinchScale(Float(combinedScale))

                // Haptic feedback at scale thresholds
                if abs(combinedScale - 1.0) > 0.1 {
                    hapticsManager?.playTwistFeedback(angularVelocity: Float(abs(scale - 1.0) * 5))
                }
            }
            .onEnded { _ in
                lastPinchScale = 1.0
                pinchScale = 1.0
                scene?.releasePinchScale()
            }
    }

    // MARK: - Rotation Gesture

    private var rotationGesture: some Gesture {
        RotationGesture()
            .onChanged { angle in
                let combinedAngle = lastRotationAngle + angle
                rotationAngle = combinedAngle
                scene?.setTwistAngle(Float(combinedAngle.radians))

                // Haptic feedback during rotation
                if abs(angle.degrees) > 5 {
                    hapticsManager?.playTwistFeedback(angularVelocity: Float(abs(angle.degrees) / 30))
                }
            }
            .onEnded { _ in
                lastRotationAngle = .zero
                rotationAngle = .zero
                scene?.releaseTwist()
            }
    }

    // MARK: - Shake Detection

    private func startShakeDetection() {
        guard !reduceMotion else { return }

        let manager = CMMotionManager()
        motionManager = manager

        guard manager.isAccelerometerAvailable else { return }

        // Reduced frequency (5Hz instead of 10Hz) - shake detection doesn't need high precision
        manager.accelerometerUpdateInterval = 0.2
        manager.startAccelerometerUpdates(to: .main) { [self] data, _ in
            guard let data else { return }

            if let last = lastAcceleration {
                let dx = data.acceleration.x - last.x
                let dy = data.acceleration.y - last.y
                let dz = data.acceleration.z - last.z
                let deltaSq = dx * dx + dy * dy + dz * dz

                // Shake threshold (squared to avoid sqrt)
                if deltaSq > 2.25 { // 1.5^2
                    let delta = sqrt(deltaSq)
                    // Direct call - we're already on main thread
                    scene?.triggerShakeChaos(intensity: Float(min(delta / 2.0, 1.5)))
                    hapticsManager?.playSpinFeedback(velocity: Float(delta / 3.0))
                }
            }

            lastAcceleration = data.acceleration
        }
    }

    private func stopShakeDetection() {
        motionManager?.stopAccelerometerUpdates()
        motionManager = nil
    }

    // MARK: - Coordinate Conversion

    private func screenToScenePoint(_ screenPoint: CGPoint, in size: CGSize) -> SIMD3<Float> {
        // Convert screen coordinates to normalized coordinates (-1 to 1)
        let nx = Float((screenPoint.x / size.width) * 2 - 1) * 0.03
        let ny = Float((1 - screenPoint.y / size.height) * 2 - 1) * 0.03

        // Simple projection to scene space (approximate)
        return SIMD3<Float>(nx, 0, ny)
    }

    // MARK: - Loop

    private func startLoopIfNeeded() {
        guard displayLink == nil else { return }

        displayLink = DisplayLinkController { deltaTime in
            // DisplayLink already fires on main thread; avoid Task overhead.
            tick(deltaTime: deltaTime)
        }
        displayLink?.start()
    }

    private func stopLoop() {
        displayLink?.stop()
        displayLink = nil
    }

    private func tick(deltaTime: Float) {
        guard let scene else { return }

        // Consume pending micro-feedback.
        if let engine = adherenceEngine, let isOnTrack = engine.pendingMicroFeedback {
            hapticsManager?.playMicroFeedback(isOnTrack: isOnTrack)
            if isOnTrack {
                scene.triggerOnTrackFeedback()
            } else {
                scene.triggerOffTrackFeedback()
            }
            engine.clearMicroFeedback()
        }
        if let isOnTrack = pendingMicroFeedback {
            hapticsManager?.playMicroFeedback(isOnTrack: isOnTrack)
            if isOnTrack {
                scene.triggerOnTrackFeedback()
            } else {
                scene.triggerOffTrackFeedback()
            }
            pendingMicroFeedback = nil
        }

        currentTime += Double(deltaTime)

        // Interactive spin is real-time; reduced-motion affects secondary animation only.
        physics.update(deltaTime: deltaTime)

        let motionConfig = motionSettings.config
        let adherence = stateInterpolator.adherence

        let amplitude: Float = motionConfig.showPulse ? (stateInterpolator.pulseAmplitude * thermalManager.effectMultiplier) : 0
        let pulseValues = pulseSystem.update(deltaTime: deltaTime, amplitude: amplitude, adherence: adherence)

        // Use primary pulse for breathing animation.
        let breathingPulse = pulseValues.primary

        scene.update(
            interpolator: stateInterpolator,
            spinAngle: physics.spinAngle,
            deltaTime: deltaTime * motionConfig.animationSpeed,
            breathingPulse: breathingPulse
        )
    }

    private func applyPhysicsParameters() {
        physics.maxSpinSpeed = stateInterpolator.maxSpinSpeed
        physics.dampingPerFrame = stateInterpolator.spinDampingPerFrame
        physics.torqueMultiplier = stateInterpolator.torqueMultiplier
    }
}

// MARK: - Display Link Controller

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

        let cappedDelta = min(deltaTime, 1.0 / 30.0)
        onUpdate(cappedDelta)
    }
}

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

struct VelocityTracker {
    private struct Sample {
        let position: CGPoint
        let timestamp: CFTimeInterval
    }

    private var samples: [Sample] = []
    private let maxSamples = 4

    var velocity: CGSize {
        guard samples.count >= 2 else { return .zero }

        let now = CACurrentMediaTime()
        let maxAge: CFTimeInterval = 0.1

        // Find first valid sample (not too old)
        var firstIdx = 0
        while firstIdx < samples.count - 1 && (now - samples[firstIdx].timestamp) > maxAge {
            firstIdx += 1
        }

        guard firstIdx < samples.count - 1 else { return .zero }

        let first = samples[firstIdx]
        let last = samples[samples.count - 1]
        let dt = last.timestamp - first.timestamp

        guard dt > 0.001 else { return .zero }

        let dx = last.position.x - first.position.x
        let dy = last.position.y - first.position.y

        return CGSize(width: dx / dt, height: dy / dt)
    }

    mutating func addSample(position: CGPoint, time: Date) {
        let timestamp = CACurrentMediaTime()
        samples.append(Sample(position: position, timestamp: timestamp))

        if samples.count > maxSamples {
            samples.removeFirst()
        }
    }

    mutating func reset() {
        samples.removeAll(keepingCapacity: true)
    }
}

// MARK: - Previews

#Preview("Peak (100%)") {
    WispOrbView(
        adherenceState: AdherenceState(
            todayAdherence: 1.0,
            rolling7Adherence: 1.0,
            rolling30Adherence: 1.0
        )
    )
    .background(Color.black)
}

#Preview("High (80%)") {
    WispOrbView(
        adherenceState: AdherenceState(
            todayAdherence: 0.8,
            rolling7Adherence: 0.8,
            rolling30Adherence: 0.8
        )
    )
    .background(Color.black)
}

#Preview("Medium (60%)") {
    WispOrbView(
        adherenceState: AdherenceState(
            todayAdherence: 0.6,
            rolling7Adherence: 0.6,
            rolling30Adherence: 0.6
        )
    )
    .background(Color.black)
}

#Preview("Low (40%)") {
    WispOrbView(
        adherenceState: AdherenceState(
            todayAdherence: 0.4,
            rolling7Adherence: 0.4,
            rolling30Adherence: 0.4
        )
    )
    .background(Color.black)
}

#Preview("Minimal (20%)") {
    WispOrbView(
        adherenceState: AdherenceState(
            todayAdherence: 0.2,
            rolling7Adherence: 0.2,
            rolling30Adherence: 0.2
        )
    )
    .background(Color.black)
}
