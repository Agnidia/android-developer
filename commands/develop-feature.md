---
description: Develop an Android feature end-to-end — architecture, implementation, tests, security review — phase-gated
argument-hint: [feature description or issue reference] [--pattern clean-arch|mvi|mvvm] [--module NAME]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
estimated-cost:
  min-tokens: 10000
  max-tokens: 40000
  model-distribution:
    haiku: 20%
    sonnet: 60%
    opus: 20%
---

# Develop Feature
<!-- Updated: June 2026 -->

Take an Android feature from description to reviewed, tested code through four phases:
architecture → implementation → tests → security review, with a build gate after each and
an approval checkpoint between phases.

Agent chain: `kotlin-architector` → `android-phone-developer` → `and-test-generator` →
`and-security-auditor`.

[Extended thinking: The phases exist because each hands the next a different artifact —
a structure, then code, then a suite, then a verdict — and because a wrong decision in
phase 1 is cheap to fix and expensive to discover in phase 4. The checkpoints are the
whole point: they are where a human sees the design before it becomes 2,000 lines. Every
phase ends at the same build gate so a failure is attributed to the phase that caused it.]

## CRITICAL BEHAVIORAL RULES

You MUST follow these rules exactly. Violating any of them is a failure.

1. **Execute phases in order.** Do NOT skip, reorder, or merge phases.
2. **Stop at every PHASE CHECKPOINT.** Wait for explicit user approval before continuing.
   Use AskUserQuestion with the phase's output.
3. **Build-gate every phase.** `/android-developer:build-test {module}` must pass before
   the next phase starts. A red build halts the pipeline at the phase that broke it.
4. **Halt on failure.** On an agent error or a failing gate, STOP, present the error, and
   ask how to proceed. Do NOT silently continue.
5. **Write phase artifacts** to `.context/.feature-dev/` (`architecture.md`,
   `implementation.md`, `tests.md`, `security.md`) before the next phase reads them — do
   not rely on the context window.
6. **One agent per phase.** Use only this plugin's agents; do not fan out.
7. **Never enter plan mode.** This command IS the plan — execute it.

## Usage

