---
name: workflow-integration
description: Guide for integrating with the igrsoft 11-stage workflow system (v3.36.0). Use when participating in structured workflow stages as an android-developer agent.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-14'
  keywords: [workflow-integration, handoff-protocol, android, dv-stage, cli-fallback]
---

# Workflow Integration Guide

When invoked from the igrsoft workflow system, follow these guidelines for seamless
collaboration.

## 11-Stage Pipeline (Default)

```
PL → AR → TL → DV → DR → SR → QA → DC → RE → FN → ST
     ↑         ↑    ↑    ↑    ↑              ↑
  android-developer agents contribute to AR, DV, DR, SR, QA, and RE
```

| Code | Stage | igrsoft Agent | android-developer Contribution |
|------|-------|---------------|--------------------------------|
| PL | Planning | product-manager | — |
| AR | Architecture | software-architector | `kotlin-architector` (consult: Clean Arch, modularization, Hilt graph, MVI vs MVVM) |
| TL | Team Lead | team-lead | — |
| DV | Development | developer → **android-developer** | **Primary**: router → `android-phone-developer` |
| **DR** | **Developer Review** | **technical-lead** | **Support**: `code-fixer` (fix application), `kotlin-architector` (pattern consult) |
| SR | Security Review | security-reviewer | Context: `security-auditor` (permissions, exported components, R8, secrets, network-security-config) |
| QA | QA Testing | qa-engineer | Support: `test-generator` (JUnit/MockK/Turbine/Compose/Roborazzi) |
| DC | Documentation | technical-writer | — |
| RE | Release Engineering | release-engineer | Packaging: `dependency-manager` (version catalogs, pins), versionCode/versionName, AAB/APK notes |
| FN | Finalization | project-manager | — |
| ST | Stakeholder | stakeholder | — |

## Worktask Triggers (v3.36.0)

| Trigger | Stages | Use Case |
|---------|--------|----------|
| `micro:` | Plan → approve → edit | Single-file fixes, typos |
| `quick:` | PL → DV → DR → QA | Small features, bug fixes |
| `worktask:` | Full 9-stage (PL→AR→TL→DV→DR→QA→DC→FN→ST) | Multi-file features |
| `fworktask:` | Full 9-stage, auto-continue | Trusted full runs |
| `--secure` / `--full` | 11-stage (adds SR, RE) | Security-critical work |
| `emergency:` | IR→DV→DR→QA→RE→FN | Hotfixes, incidents (DR enforces minimal-diff) |

## DV Contract for Android Work

The DV agent writes `.context/development-N.md`. Mandatory H2 anchors are fixed by
igrsoft's anchor allow-list (`handoff-protocol.md#anchor-allow-list`): `## files-changed`,
`## tests-added`, `## deviations`, `## follow-ups`. Android-specific sections nest as H3
under them:

| Section | Anchor level | Content |
|---------|--------------|---------|
| Files Changed | `## files-changed` | File / change / why table |
| Decisions | `### decisions` (under files-changed) | Non-obvious implementation choices with rationale |
| Tool Invocations | `### tool-invocations` (under files-changed) | Exact build/lint commands run (`./gradlew assembleDebug`, `./gradlew test`, `ktlintCheck`, `detekt`) |
| Tests Added | `## tests-added` | Test files + what each covers |
| Build Evidence | `### build-evidence` (under tests-added) | Kotlin + AGP version, ktlint/detekt warning count (target: 0), unit-test transcript path in `.context/logs/` |
| Deviations | `## deviations` | Departures from `analyzing-N.md` decisions |
| Follow-ups | `## follow-ups` | Deferred work, flagged risks |

Build Evidence is non-negotiable: a DV artifact without a Kotlin/AGP version line, a
ktlint/detekt finding count, and a test transcript path under `.context/logs/` is
incomplete. Tee raw build/test output to `.context/logs/<tool>-<worktask_id>.log`.

Copy-paste template: [templates/dv.md](templates/dv.md).

## Screenshot Gate for Android Work (HIGHEST INTEGRATION RISK — read this)

igrsoft's `dv-screenshot-gate.sh` blocks `SubagentStop` when
`metadata.requires_screenshots != false` and no manifest exists at
`.context/images/<worktask_id>/screenshots.md`. The igrsoft default is **TRUE** — but
most Android/Kotlin work has no emulator-screenshot dependency and is verified through
Gradle/CLI evidence. Handle it in this order:

1. **Preferred**: the dispatcher sets `metadata.requires_screenshots: false` for
   android-developer DV stages whose change has no visual surface (logic, data, build).
   Then no manifest is required and the gate is skipped. Plugin norm:
   `requires_screenshots: false` is the **default expectation** — flag it in your return
   summary if the metadata says otherwise.
