# Screenshot Tests

Roborazzi and Paparazzi render composables to golden images off-device (JVM, no emulator).

```kotlin
@Test fun profileCard_light() {
    captureRoboImage("profile_light.png") { AppTheme(dark = false) { ProfileCard(sample) } }
}
```

- `recordRoborazziDebug` captures/updates goldens; `verifyRoborazziDebug` fails on diff;
  `compareRoborazziDebug` reports without failing.
- Cover the state matrix that matters: light/dark, loading/content/error, RTL, large font.
- Commit goldens; review diffs in PRs. Keep them deterministic (fixed sample data, no real
  time/network).

## Attribution
Synthesized by IGRSoft from `new-silvermoon`, `piyushverma0`, Google `android/skills`
(Apache License 2.0). Apache-2.0. No verbatim copying.
