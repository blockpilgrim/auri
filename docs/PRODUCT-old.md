# Thrumi: Fusion Core — Concept Brief

---

## 1. Executive Summary

Thrumi is a mobile diet-adherence tracker that makes progress **felt** rather than counted. Instead of spreadsheets, streak pressure, or macro dashboards as the primary experience, Thrumi centers a single interactive object: the **Fusion Core**—a magnetically-levitated, industrial high-tech **3D fidget spinner** that feels like a piece of bleeding-edge clean energy technology.

The Fusion Core’s **spin quality, stability, speed ceiling, and light output** embody the user’s adherence on a 0–100% continuum. As adherence rises, the Core becomes smoother, faster, more visually striking, and more “impossible” in its levitation. As adherence falls, the Core enters a calm, safe low-power mode—still premium and beautiful, just less fidget-worthy.

The app is a trojan horse: the underlying system is evidence-based (dietary adherence and habit tracking), but the interface replaces judgmental numbers with an object users want to return to.

> **One-line pitch:** Keep your reactor online—aligned choices make your Fusion Core faster, smoother, and more electric to play with.

---

## 2. Problem Statement

### The Market Gap

Most diet apps lose users because:

- **Logging feels like homework.** Many products require precision and attention users don’t want to give.
- **Feedback is abstract.** Charts and progress bars don’t create a visceral reward.
- **Slip-ups trigger avoidance.** Red days, broken streaks, and “failure” messaging cause shame and churn.

### The Opportunity

There’s a large audience who wants to eat better but won’t sustain a spreadsheet experience. They value:

- simplicity over completeness
- immediate, emotionally resonant feedback
- recovery that feels possible after a bad day

Thrumi is designed for these users first.

---

## 3. Core Philosophy

### The Shift

In traditional trackers, **data equals feedback**.

In Thrumi, **feel equals feedback**.

Numbers exist (for users who want them), but the primary motivator is a physical, satisfying object whose behavior is meaningfully tied to adherence.

### Emotional Design Principles

- **Non-judgmental:** the Core never scolds.
- **Recoverable:** the Core never “dies,” breaks, or becomes ugly.
- **Embodied reward:** better choices make the Core *better to use*, not just “more green.”
- **Stability over drama:** low adherence is “standby,” not collapse.

---

## 4. The Fusion Core

The Fusion Core is a procedural 3D fidget spinner inspired by Tony Stark's arc reactor: **machined precision** plus an **alive** glow. It should feel like a functional power module, not a toy.

### Visual Language (Industrial High-Tech)

- **Materials:** brushed palladium/steel, machined chamfers, exposed copper coils, translucent ceramic/glass elements.
- **Center:** contained energy field (procedural glow), *not* fluid simulation.

### Particle Effects

Particles are essential for communicating power state. They scale with adherence.

**Sparks:**
- Small glowing particles (teal or orange, randomized) emitting from ring positions
- Appear at 20%+ adherence
- Drift outward/upward, fade over 0.3-0.8 seconds
- Frequency: none at 0%, occasional at 50%, constant stream at 100%

**Energy Arcs:**
- Lightning-like jagged lines
- Appear at 50%+ adherence only
- Last 100-250ms, then disappear
- More frequent and brighter at higher power

**Flashes:**
- Bright burst pulses at the core (quick expand then fade)
- Appear at 60%+ adherence only
- At 80%+, increased amount of spawn around spinner
- Duration: 150-250ms

**At 0-20% adherence:** No particles. The Core is calm and quiet.

### The Reactor Pulse (Alive without anxiety)

The Core has a slow, steady **power pulse** (visual only): a gentle emissive swell that suggests a running system.

- **Pulse rate is constant** (not tied to adherence) to avoid “heart rate” associations.
- Adherence affects **amplitude, sharpness, and harmonic richness** of the light (not the tempo).

---

## 5. How It Works

### The Daily Loop

1. User opens the app.
2. Logs a meal (photo or text).
3. Taps **On track** or **Off track** (user-defined).
4. Fusion Core updates instantly.
5. User optionally spins the Core because it’s satisfying.

### What Drives the Core

**Primary driver: adherence percentage** derived from on/off-track tags.

#### Blended State (Core Behavior)

The Fusion Core’s *overall* state is driven by a blend of:

