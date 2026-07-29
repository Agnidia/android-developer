---
description: Configure Android debugging workflows (logcat, StrictMode, layout inspector), or root-cause a crash or ANR
argument-hint: [error, stack trace, ANR trace, or component scope] [--device SERIAL]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
estimated-cost:
  min-tokens: 2000
  max-tokens: 15000
  model-distribution:
    haiku: 20%
    sonnet: 70%
    opus: 10%
---

# Debug
<!-- Updated: June 2026 -->

Set up Android debugging instrumentation for an ongoing investigation, **or** triage and
root-cause a crash, ANR, or exception already in hand.

## Modes

- **Configure mode (default)** — invoked with a component scope or no argument: set up
  logcat filters, StrictMode, Compose layout inspection, and breakpoints for an ongoing
  investigation. This is the workflow below.
- **Triage mode** — invoked with a concrete stack trace, `Exception`, ANR trace, or
  tombstone: classify → root-cause → propose the minimal fix for one specific error. See
  **Triage Mode** below. Detect triage mode when `$ARGUMENTS` contains a stack frame,
  exception class name, or ANR/tombstone text rather than a component scope.

[Extended thinking: The two modes have opposite tool postures. Configure mode adds
instrumentation — it writes StrictMode setup, log tags, and debug-variant config. Triage
mode is advisory: given one failure, work backwards to the cause and propose the smallest
fix, without mutating source unless asked. Splitting them by argument shape keeps a bare
`/debug` from editing anything unexpected, and keeps a pasted stack trace from turning into
an instrumentation project.]

## CRITICAL BEHAVIORAL RULES

1. **Detect the mode from the argument shape** before doing anything else.
2. **Triage is advisory by default.** `allowed-tools` includes `Write`/`Edit` because
   Configure mode needs them; triage proposes a fix and does not mutate source unless the
   user asks.
3. **One agent.** `android-developer:android-developer` owns both modes; escalate a
   structural root cause to `android-developer:kotlin-architector`.
4. **Single-command Bash invocations.** `adb logcat -d`, `adb shell dumpsys`,
   `./gradlew :app:installDebug`. Never `cd`-chain or `&&`-chain.
5. **Honour `--device`.** When supplied, insert `-s SERIAL` into every adb command
   (`adb -s SERIAL logcat -d`). The tables below write bare `adb` for readability;
   that form is correct only for a single attached device.
6. **Tee capture to the log** at `.context/logs/debug-<timestamp>.log`.
7. **No device is not a failure.** If `adb devices` is empty, do the static analysis and
   report what needs a device.
8. **Never enter plan mode.**

## Usage