2. **cli-fallback procedure** (when the flag is unset/true and you cannot change it):
   produce the manifest anyway using terminal transcripts —
   - Capture each meaningful surface as text: `./gradlew assembleDebug` output, the unit-
     test run, `ktlintCheck`/`detekt` reports, and (for a UI change) `adb logcat` or
     `adb shell screencap` output. Save under `.context/images/<worktask_id>/`.
   - Write `.context/images/<worktask_id>/screenshots.md` with one row per capture,
     `source: cli-fallback`, and a `notes` cell explaining why.
   - Frontmatter `screenshot_count` MUST equal the number of table rows.
3. **Never** fabricate image files or return without either the `false` flag or a
   cli-fallback manifest — the gate re-dispatches DV until one exists.
4. **Evidence freshness**: every `cli-fallback` transcript or `adb shell screencap` row
   must be produced *this run* from the actual invocation — never reuse one from a prior
   run or another workdir. igrsoft QA direct-reads the evidence files and cross-checks them
   against the `### build-evidence` log paths in the DV artifact; a stale or duplicated
   transcript/capture is flagged and re-opens DV. Extends the never-fabricate bar in rule 3
   to reused text and image evidence.
5. **Armed-gate provenance (`ui_visual_check: true`)**: when a dispatcher explicitly arms it
   for UI-critical work, statically produced renders (host-side Roborazzi/Paparazzi images,
   un-interacted screens) do NOT satisfy the gate — reach each named substate on a
   device/emulator through real interactions (taps/typing via `adb input`, or a driven
   Compose/Espresso run), confirm the primary controls are displayed and enabled, THEN
   `adb shell screencap` from the live-driven state, recording the interaction path in
   `notes`. This is conditional — the `requires_screenshots: false` default remains the norm.

Manifest row format mirrors igrsoft's `dv-screenshot-capture` output:
`| name | path | source | design_ref | notes |` with `source` ∈ {`cli-fallback`} for CLI/
Gradle evidence; `design_ref` stays blank unless a Compose screen maps to a mockup. See
[templates/dv-screenshots.md](templates/dv-screenshots.md).

## Per-Agent Error Files

Parallel-safe retry narratives live in `.context/errors/<agent-basename>.md` — basename =
last `:`-separated segment of the qualified name:

| File | Purpose |
|------|---------|
| `.context/errors/android-phone-developer.md` | Phone/tablet DV retry narratives |
| `.context/errors/kotlin-architector.md` | Architecture/structural retry narratives |
| `.context/errors/test-generator.md` | Test-generation retries |
| `.context/errors/code-fixer.md` | DR fix-application retries |
| `.context/errors/<agent-basename>.md` | One file per agent — never overwrite a shared `error.md` |

Derive your own path from `task.metadata.error_file` or your frontmatter `name:`.

## DR Android Review Criteria

technical-lead reads `development-N.md` + error files and produces `developer-review-N.md`
(verdict `pass`/`fail`). android-developer agents support DR and pre-check against these
criteria before returning from DV:

| Area | What DR checks |
|------|----------------|
| Compose stability | Stable parameters, state hoisted, no business logic in composables, keys on lazy lists, no allocation in composition, no unbounded recomposition |
| Coroutine discipline | No `GlobalScope`; injected dispatchers; lifecycle-aware collection (`repeatOnLifecycle`/`collectAsStateWithLifecycle`); structured `viewModelScope` launches; no main-thread blocking |
| Architecture purity | No Android framework types in `domain`; ViewModel exposes immutable `StateFlow`; dependency direction inward to `domain`; no concrete data source in the ViewModel |
| Resource externalization | No hardcoded strings/colors/dimens; `stringResource`/theme tokens used |
| Lint hygiene | 0 ktlint + 0 detekt findings; suppressions justified; no committed build artifacts; `libs.versions.toml` updated with any new dependency |

Template: [templates/dr-review.md](templates/dr-review.md).

## QA Gate for Android Work

QA (`testing-N.md`, verdict `go`/`no-go`) passes only when **both** hold:

1. **All tests pass** — full suite, not just new tests (`./gradlew test` for unit;
   `./gradlew connectedDebugAndroidTest` for instrumented where a device/emulator is
   available).
2. **Lint clean on changed components** — `./gradlew ktlintCheck detekt lint` reports
   zero findings on the changed modules. Screenshot tests (Roborazzi/Paparazzi) verify
   green where the change is visual.

`test-generator` supports QA with framework-native generation (JUnit/MockK/Turbine/
Compose/Roborazzi). Template: [templates/qa-testing.md](templates/qa-testing.md).

## SR and RE Contributions

