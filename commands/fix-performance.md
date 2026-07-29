---
description: Measure Android performance with Macrobenchmark and Perfetto, then optionally apply gated optimizations
argument-hint: [path or module (default .)] [--mode startup|jank|memory|all] [--apply] [--device SERIAL]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
estimated-cost:
  min-tokens: 5000
  max-tokens: 25000
  model-distribution:
    haiku: 20%
    sonnet: 70%
    opus: 10%
---

# Optimize Performance
<!-- Updated: June 2026 -->

Measure Android performance against a baseline (Macrobenchmark, Perfetto, `gfxinfo`),
identify the hot paths, and — only behind an explicit checkpoint — apply optimizations and
regenerate baseline profiles.

## Agent Routing

This plugin has **no `performance-engineer` agent**. Analysis therefore routes to
`android-developer:kotlin-architector`, which owns the module graph, startup dependency
order, and recomposition/state boundaries where Android performance problems actually
originate; mechanical application routes to `android-developer:code-fixer` under a
minimal-diff gate. Do not invoke another plugin's performance agent — it does not
understand Gradle variants, R8, or Compose recomposition.

[Extended thinking: The default path here is deliberately measure-only. Performance edits
applied without a before/after number are indistinguishable from superstition, and Compose
"optimizations" in particular (adding `remember`, `derivedStateOf`, `key`) routinely make
things slower when applied blind. So measurement is unconditional, application is opt-in
behind a checkpoint, and every applied change is re-measured against the recorded baseline.]

## CRITICAL BEHAVIORAL RULES

1. **Measure first, always.** Never propose an optimization without a baseline number for
   the metric it claims to improve.
2. **Default path is measure-only.** Applying changes requires `--apply` **and** passing the
   PHASE CHECKPOINT below. Without both, this command reports and stops.
3. **Stop at the checkpoint.** When you reach `PHASE CHECKPOINT`, stop and wait for
   explicit user approval. Use AskUserQuestion with the measured findings.
4. **Benchmark in release-like conditions.** Macrobenchmark against a `release`/`benchmark`
   variant with R8 on; a `debug` build's numbers are meaningless.
5. **Re-measure after every applied change.** A change with no measured improvement is
   reverted, not kept.
6. **Single-command Bash invocations.** `./gradlew :macrobenchmark:connectedBenchmarkAndroidTest`,
   `adb shell dumpsys gfxinfo`. Never `cd`-chain or `&&`-chain.
7. **Tee every measurement** to `.context/logs/perf-<timestamp>.log`.
8. **Never enter plan mode.**

## Usage

