# Auri: Your Light, Visualized — Concept Brief

---

## 1. Executive Summary

Auri is a mobile diet-adherence tracker that makes progress **felt** rather than counted. Instead of spreadsheets, streak pressure, or macro dashboards as the primary experience, Auri centers a single interactive object: **Your Auri**—a luminous 3D orb containing orbiting sparks of light that feels like something from a fantasy game or Studio Ghibli film.

Your Auri's **spark count, orbital speed, color richness, and brightness** embody your adherence on a 0–100% continuum. As adherence rises, your Auri becomes more vibrant, more populated with sparks, faster, and more mesmerizing. As adherence falls, your Auri enters a calm, gentle state—still beautiful and magical, just more subdued.

The app is a trojan horse: the underlying system is evidence-based (dietary adherence and habit tracking), but the interface replaces judgmental numbers with an object users want to return to.

### The Science Behind the Magic

Your body glows. Not metaphorically—your cells actually emit light. **Biophotons.** These ultraweak photon emissions are a real biological phenomenon: the healthier your cells, the more coherent and vibrant the light they produce.

Auri makes this invisible light visible. The sparks in your Auri represent your cellular radiance, powered by what you eat. Every aligned meal adds to your glow.

> **One-line pitch:** See what nourishment creates—your choices, glowing.

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

Auri is designed for these users first.

---

## 3. Core Philosophy

### The Shift

In traditional trackers, **data equals feedback**.

In Auri, **feel equals feedback**.

Numbers exist (for users who want them), but the primary motivator is a luminous, satisfying object whose behavior is meaningfully tied to adherence.

### The Biophoton Connection

The metaphor isn't arbitrary. Biophotons are real:

- Your cells emit faint light as a byproduct of metabolic processes
- Healthier cellular function produces more coherent light
- What you eat directly affects cellular health and, by extension, this inner glow

Auri visualizes this truth. The sparks orbiting inside your Auri are a representation of the light your body actually produces.

### Emotional Design Principles

- **Non-judgmental:** your Auri never scolds.
- **Recoverable:** your Auri never "dies," breaks, or becomes ugly.
- **Embodied reward:** better choices make your Auri *better to interact with*, not just "more green."
- **Stability over drama:** low adherence is "resting," not collapse.

---

## 4. Your Auri

Your Auri is a procedural 3D luminous orb inspired by biophoton science, fantasy mana orbs, Studio Ghibli magic, and games like Ori and the Blind Forest. It should feel like a living, mystical artifact—a visualization of your inner light.

### Visual Language (Magical / Stylized)

- **Style:** Cel-shaded, stylized—NOT photorealistic
- **Materials:** `UnlitMaterial` with bright, saturated colors for flat, magical appearance
- **Colors:** Soft, magical palette—teals, purples, pinks, golds, cool blues
- **Center:** Translucent or invisible container with orbiting sparks of light

### Sparks

Sparks are the core visual element—small luminous particles that orbit the center, representing your cellular light.

**Spark Properties:**
- Geometry: Small elongated spheres (teardrop/flame shape)
- Size variation: 0.8x to 1.2x base size for organic feel
- Orbit on individual tilted planes (not all on same plane)
- Each spark has unique speed multiplier for organic motion

**Spark Count by Adherence:**
| Adherence | Spark Count |
|-----------|-------------|
| 0-20%     | 3-5 sparks (minimal, calm) |
| 20-50%    | 6-12 sparks |
| 50-80%    | 12-22 sparks |
| 80-100%   | 22-30 sparks (vibrant, full) |

**Colors by Adherence:**
| Adherence | Color Palette |
|-----------|---------------|
| 0-30%     | Cool blues, dim |
| 30-50%    | Blue-teal |
| 50-70%    | Teal-purple |
| 70-85%    | Gold-teal-pink |
| 85-100%   | Full spectrum, white cores |

### The Breathing Animation (Alive without anxiety)

Your Auri has a slow, steady **breathing pulse**: a gentle scale swell on each spark that suggests living energy.

