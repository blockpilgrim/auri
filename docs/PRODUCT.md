# Thrumi: Orb of Wisps — Concept Brief

---

## 1. Executive Summary

Thrumi is a mobile diet-adherence tracker that makes progress **felt** rather than counted. Instead of spreadsheets, streak pressure, or macro dashboards as the primary experience, Thrumi centers a single interactive object: the **Orb of Wisps**—a magical, stylized 3D orb containing orbiting spirit-like entities that feels like something from a fantasy game or Studio Ghibli film.

The Orb's **wisp count, orbital speed, color richness, and brightness** embody the user's adherence on a 0–100% continuum. As adherence rises, the Orb becomes more vibrant, more populated with wisps, faster, and more mesmerizing. As adherence falls, the Orb enters a calm, gentle state—still beautiful and magical, just more subdued.

The app is a trojan horse: the underlying system is evidence-based (dietary adherence and habit tracking), but the interface replaces judgmental numbers with an object users want to return to.

> **One-line pitch:** Keep your wisps thriving—aligned choices make your Orb more vibrant, more alive, and more magical to play with.

---

## 2. Problem Statement

### The Market Gap

Most diet apps lose users because:

- **Logging feels like homework.** Many products require precision and attention users don't want to give.
- **Feedback is abstract.** Charts and progress bars don't create a visceral reward.
- **Slip-ups trigger avoidance.** Red days, broken streaks, and "failure" messaging cause shame and churn.

### The Opportunity

There's a large audience who wants to eat better but won't sustain a spreadsheet experience. They value:

- simplicity over completeness
- immediate, emotionally resonant feedback
- recovery that feels possible after a bad day

Thrumi is designed for these users first.

---

## 3. Core Philosophy

### The Shift

In traditional trackers, **data equals feedback**.

In Thrumi, **feel equals feedback**.

Numbers exist (for users who want them), but the primary motivator is a magical, satisfying object whose behavior is meaningfully tied to adherence.

### Emotional Design Principles

- **Non-judgmental:** the Orb never scolds.
- **Recoverable:** the Orb never "dies," breaks, or becomes ugly.
- **Embodied reward:** better choices make the Orb *better to interact with*, not just "more green."
- **Stability over drama:** low adherence is "resting," not collapse.

---

## 4. The Orb of Wisps

The Orb of Wisps is a procedural 3D magical orb inspired by fantasy mana orbs, Studio Ghibli magic, and games like Ori and the Blind Forest. It should feel like a living, mystical artifact—not a toy or a game UI element.

### Visual Language (Magical / Stylized)

- **Style:** Cel-shaded, stylized—NOT photorealistic
- **Materials:** `UnlitMaterial` with bright, saturated colors for flat, magical appearance
- **Colors:** Soft, magical palette—teals, purples, pinks, golds, cool blues
- **Center:** Translucent or invisible container with orbiting wisp spirits

### Wisps

Wisps are the core visual element—small teardrop/flame-shaped spirits that orbit the center.

**Wisp Properties:**
- Geometry: Small elongated spheres (teardrop/flame shape)
- Size variation: 0.8x to 1.2x base size for organic feel
- Orbit on individual tilted planes (not all on same plane)
- Each wisp has unique speed multiplier for organic motion

**Wisp Count by Adherence:**
| Adherence | Wisp Count |
|-----------|------------|
| 0-20%     | 3-5 wisps (minimal, calm) |
| 20-50%    | 6-12 wisps |
| 50-80%    | 12-22 wisps |
| 80-100%   | 22-30 wisps (vibrant, full) |

**Colors by Adherence:**
| Adherence | Color Palette |
|-----------|---------------|
| 0-30%     | Cool blues, dim |
| 30-50%    | Blue-teal |
| 50-70%    | Teal-purple |
| 70-85%    | Gold-teal-pink |
| 85-100%   | Full spectrum, white cores |

### The Breathing Animation (Alive without anxiety)

The Orb has a slow, steady **breathing pulse**: a gentle scale swell on each wisp that suggests living energy.

- **Pulse rate is constant** (not tied to adherence) to avoid "heart rate" associations.
- Adherence affects **amplitude** of the breathing (subtle at low, pronounced at high).

---

