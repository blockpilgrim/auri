# Thrumi Conventions

Emerging patterns and conventions for the Thrumi codebase.

---

## Project Structure

**When to use**: Always follow this structure for organizing files.

```
Thrumi/
├── App/           # App entry point and configuration
├── Views/         # SwiftUI views
│   └── Components/  # Reusable view components
├── Models/        # SwiftData models and domain types
├── Services/      # Business logic and data operations
├── 3D/            # RealityKit assets and 3D-related code
└── Resources/     # Assets, plists, and static resources
```

**Why**: Matches the architecture diagram in BUILD-STRATEGY.md. Keeps concerns separated and makes navigation predictable.

---

## One Enum Per File

**When to use**: When creating enums that represent domain concepts.

**Example**:
```swift
// MealSource.swift
enum MealSource: String, Codable, CaseIterable {
    case photo
    case text
}
```

**Why**: Easier to find, clearer imports, simpler git history when enums change.

---

## SwiftData Model Pattern

**When to use**: When creating SwiftData @Model classes.

**Example**:
```swift
import Foundation
import SwiftData

@Model
final class Meal {
    var id: UUID
    var timestamp: Date
    // ... other properties

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        // ... other params with defaults where sensible
    ) {
        self.id = id
        self.timestamp = timestamp
        // ...
    }
}
```

**Why**:
- Explicit `id` property instead of relying on SwiftData's auto-generated one gives us control
- Default values in init reduce boilerplate at call sites
- `final class` as SwiftData requires reference semantics

---

## Computed State Types

**When to use**: For derived data that doesn't need persistence.

**Example**:
```swift
struct AdherenceState: Equatable {
    let todayAdherence: Double
    let rolling7Adherence: Double
    let rolling30Adherence: Double
    let coreAdherence: Double  // Computed from inputs
    let tier: CoreTier         // Derived from coreAdherence

    init(todayAdherence: Double, rolling7Adherence: Double, rolling30Adherence: Double) {
        self.todayAdherence = todayAdherence
        self.rolling7Adherence = rolling7Adherence
        self.rolling30Adherence = rolling30Adherence
        self.coreAdherence = 0.60 * todayAdherence + 0.40 * rolling7Adherence
        self.tier = CoreTier.from(adherence: coreAdherence)
    }
}
```

**Why**:
- Struct (value type) for computed state that doesn't persist
- Compute derived values in init to ensure consistency
- Conform to `Equatable` to enable SwiftUI diffing

---

## Enum with Factory Method

**When to use**: When an enum needs to be derived from a continuous value.

**Example**:
```swift
enum CoreTier: String, Codable, CaseIterable {
    case safeMode       // 0-29%
    case standby        // 30-49%
    case stabilizing    // 50-69%
    case online         // 70-89%
    case phaseLocked    // 90-100%

    static func from(adherence: Double) -> CoreTier {
        switch adherence {
        case 0..<0.30: .safeMode
        case 0.30..<0.50: .standby
        case 0.50..<0.70: .stabilizing
        case 0.70..<0.90: .online
        default: .phaseLocked
        }
    }
}
```

**Why**: Keeps threshold logic with the enum. Single source of truth for mapping adherence to tiers.

---

## Testing with Swift Testing Framework

**When to use**: For all unit tests.

**Example**:
```swift
import Foundation
import SwiftData
import Testing

@testable import Thrumi

@Suite("Model Tests")
struct ModelTests {
    @Test("Descriptive test name")
    func testSomething() {
        #expect(actual == expected)
    }
}
```

**Why**: Swift Testing is the modern approach (vs XCTest). `@Suite` groups related tests. `#expect` provides clear assertions.

---

## Observable Service Pattern

**When to use**: When creating services that manage data or business logic.

**Example**:
```swift
import Foundation
import SwiftData

@Observable
final class MealService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func saveMeal(_ meal: Meal) throws {
        modelContext.insert(meal)
        try modelContext.save()
    }
}
```

**Why**:
- `@Observable` enables SwiftUI reactivity without manual publishers
- `final class` because services hold state and need reference semantics
- Accept `ModelContext` in init for dependency injection and testability
- Private `modelContext` prevents external mutation

---

## MainActor Tests for SwiftData

**When to use**: When writing tests that use SwiftData or services that interact with ModelContext.