```bash
/android-developer:develop-feature "offline-capable cart with optimistic updates"
/android-developer:develop-feature "biometric unlock" --pattern mvi --module :feature:auth
/android-developer:develop-feature "#412"
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `feature` | required | Description, or an issue reference to read the requirements from. |
| `--pattern clean-arch\|mvi\|mvvm` | from `arch-select` | Force the architecture instead of selecting one. |
| `--module NAME` | inferred | Gradle module to build the feature in; a new one is proposed if none fits. |

## Pre-flight

1. If `.context/.feature-dev/state.json` exists with `status: "in_progress"`, show the
   current phase and ask whether to resume or start fresh.
2. Otherwise create `.context/.feature-dev/` and `state.json`:
   ```json
   {
     "feature": "$ARGUMENTS",
     "status": "in_progress",
     "current_phase": 1,
     "completed_phases": [],
     "files_created": [],
     "started_at": "ISO_TIMESTAMP"
   }
   ```
3. Confirm `./gradlew` exists and record the target module.

## Phase 1: Architecture

**Use Task tool with subagent_type="android-developer:kotlin-architector"**
Prompt: "Design the Android architecture for: {feature}. Target module: {module}. Using
`skill: architecture`, select the pattern (or validate `{--pattern}`) and produce: the
Gradle module and package structure; the UiState/Intent/Effect types; the
Repository/UseCase interfaces and which layer owns each; the Hilt modules and binding
points (`skill: hilt-di`); the coroutine scopes and dispatchers with the cancellation
story (`skill: coroutines-flow`); and the persistence/network boundary
(`skill: room`, `skill: retrofit-networking`, `skill: offline-first`) including the
offline and conflict behavior if the feature is offline-capable. Prefer the smallest
viable structure — do not add a module split the feature does not need. Return an ordered,
independently-shippable implementation step list."

Write `.context/.feature-dev/architecture.md`.

---

### PHASE CHECKPOINT

**Completed:** Phase 1 — architecture selected, structure and boundaries defined, ordered
implementation steps produced.

**Next:** Phase 2 implements those steps in Kotlin/Compose, build-gated per step.

Stop here. Use AskUserQuestion to present the design and get approval before implementing.

---

## Phase 2: Implementation

**Use Task tool with subagent_type="android-developer:android-phone-developer"**
Prompt: "Implement: {feature}, following the architecture in
`.context/.feature-dev/architecture.md`. Work through the step list in order. Apply
`skill: compose-best-practices` (state hoisting, stability, keys, no side effects in
composition), `skill: material3` for theming and color roles — never literal colors —
`skill: navigation` for type-safe routes, and `skill: coroutines-flow` for scoping and
cancellation. Externalize every user-facing string to resources. Run
`/android-developer:build-test {module}` after each step and fix before moving on. Report
each file created or changed and which architecture step it satisfies."

Gate: `/android-developer:build-test {module}` — green before the checkpoint.
Write `.context/.feature-dev/implementation.md`.

---

### PHASE CHECKPOINT

**Completed:** Phase 2 — feature implemented, module builds green.

**Next:** Phase 3 generates the test suite against the project's existing framework.

Stop here. Use AskUserQuestion to present the implementation summary and get approval.

---

## Phase 3: Tests

**Use Task tool with subagent_type="android-developer:and-test-generator"**
Prompt: "Generate tests for the feature implemented in
`.context/.feature-dev/implementation.md`. Detect and match the project's existing stack —
never introduce a second framework. Cover: ViewModel state transitions (Turbine for Flow
assertions), UseCase/Repository logic against a fake data source, Compose UI behavior for
the primary user journey, and the error and offline paths named in the architecture. Follow
`skill: testing-principles` for the pyramid and `skill: testing` for the framework
patterns. Place tests in the correct source set (`test/` unit, `androidTest/` instrumented)."

Gate: `/android-developer:build-test {module}` including the new tests — all green and a
non-zero executed count. 0 executed blocks the phase.
Write `.context/.feature-dev/tests.md`.

## Phase 4: Security Review

**Use Task tool with subagent_type="android-developer:and-security-auditor"**
Prompt: "Security-review the feature in `.context/.feature-dev/implementation.md`. Check:
credential and token storage (DataStore + Tink — flag any `EncryptedSharedPreferences` or
EOL `androidx.security:security-crypto`); exported components and intent handling in the
manifest; network security config and any cleartext allowance; certificate pinning where
the threat model needs it; PII in logs; WebView configuration; permission usage against
the declared set; R8 rules that could strip a security check. Return P0-P3 findings with
`file:line` and a concrete fix. Review-only — do NOT edit."

Any P0 finding **blocks** completion: report it, halt, and ask how to proceed. Write
`.context/.feature-dev/security.md`.

## Output Format

```markdown
## Feature: {name}
**Module:** {module}  **Pattern:** {selected}  **Phases:** {n}/4 complete

| Phase | Agent | Result | Build |
|-------|-------|--------|-------|
| 1 Architecture | kotlin-architector | {pattern}, {n} steps | — |
| 2 Implementation | android-phone-developer | {n} files | ✅ |
| 3 Tests | and-test-generator | {n} added, {e} executed, {m} failed | ✅ |
| 4 Security | and-security-auditor | P0:{n} P1:{n} P2:{n} | — |

### Files
| File | Layer | Phase |
|------|-------|-------|

### Security Findings
| Severity | Location | Finding | Fix |
|----------|----------|---------|-----|

**Status:** COMPLETE / BLOCKED at phase {k} — {reason}

### Artifacts
`.context/.feature-dev/{architecture,implementation,tests,security}.md`
```

## Error Handling

### Build fails mid-phase
Stop at the failing step. Report the compiler/test output and the step that introduced it.
Route a correction to the phase's own agent — never skip forward to the next phase.

### Requirements too vague for Phase 1
Report which decisions cannot be made (data ownership, offline behavior, auth model) and
ask for them before designing. Do not invent requirements.

### P0 security finding
Halt before reporting COMPLETE. Present the finding and ask whether to fix now (route to
`android-developer:and-code-fixer`) or accept and document the risk.

## See Also
- `/android-developer:arch-select` — the standalone version of Phase 1.
- `/android-developer:gen-tests` — the standalone version of Phase 3.
- `/android-developer:review-code` — a code review pass over the finished feature.
- `/android-developer:build-test` — the gate used between every phase.