```bash
/android-developer:debug :feature:cart                    # configure mode
/android-developer:debug "java.lang.IllegalStateException: ..."   # triage mode
/android-developer:debug ~/Downloads/anr_2026-06-01.txt   # triage an ANR trace
/android-developer:debug . --device emulator-5554
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `error` \| `scope` | none → configure | A stack trace/ANR selects triage mode; a component scope selects configure mode. |
| `--device SERIAL` | first attached | Target a specific `adb` device when several are connected. Passed as `adb -s SERIAL <subcommand>` on **every** adb invocation below — bare `adb` fails with `more than one device/emulator` exactly when this flag matters. Omit `-s` only when `--device` was not supplied. |

## Configure Mode

### 1. Environment

`adb devices -l` (record the target), `adb shell getprop ro.build.version.sdk` for the API
level, and confirm the debug variant is installed. Create `.context/logs/`.

### 2. Log capture

| Need | Command |
|------|---------|
| Live tail, app only | `adb logcat --pid=$(adb shell pidof -s <applicationId>)` |
| Crash buffer | `adb logcat -b crash -d` |
| Prior boot | `adb logcat -L` |
| By tag/level | `adb logcat -s MyTag:D AndroidRuntime:E` |
| ANR traces | `adb shell cat /data/anr/traces.txt` (or `adb bugreport`) |

Tee every capture to `$LOG`.

### 3. Instrumentation

**Use Task tool with subagent_type="android-developer:android-developer"**
Prompt: "Configure debugging for `{scope}`. Add, in the debug variant only: 1) StrictMode
`ThreadPolicy`/`VmPolicy` in `Application.onCreate` with `penaltyLog` (add `detectLeakedClosableObjects`
and `detectActivityLeaks`); 2) a namespaced `Log`/`Timber` tag with structured messages at
the suspected boundary — never log PII or tokens; 3) coroutine debug support
(`-Dkotlinx.coroutines.debug`, `CoroutineName` on the suspect scopes) per
`skill: coroutines-flow`; 4) for a recomposition problem, the Compose recomposition
counts/highlighter and layout-inspector entry points per `skill: compose-best-practices`.
Keep all instrumentation out of the release variant."

### 4. Inspection tools

| Symptom | Tool |
|---------|------|
| Wrong/missing UI, bad layout | Android Studio Layout Inspector (Compose semantics tree) |
| Excess recomposition | Compose recomposition counts; `Modifier.recomposeHighlighter` |
| Jank / dropped frames | `adb shell dumpsys gfxinfo <pkg> framestats`, Perfetto |
| ANR (main thread blocked) | `/data/anr/traces.txt`, StrictMode `penaltyLog` |
| Memory growth / leak | `adb shell dumpsys meminfo <pkg>`, LeakCanary in the debug variant |
| Database state | `adb exec-out run-as <pkg> cat databases/<db>` |
| Network | OkHttp `HttpLoggingInterceptor` (debug variant only) |

## Triage Mode

Given one concrete failure, classify → root-cause → propose the minimal fix. Advisory:
do not edit source unless asked.

### T1. Classify

| Class | Signals |
|-------|---------|
| Crash | `FATAL EXCEPTION`, exception class + stack |
| ANR | `Input dispatching timed out`, main-thread frames blocked on I/O or a lock |
| Concurrency | `IllegalStateException` from the wrong thread, `NetworkOnMainThreadException`, `CancellationException` swallowed |
| Compose | `Composition` frames, "Reading a state that was created after…", infinite recomposition |
| Lifecycle | Fragment/Activity state loss, `LifecycleOwner` destroyed, leaked observer |
| Build/config | Manifest merge, ProGuard/R8 stripping, missing `keep` rule |

Record severity per `skill: severity-matrix`.

### T2. Root cause

**Use Task tool with subagent_type="android-developer:android-developer"**
Prompt: "Root-cause this Android failure. Evidence:\n{stack trace / ANR / logcat excerpt}\n
Class: {classification}. Deobfuscate against the mapping file if the trace is R8-obfuscated
(`build/outputs/mapping/<variant>/mapping.txt`). Trace the failing frame to source, name
the execution path that reaches it, and state the invariant that was violated. Check
recent changes to those files. For coroutine or Flow failures apply
`skill: coroutines-flow` (scope, cancellation, dispatcher); for recomposition failures
apply `skill: compose-best-practices` (stability, state read scope, side-effect keys).
Return the root cause with `file:line` evidence, alternate hypotheses you ruled out, and
the minimal fix. Advisory — do not edit."

If the cause is a structural boundary problem rather than a local bug, escalate to
`android-developer:kotlin-architector`.

### T3. Verify

Name the smallest test that should fail today and pass after the fix; add it via
`/android-developer:gen-tests` so the failure cannot return silently.

## Output Format

```markdown
## Debug — {configure|triage}
**Target:** {scope|error}  **Device:** {serial|none}  **Log:** .context/logs/debug-{ts}.log

<!-- configure mode -->
| Instrumentation | Where | Variant |
|-----------------|-------|---------|
| StrictMode ThreadPolicy | App.onCreate | debug |

**Capture commands:** {the logcat/dumpsys lines to run}

<!-- triage mode -->
**Class:** {crash|ANR|concurrency|compose|lifecycle|build}  **Severity:** P{n}
**Root cause:** {one sentence} — {file}:{line}
**Evidence:** {frames / log lines that establish it}
**Ruled out:** {alternate hypotheses and why}
**Minimal fix:** {change, as a diff sketch}
**Regression test:** {test to add}
```

## Error Handling

### No device attached
```
Note: adb devices lists no device.
Static analysis only — {these steps} need a device or emulator.
Suggestion: start an emulator, or `adb connect <host>:<port>`.
```

### Obfuscated stack trace with no mapping file
Report that `mapping.txt` for the variant is missing, deobfuscate what is legible, and note
which frames are unresolved. Do not guess symbol names.

## See Also
- `skill: coroutines-flow` — scopes, cancellation, dispatcher discipline.
- `skill: compose-best-practices` — recomposition and side-effect debugging.
- `/android-developer:fix-performance` — when the symptom is slow rather than wrong.
- `/android-developer:gen-tests` — lock the fix in with a regression test.
