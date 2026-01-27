# Thrumi: Build Strategy

> Strategic technical guidance for building Thrumi's MVP. Focus: get to App Store fast without accumulating crippling tech debt.

---

## 1. Tech Stack

### Platform & Language

| Component | Choice | Rationale |
|---|---|---|
| **Platform** | iOS-first (iPhone) | Product spec defines this. iPad support deferred to post-MVP. |
| **Language** | Swift 6 | Current stable version, required for iOS 18+ SDK submission. |
| **Minimum iOS** | iOS 18.0 | Required for modern RealityKit APIs (RealityView content manipulation). SwiftData also available. Covers 85%+ of active devices in 2026. |

### UI Framework

| Component | Choice | Rationale |
|---|---|---|
| **Primary UI** | SwiftUI | Mature in 2026. Declarative syntax accelerates development. Native state management (`@Observable`) reduces boilerplate. Perfect for our relatively simple UI (4 screens). |
| **3D View** | RealityKit embedded via `RealityView` | Apple's modern 3D pipeline. SceneKit is soft-deprecated and in maintenance mode—Apple recommends RealityKit for all new projects. SwiftUI-native integration via `RealityView`. |

**Trade-off:** SwiftUI still has edge cases where UIKit would be simpler (camera capture), but the development velocity gain outweighs the occasional wrapper.

### 3D & Graphics

