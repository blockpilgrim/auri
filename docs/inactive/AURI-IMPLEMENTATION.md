# Implementation Directive: Auri Visualization

> **Note:** This document was created during initial implementation. The terminology has since evolved:
> - **App name:** Thrumi → **Auri**
> - **Core concept:** "Orb of Wisps" → **"Your Auri"** (biophoton-based metaphor)
> - **Particles:** "Wisps" → **"Sparks"**
> - **Code files:** `WispOrbScene` → `AuriScene`, `WispOrbView` → `AuriView`, `WispColors` → `SparkColors`, `Wisp` → `Spark`
>
> See `docs/PRODUCT.md` for current product language.

---

## Overview (Historical)

Replace the current "Fusion Core" (industrial arc reactor aesthetic) with a magical, stylized orb with orbiting spirit-like elements. This is a complete visual overhaul—no remnants of the fusion core design should remain.

**Why the change:** The Fusion Core relied on glow/bloom effects that RealityKit cannot achieve well. The orb visualization uses orbiting geometry and motion—playing to RealityKit's strengths.

---

## Design Specification: Orb of Wisps

### Core Concept
A translucent/subtle container orb with magical wisp entities orbiting inside. The number of wisps, their speed, brightness, and color richness reflect adherence state. Users can flick to spin the wisps faster.

### Visual Style
- **Cel-shaded / stylized** — NOT photorealistic
- **Flat colors using `UnlitMaterial`** — embrace the flatness
- **Soft, magical color palette** — teals, purples, soft pinks, warm golds
- Think: Studio Ghibli magic, Ori and the Blind Forest, fantasy mana orbs

### Container Orb
- Very subtle or nearly invisible
- Option A: Faint wireframe sphere outline
- Option B: Extremely transparent glass-like sphere (barely visible)
- Option C: No container—wisps float in space with subtle boundary
- **Recommendation:** Start with Option C (no container), add if needed

### Wisps
- **Geometry:** Small teardrop or elongated sphere shape (like a flame or spirit)
- **Size:** Vary slightly (0.8x to 1.2x base size for organic feel)
- **Material:** `UnlitMaterial` with bright, saturated colors
- **Colors by state:**
  - Low adherence (0-30%): Cool blues, dim
  - Medium (30-60%): Teals, soft purples
  - High (60-85%): Warm golds, bright teals, pinks
  - Peak (85-100%): White-hot cores with colored trails, full spectrum
- **Quantity by adherence:**
  - 0-20%: 3-5 wisps (minimal, calm)
  - 20-50%: 6-12 wisps
  - 50-80%: 12-20 wisps
  - 80-100%: 20-30 wisps (vibrant, full)

### Wisp Behavior
- **Orbital motion:** Wisps orbit the center point on varied orbital planes
- **Orbital planes:** Randomized tilt per wisp (not all on same plane)
- **Base speed:** Varies by adherence (slower at low, faster at high)
- **Individual variation:** Each wisp has slight speed offset for organic feel
- **"Breathing":** Subtle scale pulse on each wisp
- **Trails (optional):** At high adherence, wisps could leave faint particle trails

### Interaction Model
- **Flick/swipe gesture:** Imparts angular momentum to the wisp system (like current spinner)
- **Wisps respond to flick:** Orbit faster, then gradually slow via damping
- **Max speed:** Capped based on adherence (higher adherence = higher ceiling)
- **Damping:** Lower adherence = faster slowdown; higher = longer spin persistence
- **Tap (optional):** Could trigger a "pulse" where wisps briefly scatter outward then return

### State Mapping (Adherence → Visuals)

| Adherence | Wisp Count | Base Speed | Color Palette | Brightness | Special Effects |
|-----------|------------|------------|---------------|------------|-----------------|
| 0-20% | 3-5 | Slow drift | Cool blue, dim | 40% | None |
| 20-40% | 6-9 | Gentle orbit | Blue-teal | 55% | None |
| 40-60% | 10-14 | Moderate | Teal-purple | 70% | Subtle pulse |
| 60-80% | 15-22 | Active | Gold-teal-pink | 85% | Occasional sparkle |
| 80-100% | 23-30 | Energetic | Full spectrum, white cores | 100% | Trails, sparkles |

