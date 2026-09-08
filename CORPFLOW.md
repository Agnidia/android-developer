<!--
The single corpflow-facing file in this plugin. Keep it self-contained — splitting it into a
references/ directory rebuilds the coupling it replaced. Never add a `## Routing` heading: that one
is reserved for a CORPFLOW.md sitting at a *user project* root.
Contract: corpflow skills/cross-plugin-handoff/references/plugin-contract.md
-->

# corpflow Integration — android-developer

The only file in android-developer that knows corpflow exists — delete it and the plugin is
standalone. Nothing in `agents/`, `commands/`, `skills/`, or `hooks/` may reference corpflow;
dispatch injects `Read CORPFLOW.md and follow it` into every delegation prompt.

## Are we in a worktask?

`.context/state.json` exists → yes, otherwise every rule below is inert. Read it first: current
stage, `run_index`, plan file path, and `metadata.*` for the dispatched task.

## Pipeline

Default run is **nine** stages — `PL→AR→TL→DV→DR→QA→DC→FN→ST`; `--secure` adds **SR** and **RE**;
emergency is `IR→DV→DR→QA→RE→FN` and skips both gates. PL0 may drop AR, TL, or DC, so never assume a
stage ran — read `state.json`.

### Stages android-developer works in

| Stage | android-developer agent | Handoff data |
|---|---|---|
| AR (Architecture) | `kotlin-architector` | planning context + platform constraints — **consultation only**, corpflow retains the stage |
| DV (Development) | `android-developer`, `android-phone-developer` | planning + architecture context |
| DR (Developer Review) | `and-code-fixer` | `metadata.gate_blockers[]` + minimal-diff remediation — **consultation only**, corpflow retains the stage and writes the artifact |
| SR (Security) | `and-security-auditor` | development context + Android security checklist — **consultation only**, corpflow retains the stage and writes the artifact |
| QA (Quality) | `and-test-generator` | development context + test requirements — **consultation only**, corpflow retains the stage and writes the artifact |
| RE (Release) | `and-release-engineer` | Play Console listing, graphic assets, track and rollout — **consultation only**, corpflow retains the stage |
| DV-support | `and-dependency-manager` | scoped findings returned to the parent DV agent, which owns the artifact |

**DV is the only stage ownership transfers for.** Read `tasks.DV0.agent`: a `android-developer:` id
means you own `development-N.md`, patch the ledger, and your frontmatter is what the harness
validates; routed via
`corpflow:developer` it owns the artifact and you return implementation plus a ≤500-token summary.
Every other stage is **consultation** — corpflow writes the artifact and every `state.json` entry.
DV-support owns no stage, writes under `.context/logs/`, never patches.

**RE is consultation too.** The orchestrator's release engineer keeps the stage and every
`state.json` write; your release engineer returns store-submission findings and artifacts. The same
agent is reachable outside the pipeline via corpflow's `/appstore`, with no worktask in play — it
still emits handoff frontmatter there, and still does not patch. Report every live store write —
`store_changes[]`, `manual_steps[]`, and the platform's version identifiers — in your return summary
and `--facts`. A store write that reaches no artifact is an unlogged production change.

## Evidence declaration

| Field | Value |
|---|---|
| `requires_screenshots` default | `true` |
| Build Evidence adapter | `android_adapter (adb exec-out screencap -p)` |
| Error file | `.context/errors/android-phone-developer.md` (basename of the agent file, not the qualified id) |

Build Evidence is `adb exec-out screencap -p` captures plus Gradle build and test transcripts. There is no Android build MCP; builds and tests go through `/android-developer:build-test` (see Build and test below). Scoped `Bash(adb:*)` is still yours for evidence capture and device queries. Security findings cover EncryptedSharedPreferences/Keystore, no-cleartext, exported-component validation, and hardcoded secrets.

## Build and test

- Build and test **only** through `/android-developer:build-test`; never invoke the toolchain directly.
- Compile-only: `--no-test`, classified `build_only` and allowed at every stage. `--build-only` is
  not a flag anywhere; it classifies as a full test run and is denied.
- DV runs scoped tests, QA is the sole full-suite authority, SR/DR/RE hold none. Your dispatch brief
  states the resolved test mode and selector; DV's executed set is the tests you touched plus
  `metadata.always_required_tests`.
- Denied and `--no-test` does not fit → record `requests_test_evidence: <what and why>` in your
  artifact, or return `verdict: blocked`. Never reach for the toolchain.
- `/android-developer:build-test` reports a real executed-test count parsed from the Gradle
  JUnit result XML. **0 executed is a failure, not a pass** — a green exit code is not
  evidence that tests ran.
- Forward that count verbatim on the evidence line; never restate it as a bare pass. A
  compile-only run reports `not run (--no-test)`, which is neither a pass nor a failure.

## Worktree isolation (DV)

You run in an isolated git worktree; `task.metadata.workspace_path` is the tree you were assigned.

- Check `git rev-parse --show-toplevel` against it before writing and before each write batch — a
  stage can be relocated mid-run. On mismatch return `verdict: blocked` with both paths; do not
  enter another worktree, create one, or write anyway.
