# Auri

A diet-adherence tracker for iOS that replaces charts and numbers with a living 3D orb. Log meals, tag them on-track or off-track, and watch your orb respond — more sparks, richer colors, faster orbits as adherence improves.

<!-- Screenshots: capture from Simulator using the five preview states in AuriView.swift (20%, 40%, 60%, 80%, 100%) -->

## What It Does

Most diet apps lose users because logging feels like homework and feedback is abstract. Auri replaces spreadsheets and progress bars with a single interactive object: a luminous orb of orbiting sparks that embodies your adherence on a 0–100% continuum.

The underlying system is evidence-based — rolling adherence percentages calculated from meal logs — but the interface replaces judgmental numbers with something you actually want to look at and interact with. Low adherence isn't a punishment; it's a calm, resting state. High adherence is unmistakably vibrant.

The orb is a genuine fidget toy. Flick to spin the sparks. Tap to scatter them. Pinch to resize. Long-press to attract sparks to your finger. Two-finger twist to tilt the orbital plane. Shake your phone for chaos mode. Every gesture produces adherence-tuned haptic feedback — crisp and celebratory when you're doing well, soft and ethereal when you're not.

## Tech Stack

- **Swift 6** / iOS 18 minimum deployment target
- **RealityKit** — procedural 3D scene with hand-written mesh generation, quaternion-tilted orbital mechanics, object-pooled particle systems, and frame-synced animation via `CADisplayLink` at up to 120 Hz (ProMotion)
- **SwiftUI** — 4-screen app with custom glass-morphism design system, environment-based service injection
- **SwiftData** — local persistence for meals and user settings, no backend
- **Core Haptics** — 8 distinct haptic patterns parameterized by adherence state
- **Core Motion** — gyroscope-based shake detection for chaos mode
- **Swift Testing** — modern test framework (`@Suite`, `@Test`, `#expect`)

## Architecture

```
SwiftUI Views → Domain Services → SwiftData Models
       ↕
  RealityKit 3D (AuriScene)
```

**Views** — `CoreView` (home with 3D orb), `LogMealView`, `DataView`, `OnboardingView`. Components use a shared glass-morphism design system.

**Services** — `MealService` (CRUD + local JPEG photo storage), `AdherenceEngine` (calculates today/7-day/30-day rolling adherence with a non-linear reward curve), `UserPreferencesService`. All `@Observable`, injected via custom `EnvironmentValues`.

**3D System** — the most complex module (~2,800 lines). `AuriScene` orchestrates the RealityKit scene. `Spark` entities orbit on individually quaternion-tilted planes with spring-damped position physics. `StateInterpolator` maps adherence to visual parameters using piecewise interpolation. Supporting systems handle spin physics, multi-frequency breathing pulses, ambient particle motes (object-pooled), tier transition effects (procedural torus mesh), thermal throttling, and full Reduce Motion accessibility.

### Notable Implementation Details

- **Delta-based spin physics** — produces per-frame deltas instead of absolute angles to prevent jitter from wrapping discontinuities when multiplied by per-spark speed multipliers
- **Round-robin material batching** — distributes GPU material updates across ~6 frames to prevent frame spikes at opacity quantization boundaries
- **Procedural torus mesh** — hand-computed positions, normals, UVs, and triangle indices via `MeshDescriptor` for tier-upgrade ring effects
- **Thermal-adaptive rendering** — monitors `ProcessInfo.thermalState` and independently throttles bloom, particle count, animation complexity, and frame rate
- **Non-linear reward curve** — `1 - pow(1-x, 2.5)` makes early progress feel disproportionately rewarding while keeping 80–100% visually distinct

## Getting Started

Requires Xcode 16+ and iOS 18.0 SDK.

```bash
# Clone and open
git clone <repo-url>
open Auri.xcodeproj

# Build for simulator
xcodebuild -project Auri.xcodeproj -scheme Auri \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Run tests
xcodebuild -project Auri.xcodeproj -scheme Auri \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

No external dependencies. No backend. No API keys.

## Status

MVP in active development. Core 3D visualization, meal logging, adherence calculation, onboarding flow, and data view are all functional. Not yet submitted to the App Store.

## License

[MIT](LICENSE)