- **Pulse rate is constant** (not tied to adherence) to avoid "heart rate" associations.
- Adherence affects **amplitude** of the breathing (subtle at low, pronounced at high).

---

## 5. How It Works

### The Daily Loop

1. User opens the app.
2. Logs a meal (photo or text).
3. Taps **On track** or **Off track** (user-defined).
4. Auri updates instantly—sparks brighten or dim, one may appear or fade.
5. User optionally plays with their Auri because it's satisfying.

### What Drives Your Auri

**Primary driver: adherence percentage** derived from on/off-track tags.

#### Blended State (Auri Behavior)

Your Auri's *overall* state is driven by a blend of:

- **Today adherence**
- **Past 7 Days adherence (rolling)**

Recommended weighting (tunable):

```
coreAdherence = 0.60 * todayAdherence + 0.40 * rolling7Adherence
```

Design intent:

- Today matters immediately.
- One bad day doesn't erase the experience.
- Patterns still show up in your Auri.

#### Micro-Feedback (Per Log)

Even though the baseline is blended, each meal produces immediate feedback:

- **On track:** sparks briefly accelerate and pulse brighter; a new spark may fade in.
- **Off track:** sparks briefly slow; one spark gently fades out.

This keeps the app responsive moment-to-moment.

### State Persistence

- **Rolling 7:** always rolling, no hard reset.
- **Today:** resets daily.

No streak-break punishment. The experience is continuous and recoverable.

---

## 6. The Reward Curve ("Radiant" Calibration)

To ensure **80% feels radiant** and **50% and below is not punishing**, Auri uses a non-linear mapping from adherence → radiance.

Design behavior:

- **0–50%:** fewer sparks, slower orbit, cooler colors—but still beautiful.
- **50–80%:** biggest gains (more sparks, richer colors, faster orbits).
- **80–100%:** refinement and peak vibrancy; 100% is unmistakably luminous.

Implementation hint (one option): apply an ease-out curve to perceived power:

```
power = 1 - pow(1 - coreAdherence, k)   // k ~ 2.0–3.0
```

This makes improvements feel meaningful early, while keeping 80–100 close.

---

## 7. State Spectrum (Five-Tier Framework)

Your Auri transitions smoothly across 0–100%, but these tiers are a shared vocabulary.

| Core Adherence | State | Metaphor | Auri Impression |
|---:|---|---|---|
| 90–100% | **Radiant** | full cellular luminescence | Peak vibrancy; maximum sparks; full color spectrum; fastest orbits |
| 70–89% | **Vibrant** | strong inner light | Many sparks; warm colors; satisfying speed |
| 50–69% | **Awakening** | gathering energy | Moderate sparks; teal-purple tones; steady motion |
| 30–49% | **Resting** | conserving energy | Fewer sparks; cooler colors; gentle drift |
| 0–29% | **Dreaming** | deep rest | Minimal sparks; dim cool blues; very calm |

### Tier Detail (What Actually Changes)

**Radiant (90–100%) — Peak luminescence (100% is unmistakable):**

- Maximum spark count (22-30)
- Full color spectrum including white cores
- Fastest orbital speed, longest spin persistence
- Breathing animation most pronounced

**Vibrant (70–89%):**

- Many sparks (15-22)
- Warm colors: golds, teals, pinks
- High orbital speed, satisfying spin persistence
- Strong brightness

**Awakening (50–69%):**

- Moderate spark count (10-14)
- Teal and purple tones
- Medium orbital speed
- Visible but not overwhelming

**Resting (30–49%):**

- Fewer sparks (6-9)
- Blue-teal colors
- Gentle orbital drift
- Subdued brightness

**Dreaming (0–29%):**

- Minimal sparks (3-5)
- Cool blues only
- Very slow drift
- Calm and peaceful, not broken

**Guardrail:** low tiers must still look intentional, beautiful, and worth opening.

---

## 8. Interaction Model (Auri-First)

### Meal Logging