### Micro-Feedback (On Meal Log)
- **On-track:** Wisps briefly accelerate and pulse brighter, a new wisp fades in
- **Off-track:** Wisps briefly slow, one wisp gently fades out

---

## Architecture & Files to Modify

### Files to REPLACE (delete and recreate with new implementation):

1. **`Thrumi/3D/FusionCoreScene.swift`** → **`WispOrbScene.swift`**
   - New scene orchestrator
   - Manages wisp entities, orbital system, container (if any)
   - Update method receives interpolator values and applies to wisps

2. **`Thrumi/3D/ReactorCore.swift`** → **DELETE** (no equivalent needed)

3. **`Thrumi/3D/SpinnerRings.swift`** → **DELETE** (no industrial rings)

4. **`Thrumi/3D/ParticleSystem.swift`** → **DELETE or replace with `WispTrailSystem.swift`**
   - If implementing trails/sparkles at high adherence, create simpler system
   - Or delete entirely if not doing trails initially

5. **`Thrumi/3D/CoreColors.swift`** → **`WispColors.swift`**
   - New color palette for magical aesthetic
   - Blues, teals, purples, golds, pinks, white

### Files to MODIFY:

1. **`Thrumi/3D/FusionCoreView.swift`** → **Rename to `WispOrbView.swift`**
   - Update to instantiate `WispOrbScene`
   - Keep: gesture handling, display link loop, physics integration
   - Update: references to scene, any fusion-core-specific logic

2. **`Thrumi/3D/SpinnerPhysics.swift`** → Keep but review
   - Core physics (angular velocity, damping) still applies
   - May need adjustment for wisp orbital mechanics
   - Consider renaming to `OrbitalPhysics.swift`

3. **`Thrumi/3D/StateInterpolator.swift`** → Modify significantly
   - Update parameter mappings for wisp-specific values:
     - `wispCount` (Int)
     - `baseOrbitSpeed` (Float)
     - `colorPalette` or `colorTemperature` (Float)
     - `brightness` (Float)
     - `showTrails` (Bool)
   - Remove fusion-core-specific properties (ringRoughness, coilGlow, sparkIntensity, etc.)

4. **`Thrumi/3D/MultiFrequencyPulse.swift`** → Keep or simplify
   - Pulse system can still drive wisp "breathing"
   - May simplify to single frequency

5. **`Thrumi/3D/HapticsManager.swift`** → Keep, minor updates
   - Haptic feedback still relevant for flicks
   - May adjust feel for "magical" rather than "industrial"

6. **`Thrumi/3D/ThermalManager.swift`** → Keep as-is
   - Still useful for reducing wisp count under thermal pressure

7. **`Thrumi/3D/ReducedMotionSupport.swift`** → Keep, update config
   - Reduce orbital speed, disable trails for reduced motion

8. **`Thrumi/3D/MotionManager.swift`** → Keep as-is (if used for device tilt)

### Files that reference FusionCoreView (search and update):

- `Thrumi/Views/CoreView.swift` — update import and usage
- `Thrumi/Views/Onboarding/CoreTutorialStep.swift` — update reference
- Any other views that embed the 3D spinner

### Documentation to Update:

- `CONVENTIONS.md` — update 3D-related patterns if they change
- `docs/PRODUCT.md` — note that visual implementation differs from original spec, or update spec

---

## Implementation Approach

### New Core Classes

