---
name: testing
description: Android tests in practice: JUnit5/JUnit4 unit tests, MockK doubles, Turbine Flow assertions, Compose UI tests with createComposeRule, and Roborazzi/Paparazzi screenshot tests. Use when writing or reviewing Android tests.
license: Apache-2.0
metadata:
  author: IGRSoft
  last-updated: '2026-06-14'
  keywords: [junit, mockk, turbine, compose-ui-test, roborazzi, paparazzi, android]
---

# Testing (Android)

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

## Screenshot

Roborazzi (JVM, fast) or Paparazzi render composables off-device; `recordRoborazziDebug`
to capture golden images, `verifyRoborazziDebug` to diff. Use for critical screens and
theme/state matrices.

## See also
- [references/junit-mockk.md](references/junit-mockk.md)
- [references/turbine-flow-tests.md](references/turbine-flow-tests.md)
- [references/compose-ui-tests.md](references/compose-ui-tests.md)
- [references/screenshot-tests.md](references/screenshot-tests.md)

## Attribution

Synthesized by IGRSoft from `new-silvermoon`, `piyushverma0`, and Google's official
`android/skills` testing guidance (**Apache License 2.0 — Google android/skills**).
Licensed Apache-2.0; no content copied verbatim.
