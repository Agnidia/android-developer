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

### Stages owned by android-developer

android-developer owns these stages when dispatched:

| Stage | android-developer agent | Handoff data |
|---|---|---|
| AR (Architecture) | `kotlin-architector` | planning context + platform constraints — **consultation only**, corpflow retains the stage |
| DV (Development) | `android-developer`, `android-phone-developer` | planning + architecture context |
| DR (Developer Review) | `and-code-fixer` | `metadata.gate_blockers[]` + minimal-diff remediation |
| SR (Security) | `and-security-auditor` | development context + Android security checklist |
| QA (Quality) | `and-test-generator` | development context + test requirements |
| RE (Release) | `and-release-engineer` | Play Console listing, graphic assets, track and rollout — **consultation only**, corpflow retains the stage |
| DV-support | `and-dependency-manager` | scoped findings returned to the parent DV agent, which owns the artifact |

**DV-support agents do not own a stage.** They return a compressed summary to the parent DV agent and
do **not** patch `state.json`.

**RE is consultation, exactly like AR.** `and-release-engineer` returns store-submission findings
and artifacts; corpflow's own release engineer keeps the stage and every `state.json` write. The
same agent is also reachable **outside** the pipeline: corpflow's `/appstore` command dispatches it
directly for Play listing and graphic-asset work with no worktask in play. In that mode it still
emits handoff frontmatter — it is the artifact contract, not a pipeline-only formality — and it
still does **not** patch `state.json`.

**In-app purchases are out of scope for now.** Play Billing product setup is not ported; the Play
Console flows differ field by field from App Store Connect's and are original work, not a
translation. A request for it should say so rather than improvising against a live console.

## Evidence declaration

| Field | Value |
|---|---|
| `requires_screenshots` default | `true` |
| Build Evidence adapter | `android_adapter (adb exec-out screencap -p)` |
| Error file | `.context/errors/android-phone-developer.md` (basename of the agent file, not the qualified id) |

Build Evidence is `adb exec-out screencap -p` captures plus Gradle build and test transcripts. There is no Android build MCP; builds and tests go through `/android-developer:build-test` (see Build and test below). Scoped `Bash(adb:*)` is still yours for evidence capture and device queries. Security findings cover EncryptedSharedPreferences/Keystore, no-cleartext, exported-component validation, and hardcoded secrets.

## Build and test (BINDING)

Build and test **only** through `/android-developer:build-test`. Do not invoke the toolchain
directly — corpflow's `agents/developer.md` requires the command, and a raw invocation
bypasses the logging, evidence capture, and stage-authority checks the pipeline depends on.

**If you only need to compile, pass `--no-test`.** Every platform `build-test` command
accepts it and corpflow's test-execution gate classifies it `build_only` and allows it at
every stage. This matters because most stages do **not** hold test-execution authority: DV
may run scoped tests only, QA is the sole full-suite authority, and SR/DR/RE hold none. A
denied invocation is not a reason to reach for the toolchain.

- `--build-only` is **not** a real flag on any plugin's command. It classifies as a full
  test run and is denied.
- If the gate denies you and `--no-test` does not fit, record
  `requests_test_evidence: <what and why>` in your artifact so QA executes it, or return
  `verdict: blocked` with `error_escalated_to:`. Both are correct outcomes; a direct
  toolchain call is not.

## Worktree isolation (DV)

When corpflow dispatches you for DV, you run in an **isolated git worktree**, not the shared
checkout. `task.metadata.workspace_path` is the tree you were assigned.

1. Confirm the tree you resolved is the tree you were assigned before writing anything —
   `git rev-parse --show-toplevel` against `metadata.workspace_path`.
2. **On mismatch, stop and report** `verdict: blocked` with the two paths. Do not "fix" it by
   entering a different worktree, creating one, or writing anyway. A mismatch means another
   stream's tree, and a write there lands your diff on their branch.
3. Do not create or move worktrees. corpflow creates every stage worktree before dispatch.
4. Re-confirm the pin immediately before each write batch, not only at entry — the check is a
   point-in-time reading and a stage that passes at entry can be relocated mid-run.

