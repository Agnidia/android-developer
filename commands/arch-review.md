---
description: Review an Android codebase against its detected architecture pattern and report boundary violations by severity
argument-hint: [path (default .)] [--pattern clean-arch|mvi|mvvm] [--severity P0|P1|P2|P3]
allowed-tools: Read, Glob, Grep, Bash
estimated-cost:
  min-tokens: 4000
  max-tokens: 20000
  model-distribution:
    haiku: 20%
    sonnet: 70%
    opus: 10%
---

# Architecture Review
<!-- Updated: June 2026 -->

Detect the architecture a module actually uses, evaluate it against that pattern's
playbook, and report anti-patterns, layer/module boundary violations, and testing gaps as
severity-rated findings.

[Extended thinking: Architecture drifts silently — a `Context` leaks into `domain`, a
ViewModel reaches past its repository, a `:feature:` module takes a dependency on a sibling
feature. This command reads the module graph and the code, names the pattern in force, and
scores against the playbook for that pattern. Report-only; fixes route through
`/android-developer:fix-refactor`.]

## CRITICAL BEHAVIORAL RULES

1. **Report-only.** No edits. Findings route to `/android-developer:fix-refactor`.
2. **Detect before judging.** Name the pattern in force and its confidence; do not review
   MVVM code against an MVI checklist.
3. **One agent.** `android-developer:kotlin-architector` performs detection and evaluation.
4. **Single-command Bash invocations** (`git ls-files`, `./gradlew :module:dependencies`).
5. **Severity-gated.** Honor `--severity` as the minimum reported level
   (`skill: severity-matrix`).
6. **Never enter plan mode.**

## Usage

```bash
/android-developer:arch-review .
/android-developer:arch-review :feature:cart --pattern clean-arch
/android-developer:arch-review . --severity P1
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `path` | `.` | Module, package, or project root to review. |
| `--pattern clean-arch\|mvi\|mvvm` | auto-detect | Review against a named playbook instead of the detected one. |
| `--severity P0..P3` | P2 | Minimum severity to report. |

## Step 1: Resolve Scope

| Input | Resolution |
|-------|-----------|
| Gradle path (`:feature:cart`) | That module and its declared dependencies |
| Directory | All `.kt` files recursively plus the module's build file |
| `.` | The settings file's module list; review the graph plus each module's top layer |

Capture the module graph: `./gradlew :module:dependencies --configuration implementation`
(fall back to reading `build.gradle.kts` when the task is unavailable).

## Step 2: Pattern Detection

**Use Task tool with subagent_type="android-developer:kotlin-architector"**
Prompt: "Detect the architecture in force for these Kotlin/Compose files. Signals:
`ViewModel` + `StateFlow`/`uiState` (MVVM, `skill: viewmodel-stateflow`); `Intent`/`reduce`/
single `UiState` + `Effect` channel (MVI); `UseCase`/`Repository` interface with a
`domain` package free of Android types (clean-arch, `skill: clean-architecture`); `:core:*`
vs `:feature:*` split (`skill: modularization`); `@HiltViewModel`/`@Module`/`@Binds`
(`skill: hilt-di`). Report the pattern, confidence (high/medium/low), evidence as
`file:line`, the DI style, and the concurrency model."

## Step 3: Playbook Evaluation

Evaluate against the matching playbook and these Android-specific gates:

| Gate | Looks for | Typical severity |
|------|-----------|------------------|
| Layer purity | `android.*`/`Context`/`Cursor` in `domain`; ViewModel importing a DAO or Retrofit service directly | P1 |
| Module boundaries | `:feature:a` → `:feature:b` edge; `:core:*` depending on a feature; `api` used where `implementation` suffices | P1 |
| State ownership | Mutable state exposed (`MutableStateFlow` public), UI state reconstructed in the composable, state hoisted to the wrong level (`skill: compose-best-practices`) | P1 |
| Concurrency boundaries | `GlobalScope`, hardcoded dispatcher instead of an injected one, collection outside a lifecycle scope (`skill: coroutines-flow`) | P1 |
| DI correctness | Field injection where constructor injection fits, `@Singleton` on request-scoped work, missing qualifier (`skill: hilt-di`) | P2 |
| DI correctness (non-Hilt) | This plugin ships Hilt guidance only. On a Koin or manual-DI project review the framework-independent properties — constructor injection over field/service-locator lookup, scope lifetime matching the consumer, no container access from the domain layer — and mark the framework-specific gate `not assessed (no {Koin\|manual} playbook)` rather than applying Hilt rules to it | P2 |
| Data boundaries | Room entity or DTO crossing into the UI layer instead of a domain model (`skill: offline-first`) | P2 |
| Testability | An architectural seam with no fake/interface, so the layer cannot be tested in isolation (`skill: testing-principles`) | P2 |

## Step 4: Findings

Severities follow `skill: severity-matrix`. For each finding:

```
[P{n}] {title}
  File: {path}:{line}
  Pattern: {anti-pattern name from the playbook}
  Issue: {what boundary breaks and why it matters}
  Fix: {concrete change}
```

## Output Format

```markdown
## Architecture Review
**Target:** {path}  **Pattern:** {detected} ({confidence})  **DI:** {Hilt|Koin|manual}

| # | Severity | Gate | Location | Finding |
|---|----------|------|----------|---------|
| 1 | P1 | Layer purity | CartUseCase.kt:12 | `domain` imports `android.content.Context` |

**Score:** PASS / WARN / FAIL   **Totals:** P0:{n} P1:{n} P2:{n} P3:{n}

### Module Graph Issues
- {edge} — {why it violates the strategy}

### Top 3 Recommendations
1. {highest-leverage fix}
```

Score is FAIL on any P0, WARN on any P1, otherwise PASS.

## Error Handling

### Pattern detection is low-confidence
Report the mixed signals and review against the generic gates (layer purity, module
boundaries, state ownership) rather than guessing a playbook.

### No Gradle wrapper
Skip the `dependencies` task, read `build.gradle.kts` for the graph, and note the gap.

## See Also
- `skill: architecture` — playbooks and anti-pattern catalogs.
- `/android-developer:arch-select` — choose the target pattern for new work.
- `/android-developer:fix-refactor` — apply a pattern change, build-gated per step.
- `/android-developer:analyze-tech-debt` — quantify and prioritize what the review finds.
