# corpflow Integration — android-developer

This is the **only** file in android-developer that knows corpflow exists. Delete it and the plugin is
standalone with no other edit; restore it and the plugin participates in worktasks again. Nothing in
`agents/`, `commands/`, `skills/`, or `hooks/` references corpflow, and nothing should be added that
does — see § Keeping the seam single.

corpflow injects `Read CORPFLOW.md and follow it` into every delegation prompt, so agents reach this
file without carrying a preamble of their own.

## Are we in a worktask?

`.context/state.json` exists → yes. Otherwise every rule below is inert and android-developer behaves exactly
as it does with corpflow uninstalled.

Read `.context/state.json` first. It carries the current stage, `run_index`, the plan file path, and
`metadata.*` for the dispatched task.

## Pipeline

Eleven stages, PL→AR→TL→DV→DR→SR→QA→DC→RE→FN→ST. PL0 sizes the run and may drop AR, TL, and DC for
small tasks, so **never assume a stage ran** — read `state.json` rather than inferring. The emergency
pipeline is six stages (IR→DV→QA→DC→FN→ST) and skips both approval gates.

android-developer owns these stages when dispatched:

| Stage | android-developer agent | Handoff data |
|---|---|---|
| AR (Architecture) | `kotlin-architector` | planning context + platform constraints — **consultation only**, corpflow retains the stage |
| DV (Development) | `android-developer`, `android-phone-developer` | planning + architecture context |
| DR (Developer Review) | `and-code-fixer` | `metadata.gate_blockers[]` + minimal-diff remediation |
| SR (Security) | `and-security-auditor` | development context + Android security checklist |
| QA (Quality) | `and-test-generator` | development context + test requirements |
| DV-support | `and-dependency-manager` | scoped findings returned to the parent DV agent, which owns the artifact |

**DV-support agents do not own a stage.** They return a compressed summary to the parent DV agent and
do **not** patch `state.json`.

## Evidence declaration

| Field | Value |
|---|---|
| `requires_screenshots` default | `true` |
| Build Evidence adapter | `android_adapter (adb exec-out screencap -p)` |
| Error file | `.context/errors/android-phone-developer.md` (basename of the agent file, not the qualified id) |

Build Evidence is `adb exec-out screencap -p` captures plus Gradle build and test transcripts. There is no Android build MCP — use scoped `Bash(gradle:*|./gradlew|adb:*)`. Security findings cover EncryptedSharedPreferences/Keystore, no-cleartext, exported-component validation, and hardcoded secrets.

## Artifacts

Write to `.context/`. Nothing else in the repository is yours to create.

| Stage | Artifact |
|---|---|
| AR | `.context/android-architecture.md` (consultation output, ≤500-token return summary) |
| DV | `.context/development-<N>.md` |
| DR | `.context/developer-review-<N>.md` |
| SR | `.context/security-review-<N>.md` |
| QA | `.context/qa-<N>.md` |
| IR | `.context/incident-report.md` |

`<N>` is `run_index` from `state.json`. The basenames are canonical; only the suffix changes per run.
Filenames are a backward-compat convenience for corpflow's `SubagentStop` hook — **the frontmatter
below is the actual contract**, and an artifact without it breaks the three-layer recovery net
(agent → orchestrator fallback → hook) regardless of what it is called.

## Handoff frontmatter (BINDING)

Emit this on every stage artifact, **unconditionally**, even on failure:

```yaml
---
handoff:
  from: "android-developer:<agent>"
  to: "corpflow:<next-stage-agent>"
  stage: "<STAGE-CODE>"
  run_index: <N>
  status: "completed" | "blocked" | "partial"
  verdict: "pass" | "fail" | "needs_changes"
  artifacts: [".context/<artifact>.md"]
  metadata:
    <per-stage required fields — see the matrix below>
---
```

Per-stage required `metadata.*`:

| Stage | Required metadata |
|---|---|
| AR | `patterns_selected[]`, `constraints[]` |
| DV | `files_changed[]`, `tests_run`, `build_status`, `requires_screenshots`, `ui_visual_check` |
| DR | `gate_blockers[]`, `severity_counts{}` |
| SR | `findings[]` with CWE mapping, `severity_counts{}` |
| QA | `tests_added[]`, `coverage_delta`, `suite_status` |

