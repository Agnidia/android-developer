---
name: material3-expressive
description: Material 3 Expressive design-craft for Android 16 in Compose — spring motion, shape variety/morphing, typographic emphasis, the 48-role color system, component replacements, hero-moment composition, and the "AI slop" anti-patterns. Use when designing or reviewing the *feel* of an Expressive UI (not just theming setup).
license: Apache-2.0
metadata:
  author: Agnidia
  last-updated: '2026-06-23'
  keywords: [material3-expressive, motion-scheme, springs, shapes, morph, typography, emphasis, hero-moments, anti-patterns, android16]
---

# Material 3 Expressive (design-craft)

This skill is about **craft** — how an Expressive UI should *move, contrast, and emphasize* —
not how to install or theme it. For setup (the `MaterialExpressiveTheme` opt-in, expressive
color/motion builders, the artifact note) start at
[material3](../material3/SKILL.md), then come here for the design decisions.

Design-era target: **Android 16+**. The tactics here require `material3:1.4.0+` (a library
version, not an OS version — `MaterialExpressiveTheme` and spring tokens work on Android < 16
with that library). Below `material3:1.4.0`, fall back to standard Material 3.

> **API stability.** Expressive ships *inside* `androidx.compose.material3` (no separate
> artifact), but several pieces named here (`MaterialExpressiveTheme`, `ButtonGroup`,
> `FloatingActionButtonMenu`/`ToggleFloatingActionButton`, `SplitButtonLayout`, the toolbar
> components, `Morph`/`RoundedPolygon`) sit on the experimental / alpha track. The repo pins
> `material3:1.4.0`; treat every component below as *verify-before-use* and confirm its status
> against the BOM you actually pin (Context7/Ref). API shapes shown here are illustrative at the
> level of intent, not a contract.

## The core idea: compound at hero moments, restraint elsewhere

Expressive is a research-backed system, not "make everything bouncy." Six tactics work
**together**:

| Tactic | Lever |
|--------|-------|
| Shape variety | Mix angular and rounded forms deliberately; morph between them on state change |
| Rich color | Spend the full 48-role scheme across hierarchy, not `primary` everywhere |
| Typographic emphasis | Use the `*Emphasized` styles for editorial moments against a quieter baseline |
| Strategic containment | Vary surface levels and card treatment per content type |
| Fluid spring motion | Physics-based, interruptible animation read from the motion scheme |
| Component flexibility | Reach for the newer expressive components over deprecated ones |

The craft is **selectivity**. Identify the 1–2 elements on a screen that earn *compound*
expressiveness — shape morph **and** spring scale **and** color shift **and** emphasized type at
once — and let everything else stay quiet. Applying all six tactics uniformly is what makes a UI
read as a Material catalog demo rather than a designed app. A detail transition that morphs a
`RoundedPolygon`, scales with a spatial spring, shifts color with an effects spring, and sets its
headline in `headlineLargeEmphasized` is a hero moment; the list it came from is not.

### Adoption order (highest impact first)

1. **Motion** — switch hardcoded tweens to motion-scheme springs. Biggest perceived-quality
   delta for the least work.
2. **Shape** — introduce deliberate contrast and morph on state transitions.
3. **Color** — deploy the expanded roles and surface-container levels across hierarchy.
4. **Components** — replace deprecated patterns with their expressive successors.

## Motion — springs, not tweens (summary)

Every animation uses spring physics, never `tween(durationMillis)`. Springs **retarget** from the
current position/velocity when interrupted, so a gesture reversed mid-flight stays smooth; a tween
restarts and snaps. Read tokens from `MaterialTheme.motionScheme` — do not hardcode spring
constants inline.

Two spec families, never mixed:

- **Spatial** specs are gently under-damped (a little bounce) and drive *geometry*: position, size,
  rotation, shape.
- **Effects** specs are critically damped (no overshoot) and drive *non-geometry*: color and
  opacity. A spatial spring on alpha can overshoot past 100%, and on color it flashes past the
  target — visibly broken.

Match **speed** to element size: fast tokens for small controls (switch, button), default tokens
for partial-screen surfaces (sheet, drawer), slow tokens for full-screen transitions. A mismatch
drags a small control or jitters a full-screen push. Full specs, the
reduce-motion fallback, and interruption mechanics: [references/motion-springs.md](references/motion-springs.md).

## Shape — variety and deliberate contrast (summary)

`MaterialShapes` expands the vocabulary well beyond rounded rectangles (pill, diamond, multi-sided
cookie/burst forms, clover, heart, and more). The principle is **contrast**: pair sharp angular
forms with soft rounded ones so the screen has tension. Uniform rounded rectangles everywhere is a
template tell.

For *state* transitions, prefer **shape morphing** (a `Morph` between two `RoundedPolygon`
instances) over a cross-fade — the silhouette animates rather than dissolving. The default FAB is a
**rounded square**, not a circle; treat the FAB's shape and animation as a personality anchor.
Details, the morph mechanics, and navigation pill indicators:
[references/shapes-morphing.md](references/shapes-morphing.md).