**Example**:
```swift
@Suite("MealService Tests")
@MainActor
struct MealServiceTests {
    @Test("Save and retrieve meal")
    func saveMeal() throws {
        let container = try createTestContainer()
        let service = MealService(modelContext: container.mainContext)
        // ...
    }
}

@MainActor
private func createTestContainer() throws -> ModelContainer {
    let schema = Schema([Meal.self, UserSettings.self])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: [config])
}
```

**Why**:
- Swift 6 strict concurrency requires MainActor for ModelContext access
- `isStoredInMemoryOnly: true` creates isolated test containers
- Each test gets a fresh container to prevent test pollution

---

## Photo Storage in Documents Directory

**When to use**: When storing user-generated images locally.

**Example**:
```swift
private static let photoDirectoryName = "MealPhotos"

func savePhoto(_ image: UIImage, for mealId: UUID) throws -> String {
    guard let data = image.jpegData(compressionQuality: 0.75) else {
        throw MealServiceError.imageCompressionFailed
    }
    let filename = "\(mealId.uuidString).jpg"
    let relativePath = "\(Self.photoDirectoryName)/\(filename)"
    let fullURL = documentsDirectory.appendingPathComponent(relativePath)
    try data.write(to: fullURL)
    return relativePath  // Store relative path, not absolute
}
```

**Why**:
- Documents directory persists across app updates
- Relative paths stored in database avoid issues if documents directory path changes
- UUID-based filenames prevent collisions
- JPEG compression ~0.75 balances quality and size (~200KB target)

---

## Environment-Based Service Injection

**When to use**: When injecting services into the SwiftUI view hierarchy.

**Example**:
```swift
// App/Environment+Extensions.swift
import SwiftUI

extension EnvironmentValues {
    @Entry var mealService: MealService?
    @Entry var adherenceEngine: AdherenceEngine?
    @Entry var userPreferences: UserPreferencesService?
}

// App/ThrumiApp.swift
@main
struct ThrumiApp: App {
    let mealService: MealService
    // ... other services

    init() {
        let container = try! ModelContainer(for: schema)
        mealService = MealService(modelContext: container.mainContext)
        // ...
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.mealService, mealService)
        }
    }
}

// In views
struct SomeView: View {
    @Environment(\.mealService) private var mealService
}
```

**Why**:
- `@Entry` macro (Swift 5.10+) simplifies custom environment value declaration
- Optional types allow views to work in previews without services
- Services initialized once at app startup and shared via environment
- Decouples views from specific service implementations

---

## RealityKit Scene Pattern

**When to use**: When creating 3D scenes with RealityKit that need runtime material control.

**Example**:
```swift
import RealityKit
import UIKit

@MainActor
final class FusionCoreScene {
    let rootEntity: Entity
    let outerRing: Entity
    // ... other component references

    private init(rootEntity: Entity, outerRing: Entity, ...) {
        self.rootEntity = rootEntity
        self.outerRing = outerRing
    }

    static func create() async -> FusionCoreScene {
        let root = Entity()
        root.name = "FusionCore"

        // Create components...
        let outer = createRing(...)
        root.addChild(outer)

        return FusionCoreScene(rootEntity: root, outerRing: outer, ...)
    }

    func setEmissiveIntensity(_ intensity: Float, for component: CoreComponent) {
        // Update materials at runtime
    }
}
```

**Why**:
- `@MainActor` required for RealityKit entity manipulation
- Async factory method (`create()`) for procedural generation
- Store references to child entities for runtime material updates
- `final class` because scene holds mutable entity state
- Import UIKit for `UIColor` in iOS RealityKit code

---

## Custom Mesh Generation

**When to use**: When RealityKit's built-in primitives don't provide the needed geometry.

**Example**:
```swift
extension MeshResource {
    static func generateTorus(
        meanRadius: Float,
        tubeRadius: Float,
        segments: Int = 48,
        tubeSegments: Int = 24
    ) -> MeshResource {
        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []

        // Generate vertex data...

        var descriptor = MeshDescriptor()
        descriptor.positions = MeshBuffer(positions)
        descriptor.normals = MeshBuffer(normals)
        descriptor.textureCoordinates = MeshBuffer(uvs)
        descriptor.primitives = .triangles(indices)

        return try! MeshResource.generate(from: [descriptor])
    }
}
```

**Why**:
- Extension on `MeshResource` keeps custom generators with built-in ones
- Use `MeshDescriptor` for full control over vertex attributes
- Pre-compute positions, normals, UVs for efficient rendering
- `try!` acceptable here since generation with valid inputs won't fail

---

## Custom Physics System Pattern

**When to use**: When implementing custom kinematic physics instead of using a physics engine.

