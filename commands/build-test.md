---
description: Detect the Gradle wrapper, assemble a variant, and run the unit-test suite for an Android module
argument-hint: [path (default .)] [--variant debug|release] [--module NAME] [--clean] [--no-test]
allowed-tools: Read, Glob, Grep, Bash
estimated-cost:
  min-tokens: 1500
  max-tokens: 12000
  model-distribution:
    haiku: 40%
    sonnet: 55%
    opus: 5%
---

# Build & Test (Android)
<!-- Updated: June 2026 -->

Detect an Android project's Gradle wrapper, assemble a variant, and run its unit tests
with single scoped commands. The happy path is pure Bash — no agent delegation. The
`android-phone-developer` agent is engaged only when the build or tests fail, with the
relevant log excerpt.

[Extended thinking: This command is the detection-and-execution workhorse other
android-developer commands reuse. It resolves the Gradle wrapper, runs assemble then
unit-test for the chosen variant/module, and tees everything to a timestamped log.
Because configure/compile/test failures have different fixes, on failure it parses the
first error, classifies the stage, and hands `android-phone-developer` a tight excerpt
instead of the whole log. Keep the green path deterministic and shell-only.]

## CRITICAL BEHAVIORAL RULES

1. **Use the Gradle wrapper.** Always `./gradlew` (never a system `gradle`); if the
   wrapper is absent, report it and stop.
2. **Happy path is shell-only.** When assemble and test both succeed, do NOT delegate.
3. **Single-command Bash invocations.** `./gradlew :module:assembleDebug`,
   `./gradlew :module:testDebugUnitTest`. Never `cd`-chain or `&&`-chain.
4. **Tee every phase to the log.** Pipe through `tee -a` to
   `.context/logs/build-<timestamp>.log`.
5. **On failure, classify before delegating.** Parse the first error, classify it as
   configure / compile / test, then delegate ONLY to `android-developer:android-phone-developer`
   with the excerpt.
6. **Tool-missing never hard-fails.** If `./gradlew` cannot run (no JDK), print the hint
   and report — do not crash.
7. **Never enter plan mode.** Execute the procedure.

## Usage

```bash
/android-developer:build-test .
/android-developer:build-test app --variant release --module :feature:login
/android-developer:build-test . --clean --no-test
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `path` | `.` | Project root holding `gradlew`. |
| `--variant debug\|release` | `debug` | Build/test variant (`assembleDebug` / `testDebugUnitTest`). |
| `--module NAME` | all | Gradle module path (`:app`, `:feature:login`). |
| `--clean` | off | `./gradlew clean` before assembling. |
| `--no-test` | off | Assemble only; skip the unit-test phase. |

## Workflow

### Phase 1: Detect (Bash)
1. Confirm `path/gradlew` exists. If not, emit the "no Gradle wrapper" error and stop.
2. Create `.context/logs/`. `TS="$(date +%Y%m%d-%H%M%S)"`, `LOG=".context/logs/build-${TS}.log"`.
3. Resolve the module prefix (`--module` or empty for the root).

### Phase 2: Clean (optional, Bash)
If `--clean`: `./gradlew clean 2>&1 | tee -a "$LOG"`.

### Phase 3: Assemble (Bash)
`./gradlew <module>:assemble<Variant> 2>&1 | tee -a "$LOG"`. Capture `${PIPESTATUS[0]}`.
On non-zero, classify (configure vs compile) and go to Failure Triage.

### Phase 4: Test (Bash)
If `--no-test`: skip, record "tests skipped". Else
`./gradlew <module>:test<Variant>UnitTest 2>&1 | tee -a "$LOG"`. On non-zero → Failure
Triage with stage `test`.

### Phase 5: Report (Bash)
Emit the Output Format summary. On full success, stop.

## Failure Triage

1. **Parse the first error** from the log:

   | Symptom | Stage |
   |---------|-------|
   | `Could not resolve`, `Plugin [id: …] not found`, `A problem occurred configuring`, version-catalog errors | `configure` |
   | Kotlin `e: …` / `error:`, unresolved reference, type mismatch | `compile` |
   | JUnit `FAILED`, `AssertionError`, `expected:<…>`, test task `> Task … FAILED` | `test` |

2. **Extract a tight excerpt** — the first error plus ~10 lines of context, not the whole
   log. Include `$LOG`.
3. **Delegate** to `android-developer:android-phone-developer`:
   **Use Task tool with subagent_type="android-developer:android-phone-developer"**
   Prompt: "build-test failed at the **{stage}** stage for `{path}` (module `{module}`,
   variant `{variant}`). First error and context from `{LOG}`:\n```\n{excerpt}\n```\n
   Diagnose the root cause and propose the minimal fix. Do not re-run the full build;
   return analysis and patch."
4. After the fix, re-run from the failing phase. Report each cycle; never auto-loop
   silently.

## Tool Availability

| Missing | Hint |
|---------|------|
| JDK / `./gradlew` fails to start | Install a JDK 17+ (`brew install temurin`) and confirm `JAVA_HOME`. |
| Android SDK | Install via Android Studio or `sdkmanager`; set `ANDROID_HOME`/`local.properties`. |

Never hard-fail on a missing tool — print the hint and report.

## Output Format

```markdown
## Build & Test Report
**Target:** {path} (module {module}, variant {variant})
**Log:** .context/logs/build-{timestamp}.log

| Phase | Result | Notes |
|-------|--------|-------|
| Clean | ✅ / ⏭ | |
| Assemble | ✅ / ❌ | {warnings} |
| Test | ✅ / ❌ / ⏭ | {N passed, M failed, or --no-test} |

**Result:** PASS / FAIL ({failing stage})
<!-- on failure: -->
### Failure Triage
- **Stage:** {configure | compile | test}
- **First error:** {one-line}
- **Delegated to:** android-developer:android-phone-developer
```

## Error Handling

### No Gradle wrapper
```
Error: No ./gradlew found under {path}.
Suggestion: Run from the project root, or generate the wrapper with `gradle wrapper`.
```

### Module not found
Report the available modules (`./gradlew projects`) and stop.

## See Also
- `/android-developer:lint-fix` — run ktlint/detekt before building to cut noise.
- `/android-developer:generate-tests` — add tests when a module has none.
- `/android-developer:deps-audit` — when a `configure`-stage failure is a dependency issue.
- `skill: tooling` — Gradle build configuration and the Android CLI.