## Color and type — spend the expanded systems (summary)

**Color.** The expressive `ColorScheme` exposes ~48 named roles. Use them as a hierarchy: `primary`
for the key action, `secondary`/`tertiary` for supporting accents, the ~12 **fixed** accent roles
for elements that must look identical across light and dark. Five `surfaceContainer` levels
(`surfaceContainerLowest` → `surfaceContainerHighest`) express layered depth **instead of**
opacity-based elevation overlays — reach for a container level, not an alpha. Defaulting to
`primary`-on-`surface` for everything throws away the contrast the system is built to provide.
(Role pairing and contrast guarantees: [material3/references/color-roles.md](../material3/references/color-roles.md).)

**Type.** The scale roughly doubles to ~30 styles by adding `*Emphasized` variants (heavier weight)
alongside the baselines. The emphasized styles are for *editorial* moments — headlines, CTAs, the
single number that matters. A hero headline in `headlineLargeEmphasized` over body copy in
`bodyLarge`, for instance, sets up that contrast. `bodyMedium` everywhere produces a flat layout with no rhythm; the
contrast between emphasized and baseline is the rhythm.

## Component replacements

Prefer the expressive successors over deprecated patterns. Verify each against your pinned BOM
before adopting — several are alpha-track.

| Instead of | Use | For |
|------------|-----|-----|
| `SegmentedButton` | `ButtonGroup` | A connected row of related buttons, with overflow |
| `BottomAppBar` | Docked / floating toolbar | A bottom action surface with an integrated FAB |
| Stacked small FABs | `FloatingActionButtonMenu` + `ToggleFloatingActionButton` | An expandable FAB that reveals a menu of actions |
| Ad-hoc primary+secondary buttons | `SplitButtonLayout` | A primary action with an attached secondary affordance |
| Circular spinner | `LoadingIndicator` (morphing polygons) | Indeterminate progress with shape character (`ContainedLoadingIndicator` for a branded, contained variant) |
| Circular FAB | Rounded-square FAB (default) | The standard expressive FAB shape |
| `onSurface` nav labels | Pill active indicator; active label in `secondary` | Navigation Bar / Rail selection state |

## Platform integration

- **Dynamic color / Material You.** Honor wallpaper-extracted palettes on Android 12+
  (`dynamicLightColorScheme`/`dynamicDarkColorScheme`); ship a brand-aligned **static** fallback for
  older devices and a forced-brand mode. Harmonize brand accents into the user's dynamic palette
  rather than overriding it.
- **Edge-to-edge + predictive back.** Android 16 draws content under the system bars — handle
  `WindowInsets` deliberately. Predictive back previews the destination as the user swipes; your
  in-app transitions should harmonize with that system animation, not fight it.
- **Adaptive layouts.** Drive layout from window size classes: compact (<600dp) → single pane +
  bottom nav; medium (600–840dp) → navigation rail + list/detail; expanded (≥840dp) → permanent
  drawer + multi-pane. Android 16 ignores orientation restrictions at ≥600dp, so adaptive layout is
  not optional. Motion scales with the surface — tighter on phones, slightly wider on tablets.

## Accessibility contract (brief)

Expressive raises the motion and shape stakes, so the a11y floor is non-negotiable. Depth lives in
the [accessibility](../accessibility/SKILL.md) skill and the
[anti-patterns](references/anti-patterns.md) checklist; the contract in one place:

- **Contrast** — 4.5:1 for normal text, 3:1 for large; enforce via semantic role pairings, and
  respond to high-contrast mode (`UiModeManager.getContrast()`, API 34+; guard with
  `Build.VERSION.SDK_INT >= 34`).
- **Reduce motion** — when `ANIMATOR_DURATION_SCALE == 0`, fall back to `snap()`/simple fades and
  switch from the expressive scheme to the standard one.
- **Touch targets** — ≥ 48×48dp regardless of how the visual shape morphs.
- **Interruptible springs** — keep every animation interruptible; this is a core a11y benefit of the
  spring system, not just a polish detail.

## See also

- [references/motion-springs.md](references/motion-springs.md) — spatial vs effects specs, speed
  tokens, interruption, reduce-motion fallback.
- [references/shapes-morphing.md](references/shapes-morphing.md) — `MaterialShapes` contrast, `Morph`
  state transitions, FAB and nav-indicator shapes.
- [references/anti-patterns.md](references/anti-patterns.md) — the "AI slop" checklist, each marker
  with a correct alternative.
- [material3/SKILL.md](../material3/SKILL.md) — Expressive **setup/theming** (the
  `MaterialExpressiveTheme` opt-in, color/motion builders, artifact note).

## Attribution

Synthesized by Agnidia (Apache-2.0) from Material 3 Expressive design guidance and community Compose
references (`new-silvermoon`, `ayush016`). No content copied verbatim; alpha-track API claims are
hedged — verify each against your pinned BOM.
