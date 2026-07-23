# Shapes — variety, contrast, and morphing

Expressive treats shape as an expressive lever, not a constant corner radius. Two moves: build a
**contrasting** shape vocabulary on a screen, and **morph** shapes on state transitions instead of
cross-fading.

> `MaterialShapes`, `Morph`, and `RoundedPolygon` are on the experimental / graphics-shapes track.
> Confirm the available shape names and the `Morph` API against the BOM you pin (Context7/Ref) — the
> set below is illustrative of intent, not an exhaustive or signature-stable list.

## A vocabulary with tension

`MaterialShapes` extends well past the rounded rectangle — pill, diamond, multi-sided cookie/burst
forms, clover, heart, and more. The point is **deliberate contrast**: place sharp angular forms
next to soft rounded ones so the layout has tension.

- Pills for chips and compact selectors.
- Rounded squares for FABs.
- Larger radii for modals and sheets.
- Distinct silhouettes for distinct content types, so a list does not read as identical cards.

Uniform rounded rectangles on every element is the single clearest "template app" tell. Vary shape
the way you vary type weight — intentionally, in service of hierarchy.

## Morph on state transitions

For a *state* change (collapsed → expanded, idle → active, loading → done), morph the silhouette
with a `Morph` between two `RoundedPolygon` instances rather than swapping or cross-fading two
composables. The outline animates continuously, which reads as a single object changing rather than
one element replacing another.

```kotlin
// Intent sketch — verify Morph/RoundedPolygon API against your pinned BOM.
val start = RoundedPolygon.rectangle(rounding = CornerRounding(8f))
val end = RoundedPolygon.star(numVerticesPerRadius = 8, rounding = CornerRounding(16f))
val morph = Morph(start, end)
// progress driven by a SPATIAL motion-scheme spring (geometry → spatial), interruptible
```

Drive the morph progress with a **spatial** motion-scheme spring (see
[motion-springs.md](motion-springs.md)) so it retargets if the state flips mid-animation. Never
drive a morph with a hardcoded tween.

## FAB and navigation shapes

- **FAB** — the expressive default is a **rounded square**, not a circle. New size configurations
  are available. Treat the FAB's shape and its press/expand animation as a personality anchor for
  the app, and reach for `FloatingActionButtonMenu` when it needs to reveal actions.
- **Navigation indicators** — the active item on a Navigation Bar / Rail uses a **pill-shaped**
  indicator, and the active label is drawn in `secondary` (not `onSurface`). That color shift is
  part of the selection signal; keep it.
- **Progress** — `LoadingIndicator` renders indeterminate progress as morphing polygons instead of a
  plain circular spinner; linear progress supports a wavy track and configurable track height.

## Touch targets survive morphing

A morphing silhouette must not shrink the interactive area below **48×48dp**. The visual shape can
animate freely; the hit target stays ≥ 48dp throughout the morph. See
[accessibility/SKILL.md](../../accessibility/SKILL.md).

## Attribution
Synthesized by IGRSoft (Apache-2.0) from Material 3 Expressive shape guidance and community Compose
references. No verbatim copying; shape/`Morph` API is illustrative — verify against your pinned BOM.