- **Today adherence**
- **Past 7 Days adherence (rolling)**

Recommended weighting (tunable):

```
coreAdherence = 0.60 * todayAdherence + 0.40 * rolling7Adherence
```

Design intent:

- Today matters immediately.
- One bad day doesn’t erase the experience.
- Patterns still show up in the Core.

#### Micro-Feedback (Per Log)

Even though the baseline is blended, each meal produces immediate feedback:

- **On track:** a brief “field alignment” beat (particle effects, glow brightens).
- **Off track:** a brief “stabilization” beat (lessening effects, glow softens).

This keeps the app responsive moment-to-moment.

### State Persistence

- **Rolling 7:** always rolling, no hard reset.
- **Today:** resets daily.

No streak-break punishment. The experience is continuous and recoverable.

---

## 6. The Reward Curve (“Awesome” Calibration)

To ensure **80% feels awesome** and **50% and below is not punishing**, Thrumi uses a non-linear mapping from adherence → “awesomeness.”

Design behavior:

- **0–50%:** reduced capability (lower speed ceiling, higher damping) but still premium.
- **50–80%:** biggest gains (smoothness, stability authority, glow richness).
- **80–100%:** refinement and signature coherence; 100% is peak and always-on.

Implementation hint (one option): apply an ease-out curve to perceived power:

```
power = 1 - pow(1 - coreAdherence, k)   // k ~ 2.0–3.0
```

This makes improvements feel meaningful early, while keeping 80–100 close.

---

## 7. State Spectrum (Five-Tier Framework)

The Fusion Core transitions smoothly across 0–100%, but these tiers are a shared vocabulary.

| Core Adherence | State | Metaphor | Core Impression |
|---:|---|---|---|
| 90–100% | **Phase-Locked** | sustained coherent field | peak stability and speed; perfect concentric levitation; richest light |
| 70–89% | **Online** | reactor stable | very smooth, bright, high-speed, satisfying |
| 50–69% | **Stabilizing** | output building | solid fidget feel; moderate glow; minor field noise |
| 30–49% | **Standby** | conservation mode | lower speed ceiling; higher damping; simplified effects |
| 0–29% | **Safe Mode** | containment prioritized | gentle, calm spin; minimal bloom; still elegant |

### Tier Detail (What Actually Changes)

**Phase-Locked (90–100%) — Always-on peak (100% is unmistakable):**

- Highest speed ceiling; longest spin persistence.
- Light is bright but controlled: rich bloom, crisp highlights, subtle volumetric rays.

**Online (70–89%):**

- Very smooth; strong stabilization.
- High speed, satisfying persistence.
- Glow and coil illumination are strong; field effects present but restrained.

**Stabilizing (50–69%):**

- Good fidget feel; stability is present but less assertive.
- Moderate speed ceiling.
- Simplified glow; occasional minor “field noise” (tiny alignment drift that self-corrects).

**Standby (30–49%):**

- Damping noticeably higher; spins slow sooner.
- Lower speed ceiling.
- Glow is quieter; bloom reduced; fewer secondary effects.

**Safe Mode (0–29%):**

- Very calm; containment prioritized.
- Lowest speed ceiling and persistence.
- Minimal bloom; core reads as “protected,” not broken.

**Guardrail:** low tiers must still look intentional, premium, and worth opening.

---

## 8. Interaction Model (Fusion Core-First)

### Meal Logging

- **Primary:** photo capture → confirm → **On track** / **Off track**
- **Alternative:** quick text entry → **On track** / **Off track**

The app does not interpret what “on track” means. The user defines alignment relative to their goal.

### Fidget Interactions

The Fusion Core should be genuinely satisfying even when a user is idle.

| Gesture | Response | What adherence modulates |
|---|---|---|
| Flick / swipe | imparts torque and spin | max speed, spin persistence, smoothness |
| Two-finger twist | precise spin control | fine control resolution, micro-jitter |
| Tilt (device motion) | subtle gyroscopic precession | precession clarity and damping |
| Tap | localized coil “ping” (light tick) | intensity and crispness |

### Haptics (Optional)

Haptics can amplify “machined precision” without adding shame:

- high adherence: crisp micro-impulses on phase-lock events and clean collisions
- low adherence: softer, more damped feedback

Sound is intentionally not required for the core experience.

---