**Example**:
```swift
@Observable
@MainActor
final class SpinnerPhysics {
    // Current state
    var angularVelocity: SIMD3<Float> = .zero
    var ringRotations: SIMD3<Float> = .zero

    // Parameters (driven by external state)
    var maxSpeed: Float = 10.0
    var damping: Float = 0.98

    // Tier-based presets
    struct TierParameters {
        let maxSpeed: Float
        let damping: Float
    }

    static let tierPresets: [CoreTier: TierParameters] = [
        .phaseLocked: TierParameters(maxSpeed: 15.0, damping: 0.992),
        // ...
    ]

    func update(deltaTime: Float) {
        angularVelocity *= damping
        ringRotations += angularVelocity * deltaTime
    }

    func updateParameters(for state: AdherenceState) {
        guard let preset = Self.tierPresets[state.tier] else { return }
        maxSpeed = preset.maxSpeed
        damping = preset.damping
    }
}
```

**Why**:
- `@Observable` for SwiftUI reactivity
- `@MainActor` for thread safety with RealityKit
- SIMD types for efficient vector math
- Tier-based presets keep physics tuning organized
- Separate `update()` and `updateParameters()` methods for different update frequencies

---

## Display Link Update Loop Pattern

**When to use**: When you need frame-synchronized updates (physics, animations) in SwiftUI.

**Example**:
```swift
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
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    private func handleDisplayLink(_ link: CADisplayLink) {
        let deltaTime = Float(link.timestamp - lastTimestamp)
        lastTimestamp = link.timestamp
        onUpdate(min(deltaTime, 1.0 / 30.0)) // Cap to prevent physics explosions
    }
}

// Helper for @objc selector requirement
private class DisplayLinkTarget {
    let handler: (CADisplayLink) -> Void
    init(handler: @escaping (CADisplayLink) -> Void) { self.handler = handler }
    @objc func handleDisplayLink(_ link: CADisplayLink) { handler(link) }
}
```

**Why**:
- CADisplayLink provides frame-synchronized callbacks
- Helper class needed because CADisplayLink requires @objc selector
- Cap deltaTime to prevent physics instability after app pause/resume
- ProMotion support via `preferredFrameRateRange`
- `@MainActor` for thread safety

---

## Gesture Velocity Tracking Pattern

**When to use**: When DragGesture doesn't provide the velocity data you need.

**Example**:
```swift
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
        guard recentSamples.count >= 2 else { return .zero }

        let first = recentSamples.first!
        let last = recentSamples.last!
        let dt = last.time.timeIntervalSince(first.time)
        guard dt > 0.001 else { return .zero }

        return CGSize(
            width: (last.position.x - first.position.x) / dt,
            height: (last.position.y - first.position.y) / dt
        )
    }

    mutating func addSample(position: CGPoint, time: Date) {
        samples.append(Sample(position: position, time: time))
        if samples.count > maxSamples { samples.removeFirst() }
    }

    mutating func reset() { samples.removeAll() }
}
```

**Why**:
- SwiftUI's DragGesture doesn't always provide reliable velocity on `.onEnded`
- Tracking recent samples allows velocity calculation at any point
- Time-based filtering ensures velocity reflects recent motion, not stale data
- Struct with mutating functions for value semantics

---

## State Interpolation Pattern

**When to use**: When mapping a continuous value (like adherence 0.0–1.0) to multiple output parameters.

**Example**:
```swift
@Observable
@MainActor
final class StateInterpolator {
    var adherenceState: AdherenceState

    // Non-linear reward curve: 80% feels near-peak
    var normalizedPower: Float {
        let k: Float = 2.5
        return 1 - pow(1 - Float(adherenceState.coreAdherence), k)
    }

    // All outputs use lerp with normalizedPower
    var maxSpeed: Float { lerp(4.0, 12.0, normalizedPower) }
    var emissiveIntensity: Float { lerp(0.2, 1.0, normalizedPower) }

    private func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
        a + (b - a) * t
    }
}
```

**Why**:
- Centralizes parameter mapping in one place (single source of truth)
- Non-linear reward curve makes progress feel meaningful
- `@Observable` enables SwiftUI reactivity
- Computed properties ensure outputs stay synchronized with input

---

## Constant-Rate Animation with Variable Amplitude

**When to use**: When an animation should always run at the same speed but with varying intensity based on state.

