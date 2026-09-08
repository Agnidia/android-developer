---
description: Detect the project's test framework and generate unit, UI, or screenshot tests for an Android target, then verify them
argument-hint: [target] [--type unit|ui|screenshot] [--framework junit5|junit4]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
estimated-cost:
  min-tokens: 3000
  max-tokens: 22000
  model-distribution:
    haiku: 15%
    sonnet: 75%
    opus: 10%
---

# Generate Tests
<!-- Updated: June 2026 -->

Detect the test framework the project already uses (never introduce a second), delegate
generation to `and-test-generator`, and verify the result with the Gradle wrapper.

[Extended thinking: Test generation must match the repo's existing stack — JUnit5 vs
JUnit4, MockK vs mockito, Roborazzi vs Paparazzi. This command detects that, hands
`and-test-generator` the target and the detected stack, then runs the new tests to confirm
green. It does not author tests itself.]

## CRITICAL BEHAVIORAL RULES

1. **Detect the existing framework; never add a second one.**
2. **Delegate generation to `android-developer:and-test-generator`** — one agent.
3. **Verify** the generated tests via `./gradlew` before reporting.
4. **Single-command Bash invocations.**
5. **Never enter plan mode.**

## Usage

```bash
/android-developer:gen-tests :feature:login --type unit
/android-developer:gen-tests app/.../ProfileScreen.kt --type ui
/android-developer:gen-tests :core:ui --type screenshot
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `target` | required | Module, package, or file to generate tests for. |
| `--type unit\|ui\|screenshot` | unit | Test kind. |
| `--framework junit5\|junit4` | auto-detect | Override the detected runner (rarely needed). |

## Workflow

### 1. Detect the stack
`useJUnitPlatform()` → JUnit5 (`junit-jupiter`) else JUnit4; `mockk` vs `mockito-kotlin`;
`app.cash.turbine` for Flow tests; `roborazzi` vs `paparazzi` (if neither, prefer
Roborazzi); presence of `compose.ui:ui-test-junit4`. Read the build files and an existing
test for the convention.

**`--framework` overrides detection**: when supplied it becomes `{runner}` in step 2
regardless of what was detected. Report both (`{chosen} (overrode detected {detected})`)
and flag a contradiction — the runner's dependency may be missing, and the generated tests
will not compile until it is added.

Open the log every later step appends to: `mkdir -p .context/logs`, `TS="$(date +%Y%m%d-%H%M%S)"`,
`LOG=".context/logs/gentests-${TS}.log"`.

### 2. Delegate generation
**Use Task tool with subagent_type="android-developer:and-test-generator"**
Prompt: "Generate `{type}` tests for `{target}`. Existing stack: runner={runner},
mocking={mock-lib}, screenshot={ss-lib}. Match it — do NOT introduce a second
framework. Follow `skill: quality` patterns; place tests in the correct source set
(`test/` for unit, `androidTest/` for instrumented)."

### 3. Verify and count
`touch "$LOG.start"` — the freshness marker the count below reads — then run the new tests:
`./gradlew {module}:testDebugUnitTest --tests <NewClass> 2>&1 | tee -a "$LOG"` (unit),
`connectedDebugAndroidTest` (ui), or for screenshot: first `recordRoborazziDebug` /
`recordPaparazziDebug` to generate baseline images, then `verifyRoborazziDebug` /
`verifyPaparazziDebug` to confirm they match.

Then apply **`/android-developer:build-test` § Phase 5: Count**. It reads three names this
command must bind first: `path` (the project root, `.` unless given), `TASK` (the task just
invoked, e.g. `:feature:login:testDebugUnitTest`), and `<module-dir>` (that module's own
directory, `:feature:login` → `feature/login`).

**0 executed FAILS this command**: the scoped `--tests <NewClass>` selector matched nothing,
which is the written-but-never-executed defect itself. A green whole-module suite does not
redeem it and is not consulted.

### 4. Report
The files added, the executed count, and the pass/fail result.

## Output Format

```markdown
## Generated Tests
**Target:** {target}  **Type:** {type}  **Framework:** {chosen — note if `--framework` overrode detection}
**Log:** .context/logs/gentests-{ts}.log

| Test file | Covers | Result |
|-----------|--------|--------|
| LoginViewModelTest.kt | load/error states | ✅ |

**Result:** {A} tests added, {E} executed, {M} failed
```

## Error Handling

### No test source set
If the module has no `test/`/`androidTest/` source set, the agent scaffolds one; report it.

### Scoped run executed nothing
0 executed from the scoped `--tests <NewClass>` run is a FAILURE, never a pass. The class
name or package is wrong, the file landed in the wrong source set, or the runner's
dependency is missing so the class never compiled in. Report the selector used and the
result directory read; do not fall back to a whole-module count.

### Multiple frameworks detected
Report the conflict and ask which to match — never generate against both.

## See Also
- `skill: quality` / `skill: testing-principles` — framework matrix and patterns.
- `/android-developer:build-test` — run the full unit suite after generating.
