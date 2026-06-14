---
name: material3
description: Material 3 theming in Compose: color roles, dynamic color, typography, and dark theme. Use when theming an app, applying color roles, or avoiding hardcoded colors.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-14'
  keywords: [material3, theming, color-roles, dynamic-color, typography, compose]
---

# Material 3 Theming

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

## See also
- [references/theming.md](references/theming.md)
- [references/color-roles.md](references/color-roles.md)

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `ayush016`. No verbatim copying.