**Example**:
```swift
struct ReactorPulse {
    private var phase: Float = 0
    let frequency: Float = 0.5  // Hz - CONSTANT, never changes

    mutating func update(deltaTime: Float, amplitude: Float, sharpness: Float) -> Float {
        phase += deltaTime * frequency * 2 * .pi
        if phase > 2 * .pi { phase -= 2 * .pi }

        let rawPulse = sin(phase)
        let shapedPulse = sign(rawPulse) * pow(abs(rawPulse), 1.0 / (sharpness + 0.5))
        return shapedPulse * amplitude
    }
}
```

**Why**:
- Constant rate avoids anxiety-inducing associations (like heart rate)
- Variable amplitude/sharpness still communicates state
- Phase wrapping prevents float overflow in long sessions
- Struct with mutating state for simple ownership

---

## Micro-Feedback Animation Pattern

**When to use**: When providing immediate visual feedback for user actions without disrupting ongoing animations.

**Example**:
```swift
// In scene class
private(set) var microFeedbackActive: Bool = false
private var microFeedbackProgress: Float = 0
private var microFeedbackDuration: Float = 0.4

func triggerMicroFeedback(isOnTrack: Bool) {
    microFeedbackActive = true
    microFeedbackProgress = 0
    microFeedbackDuration = isOnTrack ? 0.3 : 0.4  // On-track snappier
}

func updateMicroFeedback(deltaTime: Float, ...) -> Float {
    guard microFeedbackActive else { return 1.0 }

    microFeedbackProgress += deltaTime / microFeedbackDuration
    if microFeedbackProgress >= 1.0 {
        microFeedbackActive = false
        return 1.0
    }

    let t = 1.0 - pow(1.0 - microFeedbackProgress, 2.0)  // Ease-out
    // Apply feedback effects based on t
    return dampingMultiplier
}
```

**Why**:
- Progress-based animation allows frame-rate-independent timing
- Returning multipliers (like damping) lets caller integrate with physics
- Ease-out curve feels natural (quick start, smooth end)
- On-track animations should feel snappier than off-track (positive reinforcement)

---

## UIViewControllerRepresentable for System UI

**When to use**: When wrapping UIKit view controllers (camera, image picker, document picker) for use in SwiftUI.

**Example**:
```swift
import SwiftUI
import UIKit

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
```

**Why**:
- SwiftUI has no native camera API—UIImagePickerController is the standard approach
- Coordinator pattern handles delegate callbacks
- `@Environment(\.dismiss)` provides SwiftUI-native dismissal
- Use `fullScreenCover` instead of `sheet` for camera to provide full-screen experience

---

## Permission Request on First Use

**When to use**: When requesting system permissions (camera, photos, location).

**Example**:
```swift
import AVFoundation

func requestCameraPermission() async -> Bool {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .authorized:
        return true
    case .notDetermined:
        return await AVCaptureDevice.requestAccess(for: .video)
    default:
        return false
    }
}
```

**Why**:
- Request permissions at the moment of use, not during onboarding (BUILD-STRATEGY.md Decision 5)
- async/await provides clean handling of the permission dialog
- Handle denied state gracefully with user-friendly messaging

---

## One-Time Tooltip Pattern

**When to use**: When displaying educational content that should only appear once (or within a time window).

**Example**:
```swift
struct FeatureTooltip: View {
    @AppStorage("hasSeenFeatureTooltip") private var hasSeenTooltip = false
    @State private var isVisible = false
    @State private var opacity: Double = 0

    private var installDate: Date {
        if let stored = UserDefaults.standard.object(forKey: "appInstallDate") as? Date {
            return stored
        } else {
            let now = Date()
            UserDefaults.standard.set(now, forKey: "appInstallDate")
            return now
        }
    }

    private var isWithinFirstWeek: Bool {
        let days = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        return days < 7
    }

    var body: some View {
        Group {
            if isVisible {
                tooltipContent.opacity(opacity)
            }
        }
        .onAppear { checkAndShow() }
    }

    private func checkAndShow() {
        guard !hasSeenTooltip, isWithinFirstWeek else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeIn(duration: 0.3)) {
                isVisible = true
                opacity = 1.0
            }
        }
    }
}
```

**Why**:
- `@AppStorage` provides automatic persistence for dismissal state
- Time-window logic (first week) prevents tooltip fatigue for returning users
- Delayed appearance (1.5s) prevents jarring immediate overlay on view load
- Animation on show/hide creates polished feel

---

## Ring Alignment Jitter Pattern

**When to use**: When visual instability should increase smoothly at lower state values.