Writes outside `metadata.workspace_path` are never yours, including a sibling stream's source
tree. If you need a change in another stream's scope, report it; do not make it.

When you capture screenshots, append them to the run's `screenshots.md` manifest and treat that
file as the record of authority. Do **not** read or write `state.json facts.screenshots` — it is
capped and merged last-writer-wins, so in a multi-stream run it reflects one stream and silently
drops the rest. Never invent a sibling key to work around it; append to the manifest.

## Artifacts

Write to `.context/` for artifacts. In a DV stage you also own your platform's source tree —
the paths corpflow assigned you, inside your worktree — and nothing else in the repository.

| Stage | Artifact |
|---|---|
| AR | `.context/android-architecture.md` (consultation output, ≤500-token return summary) |
| RE | `.context/android-release-<N>.md` (consultation output; Play Console changes listed explicitly) |
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
| RE | `store_changes[]` (every live Play Console write, or `[]`), `manual_steps[]`, `version_name`, `version_code`, `track` |

A blocked stage still emits frontmatter — `status: "blocked"` with `error_escalated_to:` naming the
stage that must resolve it.

## Patching state.json

Run corpflow's `state-patch.sh --stage <CODE> --prev <PREV>` when its path is supplied, via the
prompt or `task.metadata.state_patch_script`. It merges `tasks.<ID>` and `handoffs[FROM→TO]` from
your frontmatter.

- If the path is **not** supplied, skip silently. Do not hand-roll a `jq` merge.
- If the patch **fails**, proceed anyway and return normally. corpflow's `SubagentStop` hook
  reconstructs the merge from your frontmatter — that is what the unconditional emission buys.
- Never write `state.json` directly. It is orchestrator-owned.

## Return summary (≤500 tokens)

corpflow merges your return text into the next stage's context, so it is a budget, not a suggestion.

**Returning is what settles your stage.** The orchestrator's completion patch keys on your return;
reporting progress out of band — a chat message, a teammate note — does not mark you complete, and
a stage that finishes its work but never returns sits at `in_progress` with its artifact already on
disk. Always return, even when blocked, even when partial: a short honest summary with
`verdict: blocked` settles the stage; silence does not.


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

### DV
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

### AR (consultation)
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

### DV-support

No `state.json` patch, parent DV agent owns the artifact:
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

### IR (emergency)
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

## Orchestrator agent roles

Some of this plugin's own commands run a multi-stage flow that borrows orchestrator agents — an
architect for a design pass, a reviewer for a DR gate. Those commands name the **role**, not the id,
so this table stays the only place an id appears. Resolve a role here before dispatching; if this
file is absent, the plugin is standalone and those phases are skipped rather than failed.

### Role table

| Role named in a command | Agent id |
|---|---|
| the orchestrator's product manager | `corpflow:product-manager` |
| the orchestrator's architect | `corpflow:software-architector` |
| the orchestrator's DR reviewer | `corpflow:technical-lead` |
| the orchestrator's QA engineer | `corpflow:qa-engineer` |
| the orchestrator's technical writer | `corpflow:technical-writer` |
| the orchestrator's security reviewer | `corpflow:security-reviewer` |
| the orchestrator's ethics reviewer | `corpflow:ethics-reviewer` |
| the orchestrator's project manager | `corpflow:project-manager` |
| the orchestrator's worktask engineer | `corpflow:workflow-engineer` |
| the orchestrator's platform router | `corpflow:developer` |
| the orchestrator's meta-prompt engineer | `corpflow:prompt-engineer` |

### Standards are referenced by id

Shared **standards** are referenced by id directly (`corpflow:code-comment-standard`,
`corpflow:security-review-process`, `corpflow:claude-constitution`,
`corpflow:logging-conventions`). They are shared vocabulary rather than orchestration: copying them
into each plugin would let the wording drift, and a drifting standard is worse than a named one.

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
| Targets corpflow | `4.0.26` |
| Contract source | `corpflow skills/cross-plugin-handoff/references/plugin-contract.md` |
| Template | `corpflow skills/cross-plugin-handoff/templates/CORPFLOW.md` |
