# Anti-patterns — the "Android AI slop" checklist

A reviewer-usable list of the markers that make an Expressive UI read as machine-generated rather
than designed. Each row is a **check** (what to flag) plus the **one-line correct alternative**.
Use it in `/android-developer:review-code` and during design-craft review.

## Motion

| Flag when you see | Correct alternative |
|-------------------|---------------------|
| Hardcoded `tween(300)` (or any `tween`) for interruptible motion — the #1 tell | Read a `motionScheme` spring token that retargets on interruption |
| A spatial (bouncy) spec applied to `color`/`alpha` | Use an **effects** spec (critically damped) for appearance; spatial is geometry-only |
| `slowSpatialSpec` on a toggle, or `fastSpatialSpec` on a full-screen transition | Match the speed token to element size: fast → small controls, slow → full-screen |
| Spring constants written inline | Pull tokens from `MaterialTheme.motionScheme`; never hardcode |
| No reduce-motion handling | When `ANIMATOR_DURATION_SCALE == 0`, fall back to `snap()` + the standard scheme |

## Shape

| Flag when you see | Correct alternative |
|-------------------|---------------------|
| Uniform rounded rectangles on every element | Build deliberate contrast from `MaterialShapes` (angular vs soft) |
| Cross-fade / visibility toggle for a state change | Morph the silhouette with a `Morph` between `RoundedPolygon` instances |
| Circular FAB | Rounded-square FAB (the expressive default) |
| Identical card layout repeated down a list | Differentiate each content type by its containment, silhouette, and type emphasis |
| Hit target shrinking as the shape morphs | Keep the interactive area ≥ 48×48dp throughout the morph |

## Color

| Flag when you see | Correct alternative |
|-------------------|---------------------|
| `primary` used for everything; `secondary`/`tertiary`/fixed accents ignored | Spend the 48-role scheme across hierarchy; fixed accents for theme-invariant elements |
| Opacity/alpha overlays used for elevation/depth | Use the 5 `surfaceContainer` levels for layered depth |
| Hardcoded `Color(0x…)` literals in a screen | Read `MaterialTheme.colorScheme.*` roles |
| Nav active label left as `onSurface` | Active label in `secondary` with a pill indicator |

## Typography

| Flag when you see | Correct alternative |
|-------------------|---------------------|
| `bodyMedium` everywhere; flat type with no emphasis | Pair an `*Emphasized` style (e.g. `headlineLargeEmphasized`) for editorial moments against a quieter baseline |

## Components

| Flag when you see | Correct alternative |
|-------------------|---------------------|
| `SegmentedButton` | `ButtonGroup` (connected buttons with overflow) |
| `BottomAppBar` for the bottom action surface | Docked / floating toolbar with an integrated FAB |
| Stacked small FABs | `FloatingActionButtonMenu` + `ToggleFloatingActionButton` |
| Circular spinner for indeterminate progress | `LoadingIndicator` with morphing polygons (`ContainedLoadingIndicator` for a branded variant) |

## Platform

| Flag when you see | Correct alternative |
|-------------------|---------------------|
| Pinning stable `1.4.0` and assuming Expressive components exist without checking | Verify Expressive component availability/stability against the pinned BOM (Context7/Ref) before use |
| Fixed-orientation layout | Adaptive layout via window size classes — Android 16 ignores orientation restrictions at ≥600dp |
| Content ignoring system bars | Edge-to-edge with deliberate `WindowInsets`; harmonize in-app transitions with predictive back |

## Composition

| Flag when you see | Correct alternative |
|-------------------|---------------------|
| All six tactics applied uniformly to every element | Compound expressiveness only at the 1–2 hero moments; restraint everywhere else |

## Attribution
Synthesized by IGRSoft (Apache-2.0) from Material 3 Expressive design guidance and community Compose
references. No verbatim copying; alpha-track API claims are hedged — verify against your pinned BOM.