## 5. How It Works

### The Daily Loop

1. User opens the app.
2. Logs a meal (photo or text).
3. Taps **On track** or **Off track** (user-defined).
4. Orb updates instantly—wisps brighten or dim, one may appear or fade.
5. User optionally plays with the Orb because it's satisfying.

### What Drives the Orb

**Primary driver: adherence percentage** derived from on/off-track tags.

#### Blended State (Orb Behavior)

The Orb's *overall* state is driven by a blend of:

- **Today adherence**
- **Past 7 Days adherence (rolling)**

Recommended weighting (tunable):

```
coreAdherence = 0.60 * todayAdherence + 0.40 * rolling7Adherence
```

Design intent:

- Today matters immediately.
- One bad day doesn't erase the experience.
- Patterns still show up in the Orb.

#### Micro-Feedback (Per Log)

Even though the baseline is blended, each meal produces immediate feedback:

- **On track:** wisps briefly accelerate and pulse brighter; a new wisp may fade in.
- **Off track:** wisps briefly slow; one wisp gently fades out.

This keeps the app responsive moment-to-moment.

### State Persistence

- **Rolling 7:** always rolling, no hard reset.
- **Today:** resets daily.

No streak-break punishment. The experience is continuous and recoverable.

---

## 6. The Reward Curve ("Awesome" Calibration)

To ensure **80% feels awesome** and **50% and below is not punishing**, Thrumi uses a non-linear mapping from adherence → "awesomeness."

Design behavior:

- **0–50%:** fewer wisps, slower orbit, cooler colors—but still beautiful.
- **50–80%:** biggest gains (more wisps, richer colors, faster orbits).
- **80–100%:** refinement and peak vibrancy; 100% is unmistakably magical.

Implementation hint (one option): apply an ease-out curve to perceived power:

```
power = 1 - pow(1 - coreAdherence, k)   // k ~ 2.0–3.0
```

This makes improvements feel meaningful early, while keeping 80–100 close.

---

## 7. State Spectrum (Five-Tier Framework)

The Orb transitions smoothly across 0–100%, but these tiers are a shared vocabulary.

| Core Adherence | State | Metaphor | Orb Impression |
|---:|---|---|---|
| 90–100% | **Radiant** | full magical resonance | Peak vibrancy; maximum wisps; full color spectrum; fastest orbits |
| 70–89% | **Vibrant** | strong magical energy | Many wisps; warm colors; satisfying speed |
| 50–69% | **Awakening** | gathering energy | Moderate wisps; teal-purple tones; steady motion |
| 30–49% | **Resting** | conserving energy | Fewer wisps; cooler colors; gentle drift |
| 0–29% | **Dreaming** | deep rest | Minimal wisps; dim cool blues; very calm |

### Tier Detail (What Actually Changes)

**Radiant (90–100%) — Peak magic (100% is unmistakable):**

- Maximum wisp count (22-30)
- Full color spectrum including white cores
- Fastest orbital speed, longest spin persistence
- Breathing animation most pronounced

**Vibrant (70–89%):**

- Many wisps (15-22)
- Warm colors: golds, teals, pinks
- High orbital speed, satisfying spin persistence
- Strong brightness

**Awakening (50–69%):**

- Moderate wisp count (10-14)
- Teal and purple tones
- Medium orbital speed
- Visible but not overwhelming

**Resting (30–49%):**

- Fewer wisps (6-9)
- Blue-teal colors
- Gentle orbital drift
- Subdued brightness

**Dreaming (0–29%):**

- Minimal wisps (3-5)
- Cool blues only
- Very slow drift
- Calm and peaceful, not broken

**Guardrail:** low tiers must still look intentional, beautiful, and worth opening.

---

## 8. Interaction Model (Orb-First)

### Meal Logging

- **Primary:** photo capture → confirm → **On track** / **Off track**
- **Alternative:** quick text entry → **On track** / **Off track**

The app does not interpret what "on track" means. The user defines alignment relative to their goal.

### Fidget Interactions

The Orb should be genuinely satisfying even when a user is idle. Rich interactivity is key.