- **SR** — `security-auditor` provides platform context to igrsoft's security-reviewer:
  permission hygiene, exported-component exposure, insecure storage, transport security
  (network-security-config, pinning), R8/ProGuard hardening, secrets scan, and WebView/
  deep-link surfaces. Review-only: findings route to `code-fixer` for application.
- **RE** — release-engineer owns the stage; android-developer contributes packaging:
  `dependency-manager` freezes version-catalog pins (`libs.versions.toml`, BOMs), and the
  implementer records versionCode/versionName, signing/ABI notes, and R8 mapping retention
  in `release-N.md`.

## Artifact Filename Contract (v3.36.0)

**Numbered `<stage>-N.md` names are canonical** per igrsoft's `handoff-protocol.md#stage-artifact-map`.
N is allocated by PL0, shared across all stages within a run, and propagated via
`task.metadata.run_index`; it bumps on gate loop-back re-dispatch. Readers fall back to
newest-glob (`<basename>-*.md`).

| Stage | Artifact | Owner |
|-------|----------|-------|
| PL | `planning-N.md` | product-manager |
| AR | `analyzing-N.md` | software-architector |
| TL | `coordination-N.md` | team-lead |
| DV | `development-N.md` | developer / android-developer agents |
| DR | `developer-review-N.md` | technical-lead |
| SR | `security-review-N.md` | security-reviewer |
| QA | `testing-N.md` | qa-engineer |
| DC | `documentation-N.md` | technical-writer |
| RE | `release-N.md` | release-engineer |
| FN | `complete-summary-N.md` | project-manager |
| ST | `retrospective-N.md` | stakeholder |
| IR | `incident-N.md` | incident-responder |

**Emit `handoff:` frontmatter unconditionally — it is the merge input regardless of
filename.** state.json reconciliation is three-layered: Layer 1 (agent runs
`state-patch.sh --stage <CODE> --prev <PREV>` when its path is supplied, else skips —
never a hand-rolled `jq`/manual merge), Layer 2 (orchestrator re-reads artifact
frontmatter after `Task()` returns), Layer 3 (`SubagentStop` hook auto-merge). Attempt
Layer 1; if the script or its path is absent, proceed — Layers 2 and 3 repair from
frontmatter.

## Handoff Frontmatter (v3.36.0 schema)

Every stage artifact MUST start with a YAML block between `---` markers. Budgets:
≤200 tokens, ≤30 lines. Base required fields: `stage`, `verdict`, `summary` (≤200 chars),
`refs`. Per-stage additions:

| Stage | Required beyond base | Verdict vocabulary |
|-------|----------------------|--------------------|
| DV | `files_touched`, `next_stage_focus` | ok / blocked / escalate |
| DR | `key_decisions` (= findings) | pass / fail |
| QA | `files_touched` (= tests added), `key_decisions` (= results) | go / no-go |

`key_decisions[].anchor` and `refs.*` MUST resolve to a real `## <kebab-case>` heading in
the target file (anchor-lint enforces this at DR and via the PostToolUse hook). Copy-paste
blocks: `templates/` in this directory.

## Gate-Feedback Contract (v3.36.0)

When DR returns `verdict: fail` or QA returns `verdict: no-go`, the orchestrator re-
dispatches DV (`run_index` bumped, `retry_count`++) and carries the upstream remediation
**verbatim** into the retry prompt. android-developer agents **consume** this contract; the
injection is orchestrator-owned.

| Surface | Mechanism | android-developer action |
|---------|-----------|--------------------------|
| Orchestrator → DV prompt | On re-dispatch (`metadata.retry_count > 0`) the prompt is prepended with `REMEDIATION (from <DR\|QA> gate — fix these specific findings before re-stop:)`; `metadata.gate_from_stage` ∈ {DR, QA}; `metadata.gate_blockers[]` = DR `blockers[]` / QA `blocking_defects[]` strings. | Read both fields; fix those exact findings *first*; do not re-scope. |
| SubagentStop hook → next dispatch | A blocked gate emits `hookSpecificOutput.additionalContext` telling the next run what to fix. | Treat as additional remediation context. |

On a rework dispatch the DV/code-fixer agent MUST:

1. Read `metadata.gate_from_stage` + `metadata.gate_blockers[]` (and any `REMEDIATION`
   block in the prompt).
2. Address each listed blocker individually; record per-blocker resolution in
   `.context/errors/<agent-basename>.md`.
3. Keep the diff minimal — change only what the blockers require.

## Qualified Agent Names

All Task delegations MUST use the fully-qualified `plugin:agent` form:

| Form | Status |
|------|--------|
| `android-developer:android-phone-developer` | Required |
| `igrsoft:technical-lead` | Required |
| `android-phone-developer` (bare) | Deprecated — back-compat shim prepends `igrsoft:` and logs a warning (would resolve to the wrong plugin) |

