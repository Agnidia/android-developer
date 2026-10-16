# Theming

`MaterialTheme` provides `colorScheme`, `typography`, and `shapes` via composition locals.
Define one app theme composable and wrap the content:

```kotlin
@Composable fun AppTheme(dark: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = if (dark) DarkColors else LightColors,
        typography = AppTypography,
        content = content,
    )
}
```

Support dynamic color on Android 12+ with a static brand fallback. Never read raw `Color`
literals in screens — always `MaterialTheme.colorScheme.*`.

## Material 3 Expressive theme

Material 3 Expressive ships inside `androidx.compose.material3` (not a separate artifact). Swap
`MaterialTheme` for `MaterialExpressiveTheme` and supply the expressive color/motion builders:

```kotlin
@Composable fun AppTheme(dark: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {
    MaterialExpressiveTheme(
        colorScheme = if (dark) expressiveDarkColorScheme() else expressiveLightColorScheme(),
        typography = AppTypography,
        motionScheme = MotionScheme.expressive(),   // springier, content-aware transitions
        content = content,
    )
}
```

`expressiveLightColorScheme()` / `expressiveDarkColorScheme()` seed an expressive palette you can
override per role; `MotionScheme.expressive()` swaps the default motion tokens. These APIs are
experimental — opt in where required and verify against your pinned BOM.

## Attribution
Synthesized by Agnidia (Apache-2.0) from `new-silvermoon`, `ayush016`. No verbatim copying.
