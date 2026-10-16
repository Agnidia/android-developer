# Screenshot Tests

Prefer **Roborazzi** (`io.github.takahirom.roborazzi:*:1.60.0` as of 2026-06) to render
composables to golden images off-device — it runs on Robolectric (JVM, no emulator) and
coexists with Hilt/Robolectric tests.

```kotlin
@Test fun profileCard_light() {
    captureRoboImage("profile_light.png") { AppTheme(dark = false) { ProfileCard(sample) } }
}
```

- `recordRoborazziDebug` captures/updates goldens; `verifyRoborazziDebug` fails on diff;
  `compareRoborazziDebug` reports without failing.
- **Auto-generate from previews:** enable `generateComposePreviewRobolectricTests` in the
  Roborazzi Gradle config to derive screenshot tests directly from `@Preview` composables —
  no hand-written `captureRoboImage` per preview.
- Cover the state matrix that matters: light/dark, loading/content/error, RTL, large font.
- Commit goldens; review diffs in PRs. Keep them deterministic (fixed sample data, no real
  time/network).

**Paparazzi caveat:** `app.cash.paparazzi:2.0.0-alpha02` (alpha as of 2026-06) is an
alternative but is not yet stable and does not interoperate with Robolectric/Hilt-driven
tests — prefer Roborazzi for new work.

## Attribution
Synthesized by Agnidia from `new-silvermoon`, `piyushverma0`, Google `android/skills`
(Apache License 2.0). Apache-2.0. No verbatim copying.