| Gesture | Response | What adherence modulates |
|---|---|---|
| Flick / swipe | imparts spin to wisps | max speed, spin persistence |
| Tap | wisps scatter outward, then return | scatter intensity |
| Double tap | sparkle burst effect | burst intensity |
| Long press + drag | wisps attracted to finger | attraction strength |
| Pinch | expand/contract orbital radius | radius limits |
| Two-finger twist | tilt orbital plane | tilt range |
| Device shake | chaos mode (erratic orbits) | chaos intensity |

### Haptics

Haptics amplify the magical feel:

- high adherence: crisp, sparkly feedback
- low adherence: softer, more ethereal feedback

Sound is intentionally not required for the core experience.

---

## 9. Emotional Design: The Low State

Low adherence should never feel like punishment. The narrative is:

- **Resting / Dreaming = the Orb is conserving energy, waiting**
- the wisps are patient, ready to awaken

Avoid:

- harsh red "error" states
- streak loss language
- dramatic collapse animations
- copy implying moral failure

---

## 10. Why Users Will Return

1. **It's a real fidget object.** Users will open the app just to play with the Orb.
2. **Progress is embodied.** Better adherence makes the Orb objectively more magical.
3. **Recovery is immediate.** One aligned meal produces a noticeable brightening.
4. **It's not shame-based.** The Orb is always beautiful; it only changes energy level.

---

## 11. Dietary Goals (MVP)

Users select a goal during onboarding to contextualize "on track."

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
| Orb of Wisps | full visual + interaction spectrum |
| Meal history | daily list, on/off markers |

---

## 13. Information Architecture

### Primary Screens

1. **Orb View (Home)** — full-screen Orb of Wisps
2. **Log Meal** — capture + on/off track
3. **Data View** — metrics + history
4. **Premium Insights** (if upgraded)

### Number Surfaces

#### Orb View (Home)

Display **Today's adherence** subtly (not dashboard-y):

- small HUD text anchored top-left or bottom-left
- format: `TODAY 82%`

The Orb itself reflects the blended state (Today + Past 7 Days). To avoid confusion without adding labels on Home:

- use a one-time tooltip in week one (e.g., "Orb reflects Today + Past 7 Days")
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

1. Welcome: "Meet your Orb of Wisps."
2. Select dietary goal.
3. Meet your Orb: quick tutorial (flick to spin the wisps).
4. Prompt to log your next meal.

---

## 15. Technical Approach (High-Level)

### Platform

- iOS-first.

### Rendering

- RealityKit with `UnlitMaterial` for cel-shaded, flat-color aesthetic.
- Procedural wisp entities with individual orbital parameters.
- No bloom/glow shaders needed—brightness achieved through color saturation.

### Motion & "Feel"

- Spinner physics model tuned for satisfaction (torque response, damping).
- State interpolation across adherence for:
  - wisp count
  - orbital speed
  - color palette
  - brightness
  - breathing amplitude

### Accessibility

- Reduce Motion: offer a calmer mode (slower orbits, no trails) while preserving state differentiation through color/brightness.

---

## 16. MVP Scope

### In Scope

- Orb of Wisps 3D visualization (stylized magical orb with orbiting wisps)
- Full state spectrum driven by blended adherence (Today + rolling 7)
- Non-linear reward curve so 80% is near-peak
- Rich fidget interactions (flick, tap, double-tap, long-press, pinch, twist, shake)
- Meal logging (photo/text) with on/off track
- Data view with Today / Past 7 / Past 30 + meal history

### Out of Scope (MVP)

- Photorealistic rendering
- Shame mechanics (broken streaks, punitive visuals)
- Social features (sharing, leaderboards)
- Notifications
- Wearables / HealthKit

---

## 17. Glossary

| Term | Definition |
|---|---|
| **Orb of Wisps** | the central 3D magical orb that visualizes adherence |
| **Wisp** | an individual spirit-like entity orbiting within the Orb |
| **On track / Off track** | user-tagged alignment of a meal with their chosen dietary goal |
| **Today adherence** | ratio of on-track meals to total meals logged today |
| **Past 7 Days** | rolling 7-day adherence ratio |
| **Past 30 Days** | rolling 30-day adherence ratio |
| **Core adherence** | blended value that drives the Orb's visual + interaction state |
| **Radiant** | peak state where the Orb is at maximum vibrancy |
