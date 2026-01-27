import RealityKit
import SwiftUI
import UIKit

/// Renders the Fusion Core 3D experience.
///
/// Camera is fixed and presented as a ~65° downward view by transforming the rendered content.
struct FusionCoreView: View {
    let adherenceState: AdherenceState

    var adherenceEngine: AdherenceEngine?
    var hapticsManager: HapticsManager?

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var scene: FusionCoreScene?
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

    var body: some View {
        RealityView { content in
            let fusionCore = await FusionCoreScene.create()
            content.add(fusionCore.rootEntity)

            await MainActor.run {
                scene = fusionCore

                stateInterpolator.update(with: adherenceState)
                applyPhysicsParameters()

                motionSettings.update(reduceMotion: reduceMotion)

                hapticsManager?.updateParameters(
                    intensity: stateInterpolator.hapticIntensity,
                    sharpness: stateInterpolator.hapticSharpness
                )

                startLoopIfNeeded()
            }
        } update: { _ in
            // Updates are driven by CADisplayLink.
        }
        .gesture(spinGesture)
        .ignoresSafeArea()
        .onDisappear {
            stopLoop()
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

    // MARK: - External micro-feedback

    func triggerMicroFeedback(isOnTrack: Bool) {
        pendingMicroFeedback = isOnTrack
    }

    // MARK: - Gesture

    private var spinGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                let now = Date.now

                if !isDragging {
                    isDragging = true
                    velocityTracker.reset()
                }

                velocityTracker.addSample(position: value.location, time: now)

                let v = velocityTracker.velocity
                let speed = sqrt(v.width * v.width + v.height * v.height)
                if speed > 80 {
                    physics.applyFlick(velocity: v)
                }
            }
            .onEnded { _ in
                isDragging = false

                let v = velocityTracker.velocity
                let speed = sqrt(v.width * v.width + v.height * v.height)
                if speed > 120 {
                    physics.applyFlick(velocity: v)
                    hapticsManager?.playSpinFeedback(velocity: Float(speed) / 800.0)
                }

                velocityTracker.reset()
            }
    }

    // MARK: - Loop

    private func startLoopIfNeeded() {
        guard displayLink == nil else { return }

        displayLink = DisplayLinkController { deltaTime in
            Task { @MainActor in
                tick(deltaTime: deltaTime)
            }
        }
        displayLink?.start()
    }

    private func stopLoop() {
        displayLink?.stop()
        displayLink = nil
    }

    private func tick(deltaTime: Float) {
        guard let scene else { return }

        // Consume pending micro-feedback (haptics only).
        if let engine = adherenceEngine, let isOnTrack = engine.pendingMicroFeedback {
            hapticsManager?.playMicroFeedback(isOnTrack: isOnTrack)
            engine.clearMicroFeedback()
        }
        if let isOnTrack = pendingMicroFeedback {
            hapticsManager?.playMicroFeedback(isOnTrack: isOnTrack)
            pendingMicroFeedback = nil
        }

        currentTime += Double(deltaTime)

        // Interactive spin is real-time; reduced-motion affects secondary animation only.
        physics.update(deltaTime: deltaTime)

        let motionConfig = motionSettings.config
        let adherence = stateInterpolator.adherence

        let amplitude: Float = motionConfig.showPulse ? (stateInterpolator.pulseAmplitude * thermalManager.effectMultiplier) : 0
        let pulseValues = pulseSystem.update(deltaTime: deltaTime, amplitude: amplitude, adherence: adherence)

        scene.update(
            interpolator: stateInterpolator,
            pulse: pulseValues,
            deltaTime: deltaTime * motionConfig.animationSpeed,
            spinAngle: physics.spinAngle,
            currentTime: currentTime,
            bloomMultiplier: thermalManager.bloomMultiplier,
            thermalParticleMultiplier: thermalManager.particleMultiplier,
            showParticles: motionConfig.showParticles
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
        let time: Date
    }

    private var samples: [Sample] = []
    private let maxSamples = 5
    private let maxAge: TimeInterval = 0.1

    var velocity: CGSize {
        let now = Date.now
        let recentSamples = samples.filter { now.timeIntervalSince($0.time) < maxAge }

        guard recentSamples.count >= 2 else {
            return .zero
        }

        guard let first = recentSamples.first, let last = recentSamples.last else {
            return .zero
        }

        let dt = last.time.timeIntervalSince(first.time)
        guard dt > 0.001 else { return .zero }

        let dx = last.position.x - first.position.x
        let dy = last.position.y - first.position.y

        return CGSize(width: dx / dt, height: dy / dt)
    }

    mutating func addSample(position: CGPoint, time: Date) {
        samples.append(Sample(position: position, time: time))

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
    FusionCoreView(
        adherenceState: AdherenceState(
            todayAdherence: 1.0,
            rolling7Adherence: 1.0,
            rolling30Adherence: 1.0
        )
    )
    .background(Color.black)
}

#Preview("Online (80%)") {
    FusionCoreView(
        adherenceState: AdherenceState(
            todayAdherence: 0.8,
            rolling7Adherence: 0.8,
            rolling30Adherence: 0.8
        )
    )
    .background(Color.black)
}

#Preview("Stabilizing (60%)") {
    FusionCoreView(
        adherenceState: AdherenceState(
            todayAdherence: 0.6,
            rolling7Adherence: 0.6,
            rolling30Adherence: 0.6
        )
    )
    .background(Color.black)
}

#Preview("Standby (40%)") {
    FusionCoreView(
        adherenceState: AdherenceState(
            todayAdherence: 0.4,
            rolling7Adherence: 0.4,
            rolling30Adherence: 0.4
        )
    )
    .background(Color.black)
}

#Preview("Safe Mode (20%)") {
    FusionCoreView(
        adherenceState: AdherenceState(
            todayAdherence: 0.2,
            rolling7Adherence: 0.2,
            rolling30Adherence: 0.2
        )
    )
    .background(Color.black)
}