**Example**:
```swift
private var jitterPhase: Float = 0

func updateRingAlignmentJitter(jitterAmount: Float, deltaTime: Float) {
    jitterPhase += deltaTime * 2.0  // Animate for smooth movement

    let jitterScale = jitterAmount * 0.015  // Max rotation in radians

    // Each element gets different phase for organic feel
    outerJitterOffset = SIMD3<Float>(
        sin(jitterPhase * 1.1) * jitterScale,
        0,
        cos(jitterPhase * 0.9) * jitterScale * 0.5
    )
    // ... similar for other elements
}
```

**Why**:
- Phase-based animation creates smooth, continuous jitter (not random noise)
- Different phase multipliers per element prevent synchronized movement
- jitterAmount from interpolator ties to adherence state
- Separate X/Z axes create natural-looking wobble

---

## Step-Based Onboarding Flow Pattern

**When to use**: When implementing multi-step onboarding or wizard-style flows.

**Example**:
```swift
struct OnboardingView: View {
    @State private var currentStep: OnboardingStep = .welcome

    enum OnboardingStep: CaseIterable {
        case welcome
        case goalSelection
        case coreTutorial
        case firstMealPrompt
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            switch currentStep {
            case .welcome:
                WelcomeStep(onContinue: { currentStep = .goalSelection })
            case .goalSelection:
                GoalSelectionStep(onSelect: { goal in
                    saveGoal(goal)
                    currentStep = .coreTutorial
                })
            // ... other steps
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentStep)
    }
}
```

**Why**:
- Enum-based steps make flow explicit and type-safe
- Each step is a separate view for isolation and testability
- Single ZStack with switch enables smooth transitions
- Animation on step change provides polished UX
- Callbacks (`onContinue`, `onSelect`, `onComplete`) keep steps decoupled from navigation logic

---

## Simultaneous Gesture Detection Pattern

**When to use**: When you need to detect gestures on a view that already has gesture handlers without blocking them.

**Example**:
```swift
FusionCoreView(adherenceState: tutorialState)
    .simultaneousGesture(
        DragGesture(minimumDistance: 20)
            .onEnded { value in
                let velocity = sqrt(
                    pow(value.velocity.width, 2) +
                    pow(value.velocity.height, 2)
                )
                if velocity > 200 {
                    hasFlicked = true
                }
            }
    )
```

**Why**:
- `simultaneousGesture` runs alongside existing gestures instead of blocking them
- Useful for tutorials or analytics where you need to observe without interfering
- Velocity-based detection distinguishes flicks from slow drags
- Keep detection logic simple—just observe, don't modify view state extensively

---

## Core Haptics Manager Pattern

**When to use**: When providing tactile feedback that varies based on app state.

**Example**:
```swift
import CoreHaptics

@MainActor
final class HapticsManager {
    private var engine: CHHapticEngine?
    private var isEngineRunning: Bool = false

    // State-driven parameters
    var intensityMultiplier: Float = 0.7
    var sharpnessMultiplier: Float = 0.7

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.resetHandler = { [weak self] in
            Task { @MainActor in self?.restartEngine() }
        }
        try? engine?.start()
    }

    func playTransient(intensity: Float, sharpness: Float) {
        guard let engine, isEngineRunning else { return }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity * intensityMultiplier),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness * sharpnessMultiplier)
            ],
            relativeTime: 0
        )
        let pattern = try? CHHapticPattern(events: [event], parameters: [])
        let player = try? engine.makePlayer(with: pattern!)
        try? player?.start(atTime: CHHapticTimeImmediate)
    }
}
```

**Why**:
- `@MainActor` for thread safety
- State multipliers allow adherence-driven haptic quality (crisp at high, soft at low)
- Handle engine reset/stop for app lifecycle
- Check `supportsHaptics` for devices without Taptic Engine

---

## Thermal Management Pattern

**When to use**: When reducing visual effects under device thermal pressure.

**Example**:
```swift
@Observable
@MainActor
final class ThermalManager {
    private(set) var thermalState: ProcessInfo.ThermalState = .nominal
    private var observerToken: (any NSObjectProtocol)?

    var effectMultiplier: Float {
        switch thermalState {
        case .nominal, .fair: return 1.0
        case .serious: return 0.7  // 30% reduction
        case .critical: return 0.4  // 60% reduction
        @unknown default: return 1.0
        }
    }

    init() {
        thermalState = ProcessInfo.processInfo.thermalState
        observerToken = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.thermalState = ProcessInfo.processInfo.thermalState
            }
        }
    }
}
```