#### `Wisp.swift`
```swift
import RealityKit
import UIKit

@MainActor
final class Wisp {
    let entity: ModelEntity

    // Orbital parameters
    var orbitRadius: Float
    var orbitSpeed: Float      // Individual speed multiplier
    var orbitPhase: Float      // Starting angle
    var orbitTilt: simd_quatf  // Tilted orbital plane

    // Visual parameters
    var baseColor: UIColor
    var brightness: Float
    var scale: Float

    // Animation state
    private var breathingPhase: Float = 0

    static func create(
        color: UIColor,
        orbitRadius: Float,
        orbitTilt: simd_quatf,
        speedMultiplier: Float
    ) -> Wisp

    func update(deltaTime: Float, globalSpinAngle: Float, breathingPulse: Float)
    // Updates position based on orbit parameters + global spin
    // Applies breathing scale animation

    func fadeIn(duration: Float)
    func fadeOut(duration: Float) -> Bool  // Returns true when fully faded
}
```

#### `WispOrbScene.swift`
```swift
import RealityKit
import UIKit

@MainActor
final class WispOrbScene {
    let rootEntity: Entity

    private var wisps: [Wisp] = []
    private var targetWispCount: Int = 5
    private var currentColorPalette: [UIColor] = []

    // Optional container
    private var containerEntity: Entity?

    // Optional trail system
    private var trailSystem: WispTrailSystem?

    static func create() async -> WispOrbScene

    func update(
        interpolator: StateInterpolator,
        spinAngle: Float,
        deltaTime: Float,
        breathingPulse: Float
    )

    // Smoothly add/remove wisps when target count changes
    private func adjustWispCount(to target: Int, palette: [UIColor])

    // Micro-feedback triggers
    func triggerOnTrackFeedback()
    func triggerOffTrackFeedback()
}
```

### Wisp Orbital Math

Each wisp orbits on its own tilted plane:
```swift
func updatePosition(globalSpinAngle: Float) {
    let angle = orbitPhase + globalSpinAngle * orbitSpeed

    // Base circular orbit
    var position = SIMD3<Float>(
        orbitRadius * cos(angle),
        0,
        orbitRadius * sin(angle)
    )

    // Apply individual orbital tilt
    position = orbitTilt.act(position)

    entity.position = position

    // Point wisp along direction of travel (optional, for teardrop shape)
    let tangent = SIMD3<Float>(-sin(angle), 0, cos(angle))
    let tiltedTangent = orbitTilt.act(tangent)
    // Orient entity to face movement direction
}
```

### Wisp Geometry

Teardrop/flame shape using custom mesh or elongated sphere:
```swift
static func createWispMesh() -> MeshResource {
    // Option 1: Elongated sphere
    // Create sphere, scale Y axis

    // Option 2: Custom teardrop mesh
    // Generate vertices for teardrop shape

    // Start simple with sphere, iterate if needed
    return MeshResource.generateSphere(radius: 0.015)
}
```

### Color Palette Definition

```swift
struct WispColors {
    // Base palette - soft, magical tones
    static let coolBlue = UIColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1)
    static let deepBlue = UIColor(red: 0.3, green: 0.4, blue: 0.8, alpha: 1)
    static let teal = UIColor(red: 0.3, green: 0.8, blue: 0.8, alpha: 1)
    static let cyan = UIColor(red: 0.4, green: 0.9, blue: 0.95, alpha: 1)
    static let purple = UIColor(red: 0.7, green: 0.5, blue: 0.9, alpha: 1)
    static let violet = UIColor(red: 0.6, green: 0.4, blue: 0.9, alpha: 1)
    static let gold = UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1)
    static let amber = UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1)
    static let pink = UIColor(red: 1.0, green: 0.6, blue: 0.8, alpha: 1)
    static let rose = UIColor(red: 1.0, green: 0.5, blue: 0.7, alpha: 1)
    static let white = UIColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 1)

    /// Returns color palette appropriate for adherence level
    static func palette(for adherence: Float) -> [UIColor] {
        switch adherence {
        case 0..<0.3:
            return [coolBlue, deepBlue]
        case 0.3..<0.5:
            return [coolBlue, teal, cyan]
        case 0.5..<0.7:
            return [teal, purple, violet]
        case 0.7..<0.85:
            return [teal, gold, pink, purple]
        default:
            return [white, gold, pink, teal, cyan, purple]
        }
    }

    /// Brightness multiplier for adherence level
    static func brightness(for adherence: Float) -> Float {
        // 0.4 at 0%, 1.0 at 100%
        return 0.4 + adherence * 0.6
    }
}
```

