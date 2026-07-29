# QA Gate Template (Android)

qa-engineer validates the DV output and writes `testing-N.md` (verdict `go`/`no-go`).

## Gate (both must hold)

1. **All tests pass** — `./gradlew test` (unit) and `./gradlew connectedDebugAndroidTest`
   (instrumented, where a device/emulator is available). Screenshot tests
   (Roborazzi, preferred over Paparazzi) green where the change is visual.
2. **Lint clean** — `./gradlew ktlintCheck detekt lint` reports zero findings on changed
   modules.

`and-test-generator` supports QA with framework-native generation (JUnit/MockK/Turbine/
Compose/Roborazzi).

## Output Frontmatter

```yaml
---
handoff:
  stage: QA
  verdict: go            # go | no-go
  summary: "<test result — ≤200 chars>"
  files_touched:         # = tests added
    - path/to/SomethingTest.kt
  key_decisions:         # = results
    - { id: r1, summary: "<N passed / M failed; lint clean>", anchor: "testing-0.md#results" }
  refs:
    development: development-0.md#tests-added
---
```

On `verdict: no-go`, list `## blocking_defects` — concrete, actionable strings the
orchestrator forwards as `metadata.gate_blockers[]` on the DV re-dispatch.
