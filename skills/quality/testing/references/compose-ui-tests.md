# Compose UI Tests

```kotlin
@get:Rule val rule = createComposeRule()           // or createAndroidComposeRule<MainActivity>()

@Test fun showsError() {
    rule.setContent { ProfileScreen(UiState(error = "Boom")) }
    rule.onNodeWithText("Boom").assertIsDisplayed()
    rule.onNodeWithContentDescription("Retry").performClick()
}
```

- Select by `onNodeWithText` / `onNodeWithContentDescription` / `onNodeWithTag` — add
  `Modifier.testTag(...)` for stable selectors.
- `waitUntil { }` for async UI; avoid sleeps.
- `createComposeRule` runs on the JVM with Robolectric where configured (fast); use
  `createAndroidComposeRule` for instrumented tests needing a real Activity.

## Attribution
Synthesized by Agnidia from `new-silvermoon`, `piyushverma0`, Google `android/skills`
(Apache License 2.0). Apache-2.0. No verbatim copying.