- Never create or move worktrees. Writes outside your tree are never yours — report, do not make.
- Record it as `worktree: true` in the DV frontmatter. Absent or false is a hard DR fail
  (`worktree_isolation_violation`).
- Screenshots append to the run's `screenshots.md` manifest, which is the record of authority.
  Never read or write `state.json facts.screenshots` — it is capped and merged last-writer-wins, so
  in a multi-stream run it keeps one stream and silently drops the rest.

## Artifacts

Write to `.context/`; in DV you also own the source paths corpflow assigned you inside your
worktree, and nothing else. `<N>` is `run_index`. Basenames are a convenience for the
`SubagentStop` hook — the frontmatter is the contract. Errors go to
`.context/errors/<agent-basename>.md`.

| Stage | Artifact |
|---|---|
| AR | `.context/android-architecture.md` (consultation output, ≤500-token return summary) |
| RE | `.context/android-release-<N>.md` (consultation output; Play Console changes listed explicitly) |
| DV | `.context/development-<N>.md` |
| DR | `.context/developer-review-<N>.md` (written by corpflow:technical-lead) |
| SR | `.context/security-review-<N>.md` (written by corpflow:security-reviewer) |
| QA | `.context/testing-<N>.md` (written by corpflow:qa-engineer) |
| IR | `.context/incident-<N>.md` (written by corpflow:incident-responder) |

## Handoff frontmatter (BINDING)

Emit on every stage artifact you write, **unconditionally, even on failure** — without it the
three-layer recovery net has nothing to merge. `handoff-harness.sh --validate-frontmatter` runs at
every stage boundary and fails the stage on a missing required field. Budget ≤200 tokens / ≤30
lines, which is why decisions and questions are stubs pointing at artifact anchors.

### DV — this annotated block is the schema

```yaml
---
handoff:
  stage: DV                    # PL|AR|TL|DV|DR|SR|QA|DC|RE|FN|ST|IR|ET
  verdict: ok                  # ok / blocked / escalate
  summary: "<N files modified, M tests added>"   # ≤200 chars
  worktree: true               # false or absent → DR hard-fails the stage
  worktree_path: <abs path>    # OPTIONAL — the metadata.workspace_path you confirmed
  worktree_branch: <branch>    # OPTIONAL
  files_touched:
    - <path>
  next_stage_focus: "<imperative: what DR/QA must focus on>"
  open_questions:              # REQUIRED — [] when nothing to elicit, never omitted
    - { id: sw-DV0-1, class: decision, ref: "development-N.md#elicitation-sweep" }
  refs:
    decisions: architecture-N.md#decisions    # ONLY when AR ran; omit otherwise
    tests: development-N.md#tests-added
  architecture:                # ONLY when AR ran; omit the whole object otherwise
    ref: architecture-N.md#decisions
    applied: true              # your truthful statement that AR's decisions were followed
---
```

`refs.decisions` and the `architecture` object travel together — one without the other makes DR
report `missing_input`, either without AR trips the inverse guard.

### Other stages — same block, these deltas

| Stage | Delta | Verdict |
|---|---|---|
| AR | `key_decisions` + `open_questions` anchored in `android-architecture.md`; no `files_touched` / `worktree` / `architecture` | ok / blocked / escalate |
| DR / SR | `key_decisions` = findings; no `files_touched` | pass / fail |
| QA | `files_touched` = tests added, `key_decisions` = results | go / no-go |
| IR | `key_decisions` = root cause | ok / escalate |

`key_decisions` items are stubs: `{ id: ad1, summary: "<≤160 chars>", anchor: "<artifact>#decisions" }`.
A `verdict` outside `ok|blocked|escalate|pass|fail|go|no-go|approve|reject` reaches the ledger
unrecognised — the stage reads as neither passed nor failed. `needs_changes` is not a verdict.

AR writes `.context/android-architecture.md` and returns ≤500 tokens for `corpflow:software-architector` to merge.
DR, SR and QA write no artifact. DV-support returns `{support_role, findings}` to its parent.
Blocked → `verdict: blocked` + `error_escalated_to:`, narrative in
`.context/errors/<agent-basename>.md`.

## Closing elicitation sweep (BINDING)

Before handing off, ask what you decided on the user's behalf that the user would rather have
decided. Each surviving question becomes an `open_questions[]` item. **Every stage owes a sweep** —
nothing to ask means `open_questions: []` plus a "nothing to elicit" line under a mandatory
`## elicitation-sweep` H2; omitting it fails the stage. A question some artifact already answers is
yours to resolve, not the user's — cost is not an exemption.

### One item, three transports — none derived from another

| Where | Carries |
|---|---|
| artifact `## elicitation-sweep` H2 | the FULL item. Canonical. Heading present even when the array is empty. |
| `handoff.open_questions[]` | the stub `{{ id, class, ref }}` |
| `state-patch.sh --facts` | the stub plus `stage`, `blocks_next_stage`, `status` |

