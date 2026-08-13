---
name: testing
description: Android tests in practice: JUnit5/JUnit4 unit tests, MockK doubles, Turbine Flow assertions, Compose UI tests with createComposeRule, and Roborazzi-first screenshot tests. Use when writing or reviewing Android tests.
license: Apache-2.0
metadata:
  author: IGRSoft
  last-updated: '2026-06-23'
  keywords: [junit, mockk, turbine, compose-ui-test, roborazzi, paparazzi, android]
---

# Testing (Android)

Stack (as of 2026-06): JUnit5 (`junit-jupiter`) for JVM unit tests, **Turbine**
(`app.cash.turbine:turbine:1.2.1`) for Flow assertions, Robolectric (`robolectric:4.16.1`)
for the JVM Android runtime, and **Roborazzi** (`io.github.takahirom.roborazzi:*:1.60.0`,
prefer over Paparazzi) for screenshots.

## Unit (ViewModel)

✅ Correct — test dispatcher, Turbine assertion on `StateFlow`:

```kotlin
@Test fun loadEmitsContent() = runTest {
    val vm = ProfileViewModel(GetUserUseCase(FakeUserRepository(User("1", "Ada"))), dispatcher = StandardTestDispatcher(testScheduler))
    vm.state.test {
        assertEquals(UiState(loading = false), awaitItem())   // initial
        vm.onLoad(UserId("1")); advanceUntilIdle()
        assertEquals("Ada", awaitItem().user?.name)
        cancelAndConsumeRemainingEvents()
    }
}
```

❌ Mistake — real delay and a hardcoded dispatcher make the test flaky:

```kotlin
@Test fun load() = runBlocking {
    val vm = ProfileViewModel(useCase)   // uses Dispatchers.IO internally
    vm.onLoad(id); Thread.sleep(500)     // WRONG — timing-dependent, flaky
    assertNotNull(vm.state.value.user)
}
```

## MockK vs fakes

Prefer **fakes** for repositories/data sources; reserve MockK for boundaries with awkward
construction. `mockk<T>()`, `every { } returns`, `coEvery { }` for suspend, `verify { }`.

## Compose UI

```kotlin
@get:Rule val rule = createComposeRule()
@Test fun clickIncrements() {
    rule.setContent { Counter(count = 0, onIncrement = {}) }
    rule.onNodeWithText("Count: 0").assertIsDisplayed()
}
```

Select by `testTag`/semantics, not pixel position. Keep UI tests hermetic.

#### Displayed-Enabled Control Sweep (multi-substate screens)

Screens that cycle one composable through substates (form → error → success; wizard steps) hide two
defects unit and screenshot tests (Roborazzi/Paparazzi) miss: a control clipped/overlapped/disabled
in one substate, and a transition control that fails to restore the prior state. Per substate: (1)
every primary control — by `testTag`/semantics (§ Compose UI) — is BOTH `assertIsDisplayed()` AND
`assertIsEnabled()`, not just present in the tree; (2) every transition control performs its
transition AND its inverse restores the prior state (Retry from error → form). One test or one per
substate — every primary control asserted displayed+enabled in each substate.

Pairs with the 48dp touch-target discipline
([compose-ui/accessibility](../../compose-ui/accessibility/SKILL.md)) — the same defect class at the
semantics level. Test-side twin of the armed screenshot gate (`CORPFLOW.md § Screenshot
Gate for Android Work`).

## Screenshot

Prefer **Roborazzi** (`io.github.takahirom.roborazzi:*:1.60.0` as of 2026-06) for Compose
screenshot tests — it runs on Robolectric (JVM, no emulator) and coexists with Hilt/Robolectric
tests. `recordRoborazziDebug` captures golden images, `verifyRoborazziDebug` diffs. Use
`generateComposePreviewRobolectricTests` to auto-generate screenshot tests from `@Preview`
composables. Cover critical screens and theme/state matrices.

Paparazzi (`app.cash.paparazzi:2.0.0-alpha02`, alpha as of 2026-06) remains an option but is
not yet stable and does not interoperate with Robolectric/Hilt-driven tests — prefer Roborazzi.

### Testing expressive / morphing UI

For Material 3 Expressive surfaces ([compose-ui/material3-expressive/SKILL.md](../../compose-ui/material3-expressive/SKILL.md)),
extend the screenshot matrix across **theme × state**, and add a **reduce-motion** column
(`ANIMATOR_DURATION_SCALE == 0` → `snap()` + standard scheme) so the no-animation fallback is
covered, not just the animated path. Springs and shape morphs are mid-flight at arbitrary times —
select nodes by `testTag`/semantics, never by pixel position, and assert on the **settled** state
rather than an intermediate frame. Goldens stay deterministic when you drive selection by tag and
disable animation for the captured frame.

## See also
- [references/junit-mockk.md](references/junit-mockk.md)
- [references/turbine-flow-tests.md](references/turbine-flow-tests.md)
- [references/compose-ui-tests.md](references/compose-ui-tests.md)
- [references/screenshot-tests.md](references/screenshot-tests.md)

## Attribution

Synthesized by IGRSoft from `new-silvermoon`, `piyushverma0`, and Google's official
`android/skills` testing guidance (**Apache License 2.0 — Google android/skills**).
Licensed Apache-2.0; no content copied verbatim.