```bash
/android-developer:fix-performance .                       # measure only
/android-developer:fix-performance :app --mode startup
/android-developer:fix-performance :feature:feed --mode jank --apply
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `path` | `.` | Module or screen to profile. |
| `--mode startup\|jank\|memory\|all` | `all` | Which measurement track to run. |
| `--apply` | off | Enable the optimization phase — still gated by the checkpoint. |
| `--device SERIAL` | first attached | Benchmarks require a physical device or a properly configured emulator. |

## Phase 1: Baseline Measurement

### 1A. Startup (`--mode startup|all`)

Macrobenchmark `StartupTimingMetric` over cold/warm/hot:
```
./gradlew :macrobenchmark:connectedBenchmarkAndroidTest -P android.testInstrumentationRunnerArguments.class=<StartupBenchmark>
```
Fallback without a Macrobenchmark module:
`adb shell am start-activity -W -n <pkg>/<activity>` (report `TotalTime`, note the lower
fidelity). Targets: cold TTID under 500ms, TTFD under 1s on a mid-tier device.

### 1B. Jank / rendering (`--mode jank|all`)

`FrameTimingMetric` from Macrobenchmark, or
`adb shell dumpsys gfxinfo <pkg> framestats` around a scripted scroll. Capture a Perfetto
trace for the janky interaction. Targets: P95 frame duration inside the refresh budget
(16.6ms at 60Hz, 8.3ms at 120Hz), zero frozen frames (>700ms).

### 1C. Memory (`--mode memory|all`)

`adb shell dumpsys meminfo <pkg>` before/after the interaction; `MemoryUsageMetric` where
available; LeakCanary output from the debug variant if present.

### 1D. Analysis

**Use Task tool with subagent_type="android-developer:kotlin-architector"**
Prompt: "Analyze these Android performance measurements for `{path}`:\n{baseline numbers,
Perfetto/gfxinfo excerpts}\nIdentify the hot paths and rank them by measured cost. Cover:
startup work on the critical path (Application.onCreate, eager Hilt graph construction,
synchronous I/O, ContentProvider initializers, missing baseline profile); recomposition
cost (unstable parameters, state read at the wrong scope, allocation in composition,
missing `LazyColumn` keys) per `skill: compose-best-practices`; main-thread blocking and
dispatcher misuse per `skill: coroutines-flow`; data-layer cost (unindexed Room queries,
N+1 access, missing paging) per `skill: room` and `skill: offline-first`. For each finding
give `file:line`, the measured cost it explains, the proposed change, and its risk. Do NOT
edit — analysis only."

---

### PHASE CHECKPOINT

**Completed:** Phase 1 — baseline measured and hot paths ranked with `file:line` evidence.

**Next:** Phase 2 would apply the ranked optimizations, one at a time, re-measuring after
each and reverting any change that does not improve its target metric.

Stop here. If `--apply` was not passed, report the baseline and the ranked findings and
**end** — this is the default outcome. If `--apply` was passed, use AskUserQuestion to
present the findings and get explicit approval before continuing to Phase 2.

---

## Phase 2: Apply (requires `--apply` + approval)

For each finding, highest measured cost first:

1. **Apply:**
   **Use Task tool with subagent_type="android-developer:code-fixer"**
   Prompt: "Apply exactly this performance change: {finding, file:line, proposed change}.
   Minimal diff — do not refactor adjacent code, do not reformat. Report the change as
   `{file, line, before, after}`."
2. **Gate:** `/android-developer:build-test {module}` must pass.
3. **Re-measure** the same metric from Phase 1 with the same command.
4. **Keep or revert:** no measured improvement → revert and record why. Never keep a change
   on the theory that it should have helped.

### Baseline profiles

When startup or scroll jank is the target, generating a baseline profile is usually the
single highest-yield change: add the `androidx.baselineprofile` plugin, record via
`./gradlew :app:generateBaselineProfile`, and verify the startup delta. Treat it as one
numbered finding with its own before/after.

## Output Format

```markdown
## Performance — {measure-only | applied}
**Target:** {path}  **Mode:** {startup|jank|memory|all}  **Device:** {model, API}
**Variant:** {release|benchmark}  **Log:** .context/logs/perf-{ts}.log

### Baseline
| Metric | Measured | Target |
|--------|----------|--------|
| Cold startup (TTID) | 780ms | <500ms |
| P95 frame | 22.4ms | <16.6ms |
| Frozen frames | 3 | 0 |

### Findings (ranked by measured cost)
| # | Finding | Location | Explains | Proposed change | Risk |
|---|---------|----------|----------|-----------------|------|
| 1 | Room query on the startup path | App.kt:44 | ~180ms of TTID | move behind a lazy init | low |

<!-- applied mode only -->
### Applied
| # | Change | Build | Before | After | Kept |
|---|--------|-------|--------|-------|------|
| 1 | lazy DB init | ✅ | 780ms | 610ms | ✅ |
| 2 | derivedStateOf on filter | ✅ | 22.4ms | 22.6ms | ❌ reverted (no gain) |

**Net:** {metric} {before} → {after} ({delta})
```

## Error Handling

### No device / emulator only
```
Warning: Macrobenchmark requires a physical device (or a benchmark-configured emulator)
for trustworthy numbers. Emulator results are reported as indicative only.
```
Proceed with the measurements that are possible and label their fidelity.

### No Macrobenchmark module
Report it, fall back to `am start -W` and `dumpsys gfxinfo`, note the reduced fidelity, and
recommend adding a `:macrobenchmark` module for repeatable numbers.

### Debug variant only
Refuse to report the numbers as a baseline. Explain that R8 and debuggability distort them,
and name the variant to build instead.

## See Also
- `skill: compose-best-practices` — recomposition, stability, state read scope.
- `skill: coroutines-flow` — dispatcher and main-thread discipline.
- `skill: gradle-build` — R8/ProGuard, build variants, baseline profiles.
- `/android-developer:build-test` — the gate between apply and re-measure.
- `/android-developer:debug` — when the symptom is wrong behavior rather than slow.
