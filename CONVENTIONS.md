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