---

## StateInterpolator Updates

Remove these fusion-core-specific properties:
- `bloomStrength`
- `glowMultiplier`
- `innerCoreColor`
- `ringRoughness`
- `coilGlowIntensity`
- `coreLightIntensity`
- `coilLightIntensity`
- `sparkIntensity`
- `arcIntensity`
- `flashIntensity`
- `showEnergyField1/2`
- `showAtmosphere`

Add these wisp-specific properties:
```swift
/// Number of wisps to display
var wispCount: Int {
    switch adherence {
    case 0..<0.2: return Int(lerp(3, 5, adherence / 0.2))
    case 0.2..<0.5: return Int(lerp(6, 12, (adherence - 0.2) / 0.3))
    case 0.5..<0.8: return Int(lerp(12, 22, (adherence - 0.5) / 0.3))
    default: return Int(lerp(22, 30, (adherence - 0.8) / 0.2))
    }
}

/// Base orbital speed multiplier
var baseOrbitSpeed: Float {
    piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.3, yMid: 0.7, y1: 1.2)
}

/// Wisp brightness multiplier
var wispBrightness: Float {
    lerp(0.4, 1.0, adherence)
}

/// Whether to show particle trails
var showTrails: Bool {
    adherence >= 0.7
}

/// Color palette for current state
var colorPalette: [UIColor] {
    WispColors.palette(for: adherence)
}

/// Breathing/pulse amplitude
var breathingAmplitude: Float {
    piecewiseLerp(x: adherence, xMid: 0.5, y0: 0.02, yMid: 0.06, y1: 0.12)
}
```

---

## What to Preserve (Do Not Modify)

- **`AdherenceState.swift`** — adherence calculation unchanged
- **`AdherenceEngine.swift`** — data logic unchanged
- **`MealService.swift`** — unchanged
- **`Meal.swift`, `UserSettings.swift`** — data models unchanged
- **App navigation structure** — unchanged
- **Meal logging flow** — unchanged
- **Data persistence** — unchanged

---

## Cleanup Checklist

After implementation, verify:
- [ ] No files in `Thrumi/3D/` contain "FusionCore", "Reactor", or "Spinner" in filename
- [ ] No source code references deleted classes (`ReactorCore`, `SpinnerRings`, etc.)
- [ ] `grep -r "FusionCore" Thrumi/` returns no results (except maybe comments explaining the change)
- [ ] `grep -r "ReactorCore" Thrumi/` returns no results
- [ ] All previews in `WispOrbView.swift` build and display correctly
- [ ] Build succeeds with zero errors
- [ ] App runs on simulator without crashes

---

## Testing Checklist

- [ ] Wisps render and orbit correctly at all adherence levels
- [ ] Flick gesture spins wisps faster
- [ ] Wisp count changes smoothly when adherence changes
- [ ] Colors shift appropriately across adherence spectrum
- [ ] Micro-feedback triggers on meal log (if implemented)
- [ ] Haptics fire on flick
- [ ] Reduced motion setting reduces/stops orbital animation
- [ ] Thermal throttling reduces wisp count
- [ ] Performance is smooth 60fps on device

---

## Success Criteria

The Orb of Wisps implementation is successful if:

1. **Mesmerizing:** The orbital motion is hypnotic and pleasant to watch
2. **Fidget-worthy:** Flicking to spin feels satisfying and responsive
3. **State-readable:** Adherence level is immediately apparent (more wisps, faster, brighter = better)
4. **Stylistically cohesive:** Looks intentionally stylized/magical, not "failed realism"
5. **Performant:** Smooth 60fps on device, not just simulator
6. **Complete:** No remnants of fusion core design remain