```markdown
## elicitation-sweep

### sw-DV0-1 — <the question, ≤160 chars>
- **class**: decision            <!-- decision | escalate -->
- **blocks_next_stage**: false   <!-- true only if the next stage would build on a guess -->
- **rationale**: <one line, ≤160 chars>
- **options** (2–4, exactly one recommended):
  - `<label ≤24>` — <detail ≤120>  *(recommended)*
  - `<label ≤24>` — <detail ≤120>
```

- `id` is `sw-<TASK_ID>-<n>` — the ledger unions on `.id`, so an unscoped `q1` overwrites another
  stage's question. Max 4 per stage; more is handing the user your triage.
- `escalate` is never auto-answered, `decision` may be; the orchestrator raises your label, never
  lowers it. `blocks_next_stage: true` costs a round trip at your own boundary, absent/`false`
  batches at the final gate.
- Re-emitting after a rework or retry carries `status` and `resolution` forward.
- You never ask — no plugin agent holds an ask tool; the orchestrator renders every item.
- Not the sweep, each already has a channel: runtime evidence (`requests_test_evidence:`), a skipped
  stage (`requests_stage_escalation:`), your outcome (`handoff.verdict`), a defect (`blocked`).

## Patching state.json

Run `state-patch.sh --stage <CODE> --prev <PREV>` when its path is supplied (prompt or
`task.metadata.state_patch_script`). Path absent → skip silently; never hand-roll a `jq` merge or
write `state.json`. Patch fails → proceed and return; the `SubagentStop` hook rebuilds from your
frontmatter. Exit 3 means your artifact is not on disk — write it and re-run.

Pass `--facts` on the **same** call. Arrays union on identity, so send only your own entries:

```bash
state-patch.sh --stage DV --prev <PREV> --facts '{
  "files_modified": ["<path>"], "tests_added": ["<path>"],
  "decisions": [{"id":"dv-1","summary":"≤160 chars","ref":"development-0.md#decisions"}],
  "open_questions": [{"id":"sw-DV0-1","stage":"DV","class":"decision",
                      "ref":"development-0.md#elicitation-sweep",
                      "blocks_next_stage":false,"status":"open"}]
}'
```

Omit `open_questions` here and the frontmatter stub is orphaned — the harness fails the stage with
`sweep stub <id> is in the frontmatter but not in facts.open_questions[]`.

## What you return

≤500 tokens is a budget — corpflow merges this into the next stage's context. Drop P2/P3 detail and
point at the artifact; never truncate mid-structure.

```markdown
## <STAGE> Summary — android-developer:<agent>
**Verdict**: <this stage's vocabulary>
**Artifact**: .context/<file>.md
**Changed**: <n> files — <the 3–5 that matter>
**Evidence**: <build status>; tests: <N> executed, <M> failed | not run (--no-test); <screenshot status>
**Blockers**: <none | what blocks and which stage resolves it>
**For next stage**: <what is not obvious from the artifact>
**Questions for the user**: <consultation stages only — sweep candidates the owning stage lifts>
```

On re-dispatch after a DR or QA rejection, `metadata.gate_blockers[]` carries the findings — the
review artifact's `## blockers`. **Fix those and nothing else**: address every entry or say in the
artifact why one is not actionable, and dispute via `error_escalated_to:` rather than by ignoring.

## Orchestrator agent roles

This plugin's own multi-stage commands name a **role**, never an id, so this table is the only place
an id appears. Resolve the id, then check your available agent list: **present** → dispatch it;
**absent** → apply the call site's own `Error handling:` line. Never a hard halt.

**Roles with a local equivalent are not dispatched through corpflow at all.** Architect, QA
engineer, and security reviewer resolve to routers that come straight back here, so app-layer work
calls this plugin's own architect, test generator, and security auditor directly. Those aliases are
corpflow's *inbound* routing, resolved at worktask init; these commands run outside any worktask.

**Split by layer, not by role.** The local architect selects this platform's patterns; service
decomposition, storage topology, and API contracts have no local equivalent and go to the
orchestrator's architect. Routing system-level design at the local architect is misrouted.

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

A standard that is absent is simply unavailable — the skill's own guidance stands alone. Never
fork a standard's text into this plugin; a copy drifts silently.

## Keeping the seam single

- Never add a corpflow reference to an agent, command, skill, or hook, and never split this file
  into references. A rule an agent needs belongs here; dispatch injection delivers it.
- Hooks say "the orchestrator" generically, so they work standalone.
- Shared standards are the exception, referenced by id: `corpflow:code-comment-standard`,
  `corpflow:security-review-process`, `corpflow:claude-constitution`, `corpflow:logging-conventions`.
- android-developer's version does not track corpflow's. Bump the target below when the contract changes.

| | |
|---|---|
| Targets corpflow | `4.0.27` |
| Size budget | ≤295 lines (store platform: RE + publishing) |
| Contract source | `corpflow skills/cross-plugin-handoff/references/plugin-contract.md` |
| Template | `corpflow skills/cross-plugin-handoff/templates/CORPFLOW.md` |
