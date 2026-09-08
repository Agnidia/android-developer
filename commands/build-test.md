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

# Build & Test
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
3. **Single-command Bash invocations.** Never `cd`-chain or `&&`-chain.
4. **Tee every phase to the log.** Pipe through `tee -a` to
   `.context/logs/build-<timestamp>.log`.
5. **An exit code is not evidence that tests ran.** Count executed tests from the result
   XML every run; 0 executed is a FAILURE.
6. **On failure, classify before delegating.** Parse the first error, classify it as
   configure / compile / test, then delegate ONLY to `android-developer:android-phone-developer`
   with the excerpt.
7. **Tool-missing never hard-fails.** If `./gradlew` cannot run (no JDK), print the hint
   and report — do not crash.
8. **Never enter plan mode.** Execute the procedure.

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
4. **Resolve the toolchain environment before any Gradle invocation.** Gradle needs both,
   and neither is guaranteed to be exported in the shell a stage happens to run in — a
   stage that inherits them silently succeeds while the next stage, invoking the same
   command, fails with a `sdk.dir` error that reads as a broken project rather than a
   missing variable. Export what is missing rather than assuming it:

   ```bash
   # SDK: honour an existing ANDROID_HOME/ANDROID_SDK_ROOT, else fall back to the
   # standard install location. Skip entirely if local.properties already pins sdk.dir.
   if [ -z "${ANDROID_HOME:-}" ] && [ -z "${ANDROID_SDK_ROOT:-}" ] \
      && ! grep -qs '^sdk\.dir=' "$path/local.properties"; then
     if [ -d "$HOME/Library/Android/sdk" ]; then           # macOS
       export ANDROID_HOME="$HOME/Library/Android/sdk"
     elif [ -d "$HOME/Android/Sdk" ]; then                 # Linux
       export ANDROID_HOME="$HOME/Android/Sdk"
     fi
   fi
   : "${ANDROID_HOME:=${ANDROID_SDK_ROOT:-}}"; export ANDROID_HOME

   # JDK: Android Studio's bundled JBR is frequently the only JDK present.
   if [ -z "${JAVA_HOME:-}" ] && [ -d "/Applications/Android Studio.app/Contents/jbr/Contents/Home" ]; then
     export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
   fi
   ```

   If neither an SDK path nor `sdk.dir` can be resolved, stop with the Android SDK row from
   Failure Triage — do not start a build that will fail several minutes later on a message
   that points at the wrong thing.

### Phase 2: Clean (optional, Bash)
If `--clean`: `./gradlew clean 2>&1 | tee -a "$LOG"`.

### Phase 3: Assemble (Bash)
`./gradlew <module>:assemble<Variant> 2>&1 | tee -a "$LOG"`. Capture `${PIPESTATUS[0]}`.
On non-zero, classify (configure vs compile) and go to Failure Triage.

### Phase 4: Test (Bash)
Under `--no-test`, skip this phase and Phase 5; the test row reads `⏭ not run (--no-test)`
and no count is reported or invented. Otherwise:

1. `TASK=":<module>:test<Variant>UnitTest"` — the invoked task, and the only task whose
   outcome step 4 may read.
2. `touch "$LOG.start"` — the freshness marker, immediately before the invocation so the
   window in which another writer could be mistaken for this run stays narrow.
3. `./gradlew "$TASK" 2>&1 | tee -a "$LOG"`; capture `TEST_STATUS="${PIPESTATUS[0]}"`.
4. `OUTCOME="$(outcome_of "$LOG")"` — the reader defined in **Test Verdicts § Reading the
   task outcome**. `tee` makes stdout a pipe, so Gradle falls back to the plain console and
   prints one durable line per task.
5. **Branch on nothing here.** Phase 5 runs next whatever `TEST_STATUS` is.

### Phase 5: Count (Bash)
Runs unconditionally, on the red path too.

1. `RES="$path/<module-dir>/build/test-results/${TASK##*:}"` — the invoked task's own
   results under the module's own dir: not the project root, and not the module-wide tree
   where a stale `testReleaseUnitTest/` would sum in.
2. Sum the `<testsuite>` attributes over every `TEST-*.xml` there:

   ```bash
   sum_attr() {  # $1=attr, $2=dir; 0 if nothing matches
     find "$2" -name 'TEST-*.xml' -exec cat {} + 2>/dev/null \
       | grep -o '<testsuite [^>]*' | grep -oE " $1=\"[0-9]+\"" \
       | grep -oE '[0-9]+' | awk '{ s += $1 } END { print s + 0 }'
   }
   ```

   `executed = tests - skipped`; `failures`, `errors`, `skipped` likewise. The leading
   space keeps `name="com.foo.tests.BarTest"` out of the sum.
