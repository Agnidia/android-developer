---
name: material3
description: Material 3 theming in Compose: color roles, dynamic color, typography, and dark theme. Use when theming an app, applying color roles, or avoiding hardcoded colors.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-15'
  keywords: [material3, theming, color-roles, dynamic-color, typography, expressive, compose]
---

# Material 3 Theming

Use `androidx.compose.material3` (current `material3:1.4.0` as of 2026-06) — pulled via the
Compose BOM (`platform(libs.compose.bom)`), version managed in your version catalog. **Material 3
Expressive ships *inside* this artifact** — it is not a separate library.

Theme with `MaterialTheme` color roles — never hardcoded colors.

✅ Correct — read tokens from the theme:

```kotlin
Surface(color = MaterialTheme.colorScheme.surface) {
    Text("Hello", color = MaterialTheme.colorScheme.onSurface, style = MaterialTheme.typography.bodyLarge)
}
```

❌ Mistake — hardcoded color (breaks dark theme + dynamic color):

```kotlin
Text("Hello", color = Color(0xFF000000))   // WRONG — use onSurface
```

## Color roles

Use semantic roles (`primary`/`onPrimary`, `surface`/`onSurface`,
`error`/`onError`) — they guarantee contrast and adapt to light/dark and dynamic color.
Each `xxx` has a matching `onXxx` for content drawn on top.

## Dynamic color (Android 12+)

```kotlin
val scheme = if (supportsDynamic()) dynamicColorScheme(LocalContext.current) else AppColorScheme
MaterialTheme(colorScheme = scheme, typography = AppTypography) { content() }
```

Provide a static fallback scheme for pre-12 devices and a forced-brand mode.

## Material 3 Expressive

Expressive lives **inside `material3`** (no extra artifact) and aligns with the Android 16 visual
style. **This section is setup/theming only** — for the design-craft (spring motion specs, shape
variety/morphing, typographic emphasis, hero-moment composition, and the anti-pattern checklist) see
[material3-expressive](../material3-expressive/SKILL.md).

Opt in with the expressive theme + color/motion builders:

```kotlin
MaterialExpressiveTheme(
    colorScheme = expressiveLightColorScheme(),   // expressiveDarkColorScheme() for dark
    motionScheme = MotionScheme.expressive(),     // springier, content-aware motion
) { content() }
```

Expressive components (in `material3`):

| Component | Use for |
|-----------|---------|
| `LoadingIndicator` / `ContainedLoadingIndicator` | Indeterminate progress with morphing polygons (contained = branded variant) instead of a circular spinner |
| `FloatingActionButtonMenu` + `ToggleFloatingActionButton` | Expandable FAB with a menu of actions |
| `ButtonGroup` | Connected row of related buttons (replaces `SegmentedButton`) |
| `SplitButtonLayout` | Primary action with an attached secondary affordance |
| Docked / floating toolbar | Bottom action surface with an integrated FAB (replaces `BottomAppBar`) |

`MaterialExpressiveTheme` and the components above are on the experimental / alpha track — opt in
where required and verify each component's stability against the BOM you pin (Context7/Ref). The
[material3-expressive](../material3-expressive/SKILL.md) skill carries the full replacement table
and usage guidance.

## See also
- [references/theming.md](references/theming.md)
- [references/color-roles.md](references/color-roles.md)
- [material3-expressive/SKILL.md](../material3-expressive/SKILL.md) — Expressive design-craft (motion, shapes, emphasis, hero moments, anti-patterns)

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `ayush016`. No verbatim copying.
