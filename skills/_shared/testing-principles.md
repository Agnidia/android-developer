---
name: testing-principles
description: Android test pyramid, framework matrix, coverage thresholds, and testing best practices for Kotlin/Compose
metadata:
  last-updated: '2026-06-15'
---

# Testing Principles Reference

Shared testing patterns, framework selection, coverage requirements, and quality
gates for Android work.

## Test Pyramid

```
         /\
        /  \      Screenshot / E2E (5-10%)
       /────\     Roborazzi (prefer over Paparazzi), critical user journeys (Espresso/Compose)
      /      \
     /────────\   Instrumented / Integration (20-30%)
    /          \  Compose UI tests, Room DAO tests, repository + fakes
   /────────────\ Unit Tests (60-70%)
  /              \ ViewModels, use-cases, mappers, pure Kotlin logic
```

## Framework Matrix

Detect the existing framework first — never introduce a second one into a project
that already has one.

| Layer | Frameworks | Focused run |
|-------|-----------|-------------|
| Unit | JUnit5 (`useJUnitPlatform()`) or JUnit4; MockK or mockito-kotlin | `./gradlew :m:testDebugUnitTest --tests <FQCN>` |
| Flow assertions | Turbine (`app.cash.turbine:turbine:1.2.1` as of 2026-06) | within unit tests |
| Compose UI | `compose.ui:ui-test-junit4` (`createComposeRule`) | `./gradlew :m:connectedDebugAndroidTest` |
| Room | in-memory `Room.inMemoryDatabaseBuilder` | unit or instrumented |
| Screenshot | Roborazzi (JVM, prefer; `generateComposePreviewRobolectricTests`) over Paparazzi (alpha) | `./gradlew :m:verifyRoborazziDebug` |

A test that is not discovered/registered does not exist — confirm source set
placement (`test/` vs `androidTest/`) and runner configuration.

## Coverage Targets

| Scope | Minimum | Target | Notes |
|-------|---------|--------|-------|
| Domain / use-cases | 90% | 95%+ | Pure Kotlin business rules |
| ViewModels / repositories | 75% | 80%+ | State logic, error mapping |
| Utilities / mappers | 60% | 70%+ | Shared helpers |
| UI (Compose) | smoke + key paths | screenshot critical screens | Visual + interaction |

## Testing Best Practices

### Naming

```
methodUnderTest_condition_expectedResult
loadUser_networkError_emitsErrorState
```

### Determinism
- Inject a `TestDispatcher`; use `runTest` and virtual time (`advanceUntilIdle()`).
  Never real `delay`/`Thread.sleep` as synchronization.
- Hermetic: in-memory Room, fake data sources, no real network, no real clock.
- Seed any randomness; no ordering assumptions between tests.

### Test Doubles
- Prefer **fakes** over mocks where the contract is simple (an in-memory repository
  is clearer than a wall of `every { } returns`).
- Mock the **boundary** (network, DAO, system services) — not your own modules.

## Quality Gates

| Gate | Threshold | Action on Failure |
|------|-----------|-------------------|
| Coverage | >80% new code | Block merge |
| Unit + instrumented tests | All pass | Block merge (QA gate) |
| ktlint + detekt | 0 findings | Block merge |
| Flaky tests | <1% flakiness | Investigation |

## Anti-Patterns to Avoid

- Testing implementation details instead of observable state/behavior.
- Over-mocking your own classes.
- Flaky timing/network/real-`Dispatchers.IO` tests.
- Tests that assert nothing or duplicate the implementation.
- Copy-paste tests instead of parameterized tests.
- Missing edge cases: empty state, error state, configuration change, process death.

## Related Skills

- `severity-matrix.md` — coverage requirements and finding priorities
- `workflow-integration/SKILL.md` — QA gate definition for worktask runs
- `quality/testing/SKILL.md` — framework deep dive