3. `find "$RES" -name 'TEST-*.xml'`, with and without `-newer "$LOG.start"`, classifies the
   result XML `fresh` / `stale only` / `none`; resolve the verdict from **Test Verdicts**.

### Phase 6: Report (Bash)
Emit the Output Format summary, including the executed count, the verdict and the result
path. On a passing verdict, stop.

## Test Verdicts

Three oracles, each asked only what it can answer: `OUTCOME` says what ran, the freshness
marker says whose result files these are, the XML says how many.

### Reading the task outcome

```bash
outcome_of() {  # $1=log; prints the outcome word, `executed`, or `unresolved`
  local l
  l=$(grep -E "^> Task ${TASK}( |$)" "$1" | tail -1)
  [ -n "$l" ] || { echo unresolved; return; }
  awk '{ print ($4 == "" ? "executed" : $4) }' <<<"$l"
}
```

The `$TASK` anchor is load-bearing. `compileDebugUnitTestKotlin`, `processDebugUnitTestJavaRes`
and `jacocoTestReport` all carry "test" in their names, and a failed test *compilation* prints
no test-task line at all — which must read `unresolved`, never as a test failure.

### The result-XML axis

`fresh` — at least one `TEST-*.xml` postdates the marker. `stale only` — files exist, none
postdate it. `none` — the task wrote none at all.

### The table

Rows are matched top to bottom and the first match wins, so every reachable
(`OUTCOME`, result-XML) pair resolves to exactly one verdict.

| `OUTCOME` | Result XML | Verdict | Result |
|---|---|---|---|
| `executed` / `FAILED` | fresh | `fresh` | PASS if `executed > 0`, `failures + errors = 0`; else triage |
| `executed` / `FAILED` | stale only | `stale` | **FAIL** — the task ran yet wrote nothing; the totals are a prior run's |
| `UP-TO-DATE` / `FROM-CACHE` | fresh / stale only | `cached` | PASS on the same terms |
| `NO-SOURCE` | any | `no-tests` | **FAIL** — no test source set |
| `SKIPPED` | any | `no-tests` | **FAIL** — the task is disabled (`onlyIf` false, `enabled = false`) |
| `unresolved` | any | `unknown` | **FAIL** — report it, never guess |
| `FAILED` | none | `aborted` | **FAIL** — the task failed and wrote nothing; triage on the log |
| any | none | `no-results` | **FAIL** |

### Overrides

`executed = 0` **FAILS** whatever the row or the exit status; `--no-test` skips the table.
A `FAILED` task is `fresh` like any other task that ran: the counts back its report and
Failure Triage receives them, which is the whole point of counting first.

### After the verdict

Counting ran before this point on purpose: triage that fires first reports a `{M} failed`
it never had, and the excerpt it delegates is weaker for it.

`cached` passes at every stage — Gradle asserts the inputs are unchanged. `stale` and
`unknown` are where an operator re-runs once with `--rerun-tasks`, a diagnostic on an
already-broken run and never a default.

`zero-executed`, `no-tests` and `no-results` fail **without delegating**: the log names no
failure, so `android-phone-developer` would have nothing to diagnose. Every other failing run
goes to Failure Triage carrying its counts — `aborted` above all, because a test JVM killed
by a crash or the OOM killer prints `FAILED` and writes no XML, which is the case that most
needs the log read and the one a verdict-only rule would skip.

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
| Test | ✅ / ❌ / ⏭ | {E} executed, {M} failed, {R} errored, {S} skipped ({verdict}) — or `not run (--no-test)` |

**Test results:** {result-dir path, or "none produced"}
**Result:** PASS / FAIL ({failing stage or verdict})
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

### No test results produced
```
Error: 0 tests executed for {module} — verdict {verdict}.
Results: {result-dir path, or "no result directory"}
```
A passing exit code is not evidence that tests ran, so this is a FAILURE. Likely causes:
the module has no `test/` source set; a `--tests` filter matched nothing; result XML is
disabled or redirected in the build script; the task is disabled (`onlyIf` false,
`enabled = false`); the task aborted after an earlier run left
stale XML. Re-run once with `--rerun-tasks` to separate `cached` from `stale`. Not
delegated — there is no failure in the log to diagnose, unless the task itself reported
`FAILED`, which is the `aborted` verdict and does go to triage.

### Module not found
Report the available modules (`./gradlew projects`) and stop.

## See Also
- `/android-developer:fix-quick` — run ktlint/detekt before building to cut noise.
- `/android-developer:gen-tests` — add tests when a module has none.
- `/android-developer:deps audit` — when a `configure`-stage failure is a dependency issue.
- `skill: tooling` — Gradle build configuration and the Android CLI.
