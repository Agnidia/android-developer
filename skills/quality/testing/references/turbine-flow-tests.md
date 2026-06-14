# Turbine Flow Tests

Turbine collects a `Flow` inside a `test { }` block and asserts emissions in order:

```kotlin
flow.test {
    assertEquals(Loading, awaitItem())
    assertEquals(Content(data), awaitItem())
    awaitComplete()                 // or cancelAndConsumeRemainingEvents()
}
```

- `awaitItem()` for the next emission, `awaitError()` for a thrown error, `expectNoEvents()`
  to assert quiescence.
- Combine with `runTest` + `advanceUntilIdle()` to drive virtual time deterministically.
- Always terminate the block (`awaitComplete`/`cancelAndConsumeRemainingEvents`) or the test
  hangs.

## Attribution
Synthesized by IGRSoft from `new-silvermoon`, `piyushverma0`, Google `android/skills`
(Apache License 2.0). Apache-2.0. No verbatim copying.