**Why**:
- Graceful degradation prevents thermal throttling
- `effectMultiplier` can be applied to bloom, particles, animation complexity
- Observe notification for real-time response
- Multipliers (0.7, 0.4) preserve visual fidelity while reducing load

---

## Reduce Motion Accessibility Pattern

**When to use**: When implementing accessibility support for users sensitive to motion.

**Example**:
```swift
// Environment key
private struct FusionCoreReducedMotionKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var fusionCoreReducedMotion: Bool {
        get { self[FusionCoreReducedMotionKey.self] }
        set { self[FusionCoreReducedMotionKey.self] = newValue }
    }
}

// Configuration struct
struct ReducedMotionConfig {
    let animationSpeed: Float       // 1.0 normal, 0.3 reduced
    let precessionIntensity: Float  // 1.0 normal, 0.0 reduced
    let showPulse: Bool             // true normal, false reduced
    let jitterIntensity: Float      // 1.0 normal, 0.0 reduced

    static let normal = ReducedMotionConfig(...)
    static let reduced = ReducedMotionConfig(...)
}

// View modifier
struct ReducedMotionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.environment(\.fusionCoreReducedMotion, reduceMotion)
    }
}
```

**Why**:
- Respect system Reduce Motion preference via `@Environment(\.accessibilityReduceMotion)`
- Config struct centralizes reduced motion parameters
- State differentiation preserved via color/intensity (not motion)
- Haptics can still fire in reduced motion mode (tactile != visual motion)

---

## Multi-Layer Glow System Pattern

**When to use**: When creating complex glow effects with multiple overlapping layers that respond to state.

**Example**:
```swift
@MainActor
final class CoreGlowLayers {
    let container: Entity
    private let hotCenter: ModelEntity     // Always visible, scales with power
    private let innerCore: ModelEntity     // Always visible, color shifts at high power
    private let outerGlow: ModelEntity     // Always visible, pulses slower
    private let energyField1: ModelEntity  // Visible at 30%+, rotates
    private let energyField2: ModelEntity  // Visible at 50%+, counter-rotates
    private let atmosphere: ModelEntity    // Visible at 40%+, outermost halo
    private let energyRing: ModelEntity    // Torus, rotates fast

    static func create() -> CoreGlowLayers {
        let container = Entity()
        // Create layers as spheres with UnlitMaterial for glow effect
        // Add in order (outer first) for proper transparency layering
        container.addChild(atmosphere)
        container.addChild(energyField2)
        // ...
        container.addChild(hotCenter)
        return CoreGlowLayers(...)
    }

    func update(adherence: Double, normalizedPower: Float, pulseValues: PulseValues, deltaTime: Float) {
        // Toggle visibility based on thresholds
        energyField1.isEnabled = adherence >= 0.30
        // Update materials based on pulse and power
    }
}
```

**Why**:
- Each layer can be independently animated (rotation, pulse, opacity)
- Visibility thresholds create progressive visual complexity as state improves
- UnlitMaterial with transparent blending creates additive glow appearance
- Layer order in scene graph affects transparency compositing

---

## Multi-Frequency Pulse Pattern

**When to use**: When a single pulse frequency isn't visually rich enough, or different elements need different animation rates.

**Example**:
```swift
struct MultiFrequencyPulse {
    private let primaryFrequency: Float = 1.5   // Main breathing rhythm
    private let fastFrequency: Float = 4.5      // Inner shimmer
    private let ultraFastFrequency: Float = 10.5 // High-power flicker

    private var primaryPhase: Float = 0
    private var fastPhase: Float = 0
    private var ultraFastPhase: Float = 0

    struct PulseValues {
        let primary: Float   // -1 to 1
        let fast: Float      // -1 to 1
        let ultraFast: Float // -1 to 1, may be 0 if not at high adherence
    }

    mutating func update(deltaTime: Float, amplitude: Float, sharpness: Float, adherence: Float) -> PulseValues {
        primaryPhase += deltaTime * primaryFrequency * 2 * .pi
        fastPhase += deltaTime * fastFrequency * 2 * .pi
        ultraFastPhase += deltaTime * ultraFastFrequency * 2 * .pi

        // Ultra-fast only at 70%+ adherence
        let ultraFastActive = adherence >= 0.70

        return PulseValues(
            primary: sin(primaryPhase) * amplitude,
            fast: sin(fastPhase) * amplitude * 0.6,
            ultraFast: ultraFastActive ? sin(ultraFastPhase) * amplitude * 0.3 : 0
        )
    }
}
```

