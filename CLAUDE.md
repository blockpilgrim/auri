# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Auri is an iOS diet-adherence tracker that visualizes progress as a 3D orb of orbiting sparks using RealityKit. Instead of charts and numbers, adherence drives the visual richness of the orb — spark count, speed, color, and brightness all respond to how well the user is eating. Built with Swift 6, SwiftUI, SwiftData, and RealityKit. Minimum deployment target: iOS 18.0.

## Build & Test Commands

This is an Xcode project (no SPM Package.swift). Build and test via `xcodebuild`:

```bash
# Build
xcodebuild -project Auri.xcodeproj -scheme Auri -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run all tests
xcodebuild -project Auri.xcodeproj -scheme Auri -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test

# Run a specific test suite
xcodebuild -project Auri.xcodeproj -scheme Auri -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:AuriTests/ModelTests

# Run a specific test
xcodebuild -project Auri.xcodeproj -scheme Auri -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test -only-testing:AuriTests/ModelTests/testMealCreationWithPhotoSource
```

No external package dependencies. No linter configured.

## Architecture

### Layer Structure

```
SwiftUI Views → Domain Services → SwiftData Models
       ↕
  RealityKit 3D (AuriScene)
```

**Views** (`Auri/Views/`): 4 main screens — `CoreView` (home with 3D orb), `LogMealView`, `DataView`, `OnboardingView`. Components and onboarding steps are in subdirectories.

**Services** (`Auri/Services/`): `MealService` (CRUD + photo storage), `AdherenceEngine` (calculates adherence percentages from meal data), `UserPreferencesService` (settings management). All are `@Observable` classes injected via SwiftUI environment.

**Models** (`Auri/Models/`): SwiftData `@Model` classes (`Meal`, `UserSettings`) plus value types (`AdherenceState`, `OrbTier`, `DietaryGoal`, `MealSource`).

**3D System** (`Auri/3D/`): The most complex module. `AuriScene` orchestrates the RealityKit scene. `Spark` represents individual orbiting light particles. `StateInterpolator` maps adherence (0.0–1.0) to visual parameters using a non-linear reward curve. `SpinnerPhysics` handles spin dynamics. `AuriView` is the SwiftUI wrapper with gesture handling. Supporting systems: `HapticsManager`, `MotionManager`, `ThermalManager`, `MultiFrequencyPulse`, `TierTransitionEffect`, `AmbientMoteSystem`, `ReducedMotionSupport`.

### Key Data Flow

1. User logs a meal → `MealService` persists to SwiftData
2. `AdherenceEngine` recalculates adherence percentages (today, 7-day, 30-day rolling)
3. `AdherenceState` computed → contains `coreAdherence` (weighted: 60% today + 40% 7-day) and `OrbTier`
4. `StateInterpolator` maps adherence to visual parameters (speed, color, spark count, emissive intensity)
5. `AuriScene.update()` applies parameters to RealityKit entities each frame via `CADisplayLink`

### Service Injection

Services are created in `AuriApp.init()` and injected via custom `EnvironmentValues` (defined in `App/Environment+Extensions.swift`). Views access them with `@Environment(\.mealService)` etc. All environment service types are optional to support SwiftUI previews.

## Key Conventions

- **Testing framework**: Swift Testing (`@Suite`, `@Test`, `#expect`) — not XCTest
- **SwiftData tests**: Must be `@MainActor`, use in-memory `ModelContainer`
- **All RealityKit code**: Must be `@MainActor`
- **Git commits**: `[ISSUE-ID] Brief description` (e.g., `[THR-42] Add meal photo capture`)
- **Linear project**: "Auri-MVP"
- **Patterns and conventions**: See `CONVENTIONS.md` for established patterns (SwiftData models, observable services, custom mesh generation, gesture tracking, particle systems, etc.)

## Important Documentation

- `docs/PRODUCT.md` — Product brief ("Auri: Your Light, Visualized")
- `docs/BUILD-STRATEGY.md` — Tech stack decisions, architecture diagram, implementation roadmap
- `CONVENTIONS.md` — Code patterns and anti-patterns (updated via Compound Engineering Protocol)

## Session Startup Protocol
At the beginning of each session:
1. Read `README.md` (if it exists) for project overview
2. Read `docs/PRODUCT.md` to understand what we're building (located in `docs/`)
3. Read `CONVENTIONS.md` to understand current patterns and standards
4. If working on a specific feature or Linear issue, read relevant sections of `docs/BUILD-STRATEGY.md`
5. Signal readiness by saying: "⏱️ So much time and so little to do. Wait. Strike that. Reverse it."

## Linear Workflow

Linear project name: "Auri-MVP"

### Starting Work on an Issue
1. Check the issue status in Linear
2. If status is "In Progress": Read all issue comments for context from previous sessions
3. If status is "Backlog" or "Todo": Set status to "In Progress"
4. Read the full issue description, acceptance criteria, and any linked resources

### During Implementation
- Follow patterns established in `CONVENTIONS.md` (if any exist)
- If you encounter a decision not covered by existing conventions, make a reasonable choice and document it
- Commit frequently with clear messages

### Completing Work on an Issue
1. Add a comment to the Linear issue documenting:
   - What was implemented
   - Implementation status (complete, partial, blocked)
   - Any important context for future sessions
   - Known issues or edge cases
2. Review `CONVENTIONS.md` — see Compound Engineering Protocol below
3. Set issue status to appropriate state (Done, In Review, Blocked)
4. Signal completion by saying at the very end: "🧪 Invention is 93% perspiration, 6% electricity, 4% evaporation, and 2% butterscotch ripple. Do you concur?"

## Compound Engineering Protocol
This protocol ensures the codebase gets smarter over time. It is **not optional**—execute it after every implementation session.

**After completing any implementation work:**
1. Review `CONVENTIONS.md`
2. Ask yourself:
   - Did I establish any new patterns that should be replicated?
   - Did I discover that an existing pattern was problematic?
   - Did I try an approach that failed and should be documented as an anti-pattern?
3. If yes to any: Update `CONVENTIONS.md` with the learning
4. For significant architectural changes: Add entry to `docs/DECISIONS.md`

**After resolving any bug or unexpected behavior:**
1. Identify root cause
2. Determine if it was caused by:
   - Missing pattern → Add the pattern to `CONVENTIONS.md`
   - Wrong pattern → Update the pattern in `CONVENTIONS.md`
   - One-off issue → Document in Linear issue comment only
3. If a pattern caused the bug, document it as an anti-pattern with:
   - What the bad approach was
   - Why it failed
   - What the correct approach is

**Format for new patterns:**
```markdown
## [Pattern Name]
**When to use**: [Criteria]
**Example**:
```[language]
// Example code
```
**Why**: [Brief rationale]
```

**Format for anti-patterns:**
```markdown
## [Anti-pattern Name]
**Don't do this**:
```[language]
// Bad example
```
**Why it fails**: [What went wrong]
**Do this instead**:
```[language]
// Correct approach
```

## When to Ask for Human Input
- Unclear or ambiguous requirements
- Decisions that significantly deviate from established patterns
- Security-sensitive implementations
- External service integrations not covered in `docs/BUILD-STRATEGY.md`
- When stuck after 2-3 different approaches
- When unsure if a pattern change is warranted