| Component | Choice | Rationale |
|---|---|---|
| **3D Engine** | RealityKit | Future-proof (Apple's active investment), physically-based rendering out of the box, and designed for the kinds of procedural effects we need (bloom, metallic materials). |
| **Asset Format** | USDZ | RealityKit's native format. Single file contains model + textures. Optimized loading. |
| **Shader/Effects** | RealityKit materials + custom Metal shaders (if needed) | PBR materials handle most visual needs. Reserve Metal for signature effects (glow pulse, volumetric light) if RealityKit's built-in options fall short. |

**Trade-off:** RealityKit's physics simulation is less mature than Unity's. We'll implement spinner physics ourselves (kinematic control) rather than relying on built-in rigid body simulation—gives us precise "feel" tuning anyway.

### Data Persistence

| Component | Choice | Rationale |
|---|---|---|
| **Local Storage** | SwiftData | New project with iOS 17+ minimum = no Core Data baggage. Declarative, SwiftUI-native, minimal boilerplate. Our data model is simple (meals, user preferences). |
| **Schema Migrations** | SwiftData lightweight migrations | Sufficient for MVP. We can add manual migration logic later if data model becomes complex. |

**Trade-off:** SwiftData is younger than Core Data and slightly slower with very large datasets. Our data volume (meals = ~3-5/day) is trivial—won't matter.

### Camera & Media

| Component | Choice | Rationale |
|---|---|---|
| **Photo Capture** | AVFoundation via `UIViewRepresentable` | SwiftUI has no native camera API. Wrapping AVFoundation is standard practice—well-documented pattern. |
| **Photo Storage** | Local app storage (FileManager) | No need for Photos framework complexity. We own the meal photos. Simpler permissions. |
| **Image Processing** | Core Image (resize/compress) | Lightweight, built-in. Compress photos before storage to manage app size. |

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         SwiftUI Views                           │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌───────────────┐ │
│  │ CoreView  │  │ LogMeal   │  │ DataView  │  │  Onboarding   │ │
│  │  (Home)   │  │   View    │  │           │  │               │ │
│  └─────┬─────┘  └─────┬─────┘  └─────┬─────┘  └───────────────┘ │
└────────┼──────────────┼──────────────┼──────────────────────────┘
         │              │              │
         ▼              ▼              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Domain Layer                               │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────────┐   │
│  │ AdherenceEngine│  │  MealService   │  │  UserPreferences │   │
│  │ (state calc)   │  │  (CRUD + photo)│  │                  │   │
│  └───────┬────────┘  └───────┬────────┘  └──────────────────┘   │
└──────────┼───────────────────┼──────────────────────────────────┘
           │                   │
           ▼                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Data Layer                                 │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    SwiftData Models                      │    │
│  │    Meal  |  DailyLog  |  UserSettings                   │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      3D Subsystem                               │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────────┐   │
│  │  FusionCore    │  │ SpinnerPhysics │  │  StateInterpolator│  │
│  │  (RealityKit)  │  │  (kinematic)   │  │  (adherence→feel) │  │
│  └────────────────┘  └────────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

### Pattern: Lightweight MVVM

- **Views** own their local UI state (`@State`)
- **Observable models** (`@Observable`) hold domain state shared across views
- **Services** encapsulate data operations (MealService, AdherenceEngine)
- **No heavy ViewModel layer**—SwiftUI's `@Observable` eliminates most of what traditional ViewModels did

This is pragmatic for a 4-screen app. Over-architecting would slow us down.

---

## 3. Data Architecture

### Core Models

```
Meal
├── id: UUID
├── timestamp: Date
├── photoPath: String?          // relative path to stored image
├── description: String?        // optional text entry
├── isOnTrack: Bool
└── source: MealSource          // .photo | .text

UserSettings
├── id: UUID
├── dietaryGoal: DietaryGoal    // enum: keto, vegan, etc.
├── onboardingComplete: Bool
└── createdAt: Date
```

### Computed/Derived (not persisted)

```
AdherenceState
├── todayAdherence: Double      // 0.0–1.0
├── rolling7Adherence: Double   // 0.0–1.0
├── rolling30Adherence: Double  // 0.0–1.0
├── coreAdherence: Double       // blended: 0.6*today + 0.4*rolling7
└── tier: CoreTier              // enum: safeModePhase-locked, standby, stabilizing, online, phaseLocked
```

### Data Flow

1. User logs meal → `MealService.save(meal)` → SwiftData persists
2. `AdherenceEngine` recomputes state (queries meals, calculates ratios)
3. `CoreView` observes `AdherenceEngine.state` → drives 3D visual parameters

### Why No Server/Sync (MVP)

- No user accounts = no backend complexity
- Data lives on device only
- Dramatically reduces scope and App Store review friction
- Can add CloudKit sync post-MVP if retention data justifies it

---

## 4. Key Decisions

### Decision 1: Custom Spinner Physics vs. RealityKit Physics

**Context:** RealityKit has built-in physics simulation, but it's designed for realistic rigid body dynamics, not "satisfying fidget toy feel."

**Decision:** Implement custom kinematic physics.

**Approach:**
- Use RealityKit's `.kinematic` physics mode
- Directly control angular velocity based on gesture input
- Implement our own damping curves, speed ceilings, and "stabilization authority" as functions of adherence
- No collision-based physics needed—the Core floats

**Rationale:** The spec explicitly calls for tunable "feel" (damping, persistence, wobble suppression). We need direct control over these parameters. Fighting a physics engine to get precise fidget satisfaction would be harder than building the behavior ourselves.

**Trade-off:** More code to write upfront, but full creative control and easier tuning.

---

### Decision 2: Procedural vs. Pre-built 3D Model

**Context:** The Fusion Core needs to be "procedurally generated" per spec, with state-dependent visuals.

**Decision:** Hybrid approach—pre-built base geometry + runtime material/parameter adjustments.

**Approach:**
- Model the Fusion Core components in Reality Composer Pro (rings, coils, center)
- Export as USDZ
- At runtime, adjust material properties (emissive intensity, roughness) and animation parameters based on `coreAdherence`
- Effects like "micro phase-lock" can be shader-driven or animation blending

**Rationale:** Pure procedural geometry generation is complex and slow. Pre-built assets with dynamic parameters gives us "looks procedural" results with shipping-ready performance.

**Trade-off:** Less geometric variation than true procedural generation, but the spec's variation is about behavior and light, not shape.

---

### Decision 3: Photo Storage Strategy

**Context:** Meal photos need to be stored. Options: (a) Photos library, (b) app's local storage, (c) cloud storage.

**Decision:** Local app storage via FileManager.

**Approach:**
- Save compressed JPEGs to app's Documents directory
- Store relative path in SwiftData model
- Implement cleanup routine for orphaned photos

**Rationale:**
- No Photos permission request (simpler onboarding, one less rejection vector)
- No cloud dependency (works offline, no backend)
- Full control over retention and cleanup

**Trade-off:** Photos don't appear in user's Camera Roll (may confuse some users). Users can't easily share meal photos externally. Acceptable for MVP—we're not building Instagram.

---

### Decision 4: Adherence Calculation Timing

**Context:** When should we recalculate adherence state?

**Decision:** On-demand calculation, not background processing.

**Approach:**
- Recalculate when: app foregrounds, meal logged, user navigates to Data View
- Cache the result for the session
- No background refresh, no timers

**Rationale:** Meal logging is infrequent (3-5x/day). The calculation is cheap (count records, divide). Over-engineering async computation for a simple ratio is waste.

**Trade-off:** Adherence won't update at midnight while app is open. Acceptable—close and reopen takes 2 seconds.

---

### Decision 5: Onboarding Flow

**Context:** Spec targets <60 seconds to first interaction.

**Decision:** Minimal linear flow, skip where possible.

**Approach:**
1. Welcome screen (1 tap)
2. Dietary goal picker (1 tap)
3. Core tutorial (1 gesture: flick to spin)
4. Prompt to log first meal

No account creation. No permissions upfront (request camera when user first taps Log Meal).

**Rationale:** Every screen in onboarding is a dropout point. The Core is the hook—get users to it immediately.

**Trade-off:** Deferred permission request may feel slightly awkward on first log. Worth it for faster time-to-delight.

---

## 5. Testing Philosophy

### What We Test

| Layer | Approach |
|---|---|
| **Adherence Logic** | Unit tests. This is the core algorithm—must be correct. Test edge cases: no meals, all on-track, all off-track, day boundaries, rolling window math. |
| **Data Layer** | Unit tests for SwiftData operations. Ensure CRUD works, queries return correct data. |
| **3D Visuals** | Manual QA + snapshot tests. Automated visual testing of 3D is brittle; human eyes catch "feel" issues. |
| **UI Flows** | UI tests for critical paths: onboarding complete, meal logging, navigation. Light coverage—UI changes often in early stages. |

### What We Don't Test (MVP)

- Every UI permutation (diminishing returns)
- Performance benchmarks (profile manually, fix obvious issues)
- Accessibility (add post-MVP when core experience is validated)

### Philosophy

Ship fast, fix bugs that users report. Don't let test coverage block launch. The App Store audience will find issues no test suite would.

---

## 6. Performance Considerations

### Launch Time

**Target:** <2 seconds cold launch.

**Approach:**
- Precompile assets (USDZ in bundle, no runtime fetching)
- Defer non-critical work (adherence calculation can happen after first frame)
- Lazy-load Data View and settings
- Profile with Instruments before submission

### 3D Performance

**Target:** Solid 60fps on iPhone 12 and newer.

**Approach:**
- Keep Fusion Core poly count reasonable (<50K triangles)
- Use RealityKit's built-in LOD if needed
- Limit particle effects and bloom intensity on older devices (check `ProcessInfo.processInfo.thermalState`)
- Profile with Metal System Trace

### Battery

**Approach:**
- Reduce frame rate when app is backgrounded or device is idle
- Don't animate when user isn't touching
- No background processing, no location services, no network polling

### Storage

**Approach:**
- Compress meal photos to ~200KB each
- Implement photo cleanup for deleted meals
- Target: app + 1 year of meals < 500MB

---

## 7. App Store Readiness

### Submission Checklist (Pre-Built)

- [ ] Privacy manifest (required since 2024)
- [ ] App Privacy labels accurate (we collect: photos, usage data)
- [ ] Camera permission string clear and non-generic
- [ ] No placeholder content
- [ ] Demo scenario prepared (5-10 logged meals, varied adherence)
- [ ] Privacy policy URL live and accessible
- [ ] Screenshots for all required device sizes
- [ ] App Review notes explain the Core mechanic

### Rejection Risk Mitigation

| Risk | Mitigation |
|---|---|
| "Not enough functionality" | Ensure full loop works: log meal → see Core update → view data |
| Crashes | Test on physical devices, not just simulator |
| Camera permission rejection | Clear purpose string: "Take photos of your meals to track progress" |
| Misleading metadata | Don't overclaim—we're a tracker, not an AI nutritionist |

---

## 8. What We're Optimizing For

| Priority | What It Means |
|---|---|
| **Speed to App Store** | Ship MVP in weeks, not months. Cut scope aggressively. |
| **Delight** | The Core must feel amazing. This is the product. |
| **Simplicity** | 4 screens, no backend, no accounts, no sync. |
| **Iterability** | Clean enough to change quickly based on user feedback. |

### What We're Sacrificing

| Sacrifice | Why It's OK |
|---|---|
| Feature completeness | MVP scope is intentionally minimal. Premium features come later. |
| Cross-platform | iOS-first lets us ship faster and use native frameworks. Android later if validated. |
| Perfect architecture | Some shortcuts are fine. Refactor when we have users. |
| Extensive testing | Ship and learn. Users are the best QA. |

---

## 9. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| RealityKit performance issues on older devices | Medium | High | Profile early on iPhone 12. Have fallback visual mode ready. |
| Spinner "feel" is hard to tune | High | High | Budget time for iteration. Get the physics system built early. |
| SwiftData bugs/limitations | Low | Medium | Data model is simple. Can migrate to Core Data if critical issues arise. |
| App Store rejection | Medium | Medium | Follow checklist above. First-time apps often get scrutiny—expect one round of feedback. |
| Users don't understand Core connection to adherence | Medium | Medium | Tooltip on first use. Clear copy on Data View. |

---

## 10. Open Questions (Decide During Implementation)

1. **Haptics intensity:** How strong should feedback be at different adherence levels? Needs device testing.
2. **Photo compression quality:** 70% JPEG? 80%? Test visual quality vs. file size.
3. **Reduce Motion support:** What's the "calm mode" experience? Slower animation? Static glow?
4. **Core visual design:** The spec says "Stark-esque but not a replica." Needs design exploration before modeling.

---

## Sources

### 3D Graphics & RealityKit
- [WWDC 2025 - SceneKit Deprecation and RealityKit Migration](https://dev.to/arshtechpro/wwdc-2025-scenekit-deprecation-and-realitykit-migration-a-comprehensive-guide-for-ios-developers-o26)
- [Bring your SceneKit project to RealityKit - WWDC25](https://developer.apple.com/videos/play/wwdc2025/288/)
- [Physics in RealityKit](https://markhorgan.com/blog/physics-in-realitykit/)
- [PhysicsBodyComponent Documentation](https://developer.apple.com/documentation/realitykit/physicsbodycomponent)

### SwiftUI Architecture
- [The Ultimate Guide to Modern iOS Architecture in 2025](https://medium.com/@csmax/the-ultimate-guide-to-modern-ios-architecture-in-2025-9f0d5fdc892f)
- [SwiftUI vs UIKit in 2026](https://7span.com/blog/swiftui-vs-uikit)
- [Clean Architecture for SwiftUI](https://nalexn.github.io/clean-architecture-swiftui/)

### Data Persistence
- [Core Data vs SwiftData: Which Should You Use in 2025?](https://distantjob.com/blog/core-data-vs-swiftdata/)
- [SwiftUI Data Persistence in 2025](https://dev.to/swift_pal/swiftui-data-persistence-in-2025-swiftdata-core-data-appstorage-scenestorage-explained-with-5g2c)

### Performance & Launch Time
- [Reducing your app's launch time - Apple](https://developer.apple.com/documentation/xcode/reducing-your-app-s-launch-time)
- [How To Make Apps Load Faster in 2025](https://www.bitcot.com/how-to-make-apps-load-faster/)

### App Store Submission
- [App Store Review Guidelines 2025](https://nextnative.dev/blog/app-store-review-guidelines)
- [iOS App Store Review Guidelines 2026](https://crustlab.com/blog/ios-app-store-review-guidelines/)
- [How Long Does App Store Review Take in 2025?](https://be-dev.pl/blog/eng/how-long-does-app-store-review-take-in-2025-average-time-common-mistakes-how-to-speed-it-up)

### Camera Integration
- [Camera capture setup in a SwiftUI app](https://www.createwithswift.com/camera-capture-setup-in-a-swiftui-app/)
- [Integrating Device Camera in SwiftUI Apps](https://www.createwithswift.com/integrating-device-camera-in-swiftui-apps/)