**Why**:
- Multiple frequencies create richer, more organic animation
- Conditional activation (e.g., ultra-fast at 70%+) rewards high adherence
- Separate phase tracking prevents integer overflow across all frequencies
- Return struct allows caller to apply values to different visual elements

---

## iOS Particle Effect Workaround

**When to use**: When ParticleEmitterComponent isn't available or has limited iOS support.

**Don't do this** (on iOS):
```swift
// ParticleEmitterComponent has limited iOS support
var emitter = ParticleEmitterComponent()
emitter.birthRate = 30  // This property may not exist on iOS
emitter.mainEmitter.color = .constant(.single(color.cgColor))
```

**Why it fails**: ParticleEmitterComponent's full API is primarily available on visionOS. On iOS, the type may exist but with limited or different properties.

**Do this instead**:
```swift
@MainActor
final class SparkParticle {
    let entity: ModelEntity
    var isExpired: Bool { lifetime >= maxLifetime }
    private var lifetime: Float = 0
    private var velocity: SIMD3<Float>

    static func create(color: UIColor, intensity: Float) -> SparkParticle {
        let mesh = MeshResource.generateSphere(radius: 0.002)
        var material = UnlitMaterial()
        material.color = .init(tint: color)
        let entity = ModelEntity(mesh: mesh, materials: [material])
        // Set random position, velocity, lifetime
        return SparkParticle(entity: entity, ...)
    }

    func update(deltaTime: Float) {
        lifetime += deltaTime
        entity.position += velocity * deltaTime
        // Fade opacity, apply gravity, etc.
    }
}

// In manager:
private var activeSparks: [SparkParticle] = []

func updateSparks(...) {
    // Remove expired
    activeSparks.removeAll { spark in
        spark.update(deltaTime: deltaTime)
        if spark.isExpired {
            spark.entity.removeFromParent()
            return true
        }
        return false
    }
    // Spawn new based on timing
    if currentTime - lastSparkTime >= spawnInterval {
        let spark = SparkParticle.create(...)
        container.addChild(spark.entity)
        activeSparks.append(spark)
        lastSparkTime = currentTime
    }
}
```

**Why**:
- Works reliably on iOS (no platform-specific API dependencies)
- Full control over particle behavior, appearance, and performance
- Easy to cap maximum particles for performance
- Can be extended for any particle type (sparks, flashes, debris)

---

## Prototype-First Visual Translation Pattern

**When to use**: When rebuilding visual systems based on a working reference implementation (e.g., HTML/Three.js prototype).

**Example approach**:
```
1. Read entire prototype file first - understand structure before writing code
2. Document prototype's architecture in code comments:
   - Camera setup (position, lookAt, behavior)
   - Scene structure (what entities, their hierarchy)
   - Animation/update loop structure
   - Interpolation values for state mapping
3. Translate with explicit line number references:
```

```swift
/// Translated from thrumi-prototype.html buildFusionCore() (lines 891-947).
///
/// Ring configuration per prototype:
/// | Index | Inner R | Outer R | Thickness | Speed | Direction |
/// |-------|---------|---------|-----------|-------|-----------|
/// | 0     | 0.55    | 0.70    | 0.08      | 1.0   | CW        |
/// | 1     | 0.80    | 0.95    | 0.06      | 0.8   | CCW       |
/// ...

private static let ringConfigs: [RingConfig] = [
    RingConfig(innerRadius: 0.55, outerRadius: 0.70, thickness: 0.08, speedMultiplier: 1.0, direction: 1, ...),
    RingConfig(innerRadius: 0.80, outerRadius: 0.95, thickness: 0.06, speedMultiplier: 0.8, direction: -1, ...),
]
```

**Why**:
- Line number references make future debugging easier ("why is this 0.55?")
- Explicit mapping tables catch scale/unit translation errors
- Comments serve as specification when prototype file is no longer available
- Prevents "improvisation" drift from reference implementation

---

## Fixed Camera Position Pattern (RealityKit)

**When to use**: When the 3D scene requires a fixed viewing angle, not user-controlled orbit.

**Example**:
```swift
// In View body:
RealityView { content in
    let scene = await FusionCoreScene.create()
    content.add(scene.rootEntity)
}
// Apply fixed camera angle as 3D rotation on the view
.rotation3DEffect(
    .degrees(-63),  // Camera elevation angle
    axis: (x: 1, y: 0, z: 0),
    perspective: 0.5
)
```