## 9. Emotional Design: The Failure Mode

Low adherence should never feel like punishment. The narrative is:

- **Standby / Safe Mode = stabilization and conservation**
- the system is waiting to be brought back online

Avoid:

- harsh red “error” states
- streak loss language
- dramatic collapse animations
- copy implying moral failure

---

## 10. Why Users Will Return

1. **It’s a real fidget object.** Users will open the app just to spin the Core.
2. **Progress is embodied.** Better adherence makes the Core objectively more satisfying.
3. **Recovery is immediate.** One aligned meal produces a noticeable stabilization shift.
4. **It’s not shame-based.** The Core is always dignified; it only changes power mode.

---

## 11. Dietary Goals (MVP)

Users select a goal during onboarding to contextualize “on track.”

- Keto / low-carb
- Vegetarian
- Vegan
- Mediterranean
- Whole/minimally processed
- Low sugar
- High protein
- Whole30 / paleo
- Custom (free text)

---

## 12. Product Tiers

### Free Tier

| Feature | Details |
|---|---|
| Meal logging | photo or text, unlimited |
| Adherence tracking | on track / off track tagging |
| Metrics | Today, Past 7 Days (rolling), Past 30 Days (rolling) |
| Fusion Core | full visual + interaction spectrum |
| Meal history | daily list, on/off markers |

---

## 13. Information Architecture

### Primary Screens

1. **Core View (Home)** — full-screen Fusion Core
2. **Log Meal** — capture + on/off track
3. **Data View** — metrics + history
4. **Premium Insights** (if upgraded)

### Number Surfaces

#### Core View (Home)

Display **Today’s adherence** subtly (not dashboard-y):

- small HUD text anchored top-left or bottom-left
- format: `TODAY 82%`

The Fusion Core itself reflects the blended state (Today + Past 7 Days). To avoid confusion without adding labels on Home:

- use a one-time tooltip in week one (e.g., “Core reflects Today + Past 7 Days”)
- keep the explanation in the Data view.

#### Data View

Top section shows three rolling metrics:

- **Today**
- **Past 7 Days** (rolling)
- **Past 30 Days** (rolling)

Then:

- **Meal history** grouped by day, each entry marked On/Off track.

---

## 14. Onboarding

Target: under 60 seconds to first meaningful interaction.

1. Welcome: “Thrumi keeps your reactor online.”
2. Select dietary goal.
3. Meet your Fusion Core: quick tutorial (flick to spin).
4. Prompt to log your next meal.

---

## 15. Technical Approach (High-Level)

### Platform

- iOS-first.

### Rendering

- Prefer a modern 3D pipeline (RealityKit/SceneKit/Metal) with physically-based materials.
- Procedural geometry or modular kit-bashed components assembled procedurally.
- Bloom/volumetric glow tuned to feel premium but performant.

### Motion & “Feel”

- Spinner physics model tuned for satisfaction (torque response, damping, stability control).
- State interpolation across adherence for:
  - max angular velocity
  - damping/friction
  - stabilization authority (wobble suppression)
  - light output and effect density

### Accessibility

- Reduce Motion: offer a calmer mode (less precession and fewer secondary effects) while preserving state differentiation.

---

## 16. MVP Scope

### In Scope

- Fusion Core 3D spinner (unique procedural design, not a prop copy)
- Full state spectrum driven by blended adherence (Today + rolling 7)
- Non-linear reward curve so 80% is near-peak
- Meal logging (photo/text) with on/off track
- Data view with Today / Past 7 / Past 30 + meal history

### Out of Scope (MVP)

- Fluid simulation
- Shame mechanics (broken streaks, punitive visuals)
- Social features (sharing, leaderboards)
- Notifications
- Wearables / HealthKit

---

## 17. Glossary

| Term | Definition |
|---|---|
| **Fusion Core** | the central 3D levitating fidget spinner that visualizes adherence |
| **On track / Off track** | user-tagged alignment of a meal with their chosen dietary goal |
| **Today adherence** | ratio of on-track meals to total meals logged today |
| **Past 7 Days** | rolling 7-day adherence ratio |
| **Past 30 Days** | rolling 30-day adherence ratio |
| **Core adherence** | blended value that drives the Core’s visual + physical state |
| **Phase-Locked** | peak state where the Core feels perfectly stable and coherent |
