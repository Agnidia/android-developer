# Motion — spring specs and speed tokens

Expressive motion is physics, read from the theme. Two rules dominate: pick the **right spec
family** for what you animate, and pick the **right speed** for the element's size. Both come from
`MaterialTheme.motionScheme` — never from inline constants.

> The token names below (`fastSpatialSpec`, `defaultEffectsSpec`, etc.) describe *intent*. Confirm
> the exact accessor names and stability against the BOM you pin (Context7/Ref) — the motion-scheme
> surface is on the experimental track in the pinned `material3:1.4.0`.

## Spatial vs effects — never cross them

| Family | Damping | Drives | Feel |
|--------|---------|--------|------|
| **Spatial** | under-damped (slight bounce, ~0.6) | position, size, rotation, shape | physical, settles with a small overshoot |
| **Effects** | critically damped (1.0, no overshoot) | color, opacity | clean arrival, no flash past target |

The hard constraint: **never apply a spatial spec to color or opacity.** A bouncy spring on alpha
overshoots past 100%, and on color it visibly flashes past the target before settling — both read as
a bug, not a flourish. Geometry bounces; appearance does not.

```kotlin
// ✅ geometry gets a spatial spec; appearance gets an effects spec
val scale by animateFloatAsState(
    targetValue = if (expanded) 1f else 0.92f,
    animationSpec = MaterialTheme.motionScheme.fastSpatialSpec(),   // size → spatial
)
val tint by animateColorAsState(
    targetValue = if (selected) scheme.primary else scheme.onSurfaceVariant,
    animationSpec = MaterialTheme.motionScheme.defaultEffectsSpec(), // color → effects
)
```

```kotlin
// ❌ spatial spring on color — overshoots/flashes past the target
val tint by animateColorAsState(target, animationSpec = MaterialTheme.motionScheme.fastSpatialSpec())
```

## Speed tokens — match the element

Each family comes in fast / default / slow. Scale the speed to the size of what moves:

| Token tier | Use for | Examples |
|------------|---------|----------|
| **fast** | small controls | switch, button, chip, icon toggle |
| **default** | partial-screen surfaces | bottom sheet, drawer, expanding card |
| **slow** | full-screen transitions | screen-to-screen, detail open |

Mismatched speed reads wrong both ways: a slow token on a small toggle drags, and a fast token on a
full-screen push feels jittery. When the surface itself scales (phone vs tablet), let motion follow —
tighter on compact, slightly wider on expanded.

## Interruption and retargeting

The reason springs beat tweens is interruption. A spring animates from the **current** value and
velocity, so when the target changes mid-flight (the user reverses a swipe, taps again), it
retargets smoothly without a restart. A `tween` is time-parameterized: interrupting it restarts the
curve and the value jumps. Keep every Expressive animation interruptible — this is both the quality
win and an accessibility benefit.

## Reduce-motion fallback

Respect the system "remove animations" setting. When `ANIMATOR_DURATION_SCALE == 0`:

- replace spring specs with `snap()` (or a minimal fade), and
- switch the theme from the expressive motion scheme to the **standard** scheme.

```kotlin
val reduceMotion = remember {
    Settings.Global.getFloat(
        context.contentResolver, Settings.Global.ANIMATOR_DURATION_SCALE, 1f
    ) == 0f
}

val spec = if (reduceMotion) snap() else MaterialTheme.motionScheme.defaultSpatialSpec()
```

Wrap in `remember { }` to avoid a ContentProvider query on every recomposition. Gate it once
near the theme and thread the decision down, rather than re-querying per animation.

## Attribution
Synthesized by IGRSoft (Apache-2.0) from Material 3 Expressive motion guidance and community Compose
references. No verbatim copying; token names are illustrative — verify against your pinned BOM.