**Why**:
- RealityKit's camera is managed by the view system, not scene objects
- Applying rotation to the view simulates camera angle
- No orbit controls means consistent framing across sessions
- Document the prototype's camera position (e.g., `(0, 5, 2.5)` looking at origin) to explain the rotation value

---

## Ring Configuration Component Pattern

**When to use**: When multiple similar entities need individual runtime parameters.

**Example**:
```swift
// Custom component for per-entity data
struct RingConfigComponent: Component {
    let speedMultiplier: Float
    let direction: Float // 1 = CW, -1 = CCW
    let index: Int
}

// Attach during creation
let ringGroup = Entity()
ringGroup.components.set(RingConfigComponent(
    speedMultiplier: config.speedMultiplier,
    direction: config.direction,
    index: index
))

// Read during update
for ring in rings {
    guard let config = ring.components[RingConfigComponent.self] else { continue }
    let rotation = baseRotation * config.speedMultiplier * config.direction
    ring.transform.rotation = simd_quatf(angle: rotation, axis: [0, 1, 0])
}
```

**Why**:
- RealityKit's Component system provides entity-attached data
- Avoids parallel arrays for entity-to-config mapping
- Query-friendly: can iterate entities and access their configs
- Type-safe: compiler ensures correct component usage

---

## Modular 3D Scene Architecture Pattern

**When to use**: When building complex 3D scenes with multiple distinct visual systems.

**Example**:
```swift
// Main scene orchestrator - owns all sub-systems
@MainActor
final class FusionCoreScene {
    let rootEntity: Entity

    private let reactorCore: ReactorCore      // Central energy field
    private let spinnerRings: SpinnerRings    // Industrial spinning structure
    private let particles: ParticleSystem     // Sparks, arcs, flashes

    static func create() async -> FusionCoreScene {
        let root = Entity()

        let core = ReactorCore.create(unitScale: unitScale)
        root.addChild(core.container)

        let rings = SpinnerRings.create(unitScale: unitScale)
        root.addChild(rings.container)

        let particles = ParticleSystem(ringRadii: rings.ringRadii, unitScale: unitScale)
        root.addChild(particles.container)

        return FusionCoreScene(...)
    }

    func update(interpolator: StateInterpolator, ...) {
        reactorCore.update(interpolator: interpolator, ...)
        spinnerRings.update(interpolator: interpolator, ...)
        particles.update(interpolator: interpolator, ...)
    }
}

// Each sub-system manages its own Entity container
@MainActor
final class ReactorCore {
    let container: Entity

    static func create(unitScale: Float) -> ReactorCore {
        let container = Entity()
        // Build layer hierarchy...
        return ReactorCore(container: container, ...)
    }

    func update(interpolator: StateInterpolator, ...) {
        // Update internal entities
    }
}
```

**Why**:
- Each visual system has a clear responsibility and API surface
- Sub-systems can be developed and tested independently
- StateInterpolator provides single source of truth for adherence-based parameters
- Container entities allow clean hierarchy in scene graph
- Factory methods (`create()`) encapsulate complex construction
- Update methods accept interpolator for consistent state mapping

---

## Industrial 3D Geometry Pattern

**When to use**: When creating machined/industrial-looking 3D objects.

**Example**:
```swift
// Main body with brushed metal
let body = ModelEntity(mesh: torusMesh, materials: [ringBodyMaterial(roughness: 0.35)])

// Inner machined groove (smaller radius, darker)
let innerGroove = ModelEntity(mesh: grooveMesh, materials: [grooveMaterial(roughness: 0.18)])

// Outer machined groove
let outerGroove = ModelEntity(mesh: outerGrooveMesh, materials: [grooveMaterial(roughness: 0.18)])

// Segment dividers for turbine-blade look
for i in 0..<segmentCount {
    let angle = Float(i) / Float(segmentCount) * 2 * .pi
    let segment = createSegmentDivider(radius: radius, angle: angle)
    group.addChild(segment)
}

// Copper coil modules (offset from segments)
for i in 0..<coilCount {
    let angle = Float(i) / Float(coilCount) * 2 * .pi + offset
    let coil = createCoilModule(radius: radius, angle: angle)
    group.addChild(coil)
}
```

**Why**:
- Concentric grooves create machined precision feel
- Segment dividers break up smooth torus into industrial sections
- Coils offset from segments avoid visual collision
- Different roughness values create material hierarchy (shiny grooves, matte body)
- Smaller detail geometry (grooves, segments) uses higher roughness for contrast