Task metadata carries qualified names:

```json
{
  "metadata": {
    "agent": "android-developer:android-phone-developer",
    "model": "sonnet",
    "error_file": ".context/errors/android-phone-developer.md",
    "requires_screenshots": false,
    "plan_file": "planning-0.md",
    "run_index": 0
  }
}
```

## Token Budgets

- **Incoming compressed context** (from igrsoft): 300-500 tokens (planning 300,
  architecture 300, development handoff 500).
- **Full stage output**: write to `.context/<stage>-N.md` (no token cap).
- **Outgoing return summary**: 500 tokens max (for the orchestrator).
- **Inter-stage handoffs**: DV→DR 300, DR→QA 300.

## Detecting Workflow Context

1. **Context folder**: `.context/` in the project root, or
   `.worktrees/milestone-{N}/{issue#}/.context/` in worktree mode (resolve via
   `task.metadata.workspace_path` + `metadata.isolation`).
2. **Plan file**: (1) `task.metadata.plan_file`; (2) newest `.context/planning-*.md`.
3. **State ledger**: read `.context/state.json` for upstream `facts`/`handoffs`/`stages`.
4. **Architecture document**: newest `.context/analyzing-*.md` — or the anchors named in
   upstream `next_stage_focus`.
5. **Task System**: TaskList/TaskGet; inspect `task.metadata.{plan_file, agent, model,
   run_index, error_file, gate_from_stage, gate_blockers, requires_screenshots,
   workspace_path}`.

## Dynamic Worktask Sizing (v3.36.0)

PL0 assesses complexity (0-50) and creates only the stages needed:

| Score | Complexity | PL0 Creates |
|-------|------------|-------------|
| 0-10 | Low | DV0, DR0, QA0 |
| 11-20 | Medium | AR0, DV0, DR0, QA0 |
| 21-30 | Moderate | AR0, TL0, DV0, DR0, QA0 |
| 31-40 | High | AR0, TL0, DV0, DR0, QA0, DC0, FN0, ST0 |
| 41-50 | Critical | AR0, TL0, DV0, DR0, SR0, QA0, DC0, RE0, FN0, ST0 |

Security-sensitive features (authentication, payments, PII, cryptography, secrets,
exported components, deep links) auto-include SR0 regardless of score.

PL0 stamps `metadata.skipped_stages = [{stage, reason}]` for every stage dropped from the
full 9-stage pipeline (PL→AR→TL→DV→DR→QA→DC→FN→ST), so `state.json` self-documents the
drops. It also stamps `metadata.test_mode` (`build-only` / `scoped` / `full` — defaulted by
score and marker coverage) and `metadata.ui_visual_check`. The plugin norm keeps
`requires_screenshots: false` for systems-style Android work, so `ui_visual_check` is
normally `false`; but when a dispatcher arms `ui_visual_check: true` for UI-critical work,
the provenance rule in § Screenshot Gate for Android Work applies. The stage table above,
the `test_mode` defaults, and these stamps are all defined by igrsoft
`estimation-methodology § PL0 Stage-Set` (the source of truth) — keep them in lockstep with
it so the next sync is a mechanical copy.

## MCP Dynamic Inheritance

Subagents inherit the parent session's MCP tools (Context7, Ref, etc.). Do not redeclare
MCP tools in agent frontmatter when the parent session already provides them —
redeclaration creates duplicates and bloats permission prompts.

## When Not in Workflow

If no workflow context is detected (no `.context/`, no task metadata), proceed with
standard implementation: follow the Android skills, run the same build/test/lint
discipline, and report results directly — no artifacts or frontmatter required.

## Related Skills (igrsoft plugin)

| Skill | Purpose |
|-------|---------|
| `igrsoft:worktask` | Complete worktask system documentation |
| `igrsoft:cross-plugin-handoff` | Handoff protocol between plugins |
| `igrsoft:agent-coordination` | Multi-agent coordination patterns |
| `igrsoft:context-compression` | Token budgets and compression techniques |
| `igrsoft:security-review-process` | SR stage OWASP/MASVS checklists |
| `igrsoft:release-engineering` | RE stage versioning patterns |

## Related Skills (android-developer plugin)

| Skill | Purpose |
|-------|---------|
| `_shared/model-selection.md` | Per-agent model/effort assignments and override paths |
| `_shared/severity-matrix.md` | P0-P3 finding priorities for DR/SR outputs |
| `_shared/testing-principles.md` | Test pyramid, framework matrix, QA coverage expectations |

## Attribution

Original IGRSoft synthesis (MIT), adapted from the system-developer plugin's
workflow-integration guide (MIT) with Android substitutions. Encodes the igrsoft
v3.36.0 handoff protocol.