- **Primary:** photo capture → confirm → **On track** / **Off track**
- **Alternative:** quick text entry → **On track** / **Off track**

The app does not interpret what "on track" means. The user defines alignment relative to their goal.

### Fidget Interactions

Your Auri should be genuinely satisfying even when a user is idle. Rich interactivity is key.

| Gesture | Response | What adherence modulates |
|---|---|---|
| Flick / swipe | imparts spin to sparks | max speed, spin persistence |
| Tap | sparks scatter outward, then return | scatter intensity |
| Double tap | sparkle burst effect | burst intensity |
| Long press + drag | sparks attracted to finger | attraction strength |
| Pinch | expand/contract orbital radius | radius limits |
| Two-finger twist | tilt orbital plane | tilt range |
| Device shake | chaos mode (erratic orbits) | chaos intensity |

### Haptics

Haptics amplify the luminous feel:

- high adherence: crisp, sparkly feedback
- low adherence: softer, more ethereal feedback

Sound is intentionally not required for the core experience.

---

## 9. Emotional Design: The Low State

Low adherence should never feel like punishment. The narrative is:

- **Resting / Dreaming = your Auri is conserving energy, waiting**
- the sparks are patient, ready to brighten

Avoid:

- harsh red "error" states
- streak loss language
- dramatic collapse animations
- copy implying moral failure

---

## 10. Why Users Will Return

1. **It's a real fidget object.** Users will open the app just to play with their Auri.
2. **Progress is embodied.** Better adherence makes your Auri objectively more luminous.
3. **Recovery is immediate.** One aligned meal produces a noticeable brightening.
4. **It's not shame-based.** Your Auri is always beautiful; it only changes energy level.

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
| Your Auri | full visual + interaction spectrum |
| Meal history | daily list, on/off markers |

---

## 13. Information Architecture

### Primary Screens

1. **Auri View (Home)** — full-screen Auri visualization
2. **Log Meal** — capture + on/off track
3. **Data View** — metrics + history
4. **Premium Insights** (if upgraded)

### Number Surfaces

#### Auri View (Home)

Display **Today's adherence** subtly (not dashboard-y):

- small HUD text anchored top-left or bottom-left
- format: `TODAY 82%`

Your Auri itself reflects the blended state (Today + Past 7 Days). To avoid confusion without adding labels on Home:

- use a one-time tooltip in week one (e.g., "Your Auri reflects Today + Past 7 Days")
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

1. Welcome: "Meet your Auri."
2. Select dietary goal.
3. Meet your Auri: quick tutorial (flick to spin the sparks).
4. Prompt to log your next meal.

---

## 15. Technical Approach (High-Level)

### Platform

- iOS-first.

### Rendering

- RealityKit with `UnlitMaterial` for cel-shaded, flat-color aesthetic.
- Procedural spark entities with individual orbital parameters.
- No bloom/glow shaders needed—brightness achieved through color saturation.

### Motion & "Feel"

- Spinner physics model tuned for satisfaction (torque response, damping).
- State interpolation across adherence for:
  - spark count
  - orbital speed
  - color palette
  - brightness
  - breathing amplitude

### Accessibility

- Reduce Motion: offer a calmer mode (slower orbits, no trails) while preserving state differentiation through color/brightness.

---

## 16. MVP Scope

### In Scope

- Auri 3D visualization (stylized luminous orb with orbiting sparks)
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
| **Auri** | the app name; also refers to your personal luminous orb visualization |
| **Biophotons** | ultraweak light emissions from living cells; the scientific basis for the Auri metaphor |
| **Spark** | an individual light particle orbiting within your Auri |
| **On track / Off track** | user-tagged alignment of a meal with their chosen dietary goal |
| **Today adherence** | ratio of on-track meals to total meals logged today |
| **Past 7 Days** | rolling 7-day adherence ratio |
| **Past 30 Days** | rolling 30-day adherence ratio |
| **Core adherence** | blended value that drives your Auri's visual + interaction state |
| **Radiant** | peak state where your Auri is at maximum luminescence |
