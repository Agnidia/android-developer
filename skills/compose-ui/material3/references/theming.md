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

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `ayush016`. No verbatim copying.
