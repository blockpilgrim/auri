# Thrumi Conventions

Emerging patterns and conventions for the Thrumi codebase.

---

## Project Structure

**When to use**: Always follow this structure for organizing files.

```
Thrumi/
├── App/           # App entry point and configuration
├── Views/         # SwiftUI views
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