A blocked stage still emits frontmatter — `status: "blocked"` with `error_escalated_to:` naming the
stage that must resolve it.

## Patching state.json

Run corpflow's `state-patch.sh --stage <CODE> --prev <PREV>` when its path is supplied, via the
prompt or `task.metadata.state_patch_script`. It merges `stages.<CODE>` and `handoffs[FROM→TO]` from
your frontmatter.

- If the path is **not** supplied, skip silently. Do not hand-roll a `jq` merge.
- If the patch **fails**, proceed anyway and return normally. corpflow's `SubagentStop` hook
  reconstructs the merge from your frontmatter — that is what the unconditional emission buys.
- Never write `state.json` directly. It is orchestrator-owned.

## Return summary (≤500 tokens)

corpflow merges your return text into the next stage's context, so it is a budget, not a suggestion.

```markdown
## <STAGE> Summary — android-developer:<agent>
**Verdict**: pass | fail | needs_changes
**Artifact**: .context/<file>.md
**Changed**: <n> files — <the 3–5 that matter>
**Evidence**: <build/test/screenshot status>
**Blockers**: <none | what blocks and which stage must resolve it>
**For next stage**: <what the next stage needs that is not obvious from the artifact>
```

Compress by dropping P2/P3 detail and referencing the artifact path. Never truncate mid-structure —
a half-written table costs the next stage more than an omitted section.

## Gate feedback on re-dispatch

When corpflow re-dispatches you after a DR or QA rejection, `metadata.gate_blockers[]` carries the
findings. Address every entry or explain in the artifact why one is not actionable. Do not
re-litigate the gate's judgement; a disputed blocker is escalated via `error_escalated_to:`, not
ignored.

## Frontmatter templates

Copy the block for the active stage.

**DV**
```yaml
handoff:
  from: "android-developer:android-phone-developer"
  to: "corpflow:technical-lead"
  stage: "DV"
  run_index: <N>
  status: "completed"
  verdict: "pass"
  artifacts: [".context/development-<N>.md"]
  metadata:
    files_changed: []
    tests_run: ""
    build_status: "pass"
    requires_screenshots: true
    ui_visual_check: true
```

**AR (consultation)**
```yaml
handoff:
  from: "android-developer:kotlin-architector"
  to: "corpflow:software-architector"
  stage: "AR"
  run_index: <N>
  status: "completed"
  verdict: "pass"
  artifacts: [".context/android-architecture.md"]
  metadata:
    patterns_selected: []
    constraints: []
```

**DV-support** — no `state.json` patch, parent DV agent owns the artifact:
```yaml
handoff:
  from: "android-developer:<support-agent>"
  to: "android-developer:android-phone-developer"
  stage: "DV"
  run_index: <N>
  status: "completed"
  verdict: "pass"
  artifacts: []
  metadata:
    support_role: "<performance|dependencies|accessibility>"
    findings: []
```

**IR (emergency)**
```yaml
handoff:
  from: "android-developer:<agent>"
  to: "corpflow:incident-responder"
  stage: "IR"
  run_index: <N>
  status: "completed"
  verdict: "pass"
  artifacts: [".context/incident-report.md"]
  metadata:
    root_cause: ""
    hotfix_constraints: []
```

## Keeping the seam single

When a corpflow contract changes, this file changes and nothing else in android-developer does. That property
only holds if it is defended:

- Do not add a corpflow reference to an agent, command, skill, or hook. If an agent needs a rule,
  the rule belongs here and corpflow's dispatch injection delivers it.
- Do not split this file into a directory of references. One file is the contract.
- Hooks that describe orchestrator interop say "the orchestrator" generically. They work under
  corpflow or standalone, and naming corpflow in a comment re-couples a file that had no reason to
  be coupled.
- android-developer's own version does not track corpflow's. Record the targeted corpflow version below and
  bump it when the contract changes.

| | |
|---|---|
| Targets corpflow | `4.0.13` |
| Contract source | `corpflow skills/cross-plugin-handoff/references/plugin-contract.md` |
| Template | `corpflow skills/cross-plugin-handoff/templates/CORPFLOW.md` |
