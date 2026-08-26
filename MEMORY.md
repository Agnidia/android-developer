# android-developer Plugin Memory

## Version Tracking

| Field | Value |
|-------|-------|
| Plugin version | 1.5.0 |
| corpflow compatibility | v4.0.26 |
| Claude Code min required | 2.1.169 |
| Last updated | 2026-08-26 |

Version strings move together (plugin.json, marketplace.json metadata, README
header, this table, CHANGELOG.md) per the corpflow `/cc-update` convention.

## Inventory Index

| Category | Count | Quick Summary |
|----------|-------|---------------|
| **Agents** | 7 | android-developer (router), android-phone-developer, kotlin-architector, and-test-generator, and-security-auditor, and-code-fixer, and-dependency-manager |
| **Commands** | 15 | analyze-accessibility, analyze-tech-debt, arch-review, arch-select, build-test, debug, deps, develop-feature, fix-modernize, fix-performance, fix-quick, fix-refactor, gen-docs, gen-tests, review-code |
| **Skills** | 23 SKILL.md | 1 top + 1 workflow-integration + 6 domain routers + 15 leaves (architecture/4, compose-ui/5, data/3, concurrency-networking/1, quality/1, tooling/1) |
| **Skill domains** | 6 | architecture, compose-ui, data, concurrency-networking, quality, tooling |
| **Hooks** | 3 | audit-tooluse.sh (PostToolUse), audit-subagent.sh (SubagentStop), precompact-checkpoint.sh (PreCompact) |

## CC Features Adopted at 1.0.0

Born on the corpflow v3.17.0 / CC 2.1.169 baseline (current compatibility: corpflow
v4.0.0), the plugin adopts the current capability set from the start:

- **Tiered `maxTurns`** — every agent declares a runaway-loop backstop sized to
  its role: haiku/low 30 (`and-dependency-manager`), haiku/medium 30 (`and-code-fixer`),
  sonnet/medium 40 (`android-developer` router), sonnet/high 50
  (`android-phone-developer`, `and-test-generator`, `and-security-auditor`), opus/xhigh 50
  (`kotlin-architector`).
- **`disallowed-tools: Write, Edit`** — declared on the review-only agent
  (`and-security-auditor`) as defense-in-depth on top of its already Write/Edit-free
  `tools:` allow-list. Fixes route to `and-code-fixer`.
- **Fully-qualified `Task(plugin:agent)` references** — all delegations use the
  `Task(android-developer:<agent>)` / `subagent_type="android-developer:<agent>"`
  form; no bare agent names anywhere. Cross-plugin targets keep their own prefix
  (`corpflow:*`, etc.).
- **Scoped `Bash(cmd:*)` allowlists** — each agent's `tools:` enumerates only the
  toolchain binaries it needs (for example `android-phone-developer`: git, gradle,
  ./gradlew, adb, ktlint, detekt). Because scoped patterns do not match compound
  commands, agents issue single-command invocations (`./gradlew :app:assembleDebug`,
  `adb install -r app.apk`) rather than `cd`-chains.
- **Plugin-scoped advisory hooks** — `hooks/{audit-tooluse,audit-subagent,
  precompact-checkpoint}.sh`, wired in `plugin.json` (PostToolUse / SubagentStop /
  PreCompact). All rows are advisory (`actor: "android-developer:hook:*"`,
  `metadata.advisory: true`) and share corpflow's `dedupe_key` / `dedupe_key_extended`
  shape so corpflow's `audit-dedup.sh` keeps the orchestrator row authoritative when
  android-developer runs nested. Each script has `--self-test`.

## Not Adopted (corpflow-owned infrastructure)

android-developer agents are invoked specialists; corpflow owns orchestration. The
following stay orchestrator-owned and are deliberately **not** implemented here:

- **`audit-dedup.sh`** — corpflow-owned. android-developer emits advisory rows with
  matching dedupe keys for corpflow's helper to reconcile; it does not reconcile
  them itself.
- **`state-merge.sh` / SubagentStop `state.json` merge** — orchestrator-owned. The
  hooks here read and checkpoint state but never merge it. Frontmatter emission is
  unconditional (it is the input corpflow's merge layer consumes).
- **Screenshot-gate ownership** — corpflow owns the evidence gate. android-developer
  work defaults to `requires_screenshots: false` and, when a gate demands proof,
  supplies `cli-fallback` terminal transcripts (`./gradlew` build/test output,
  ktlint/detekt reports, `adb logcat`). It does not own or override the gate itself.

## Decisions Log

- **2026-06-23: Added M3 Expressive design-craft skill** — New leaf skill
  `compose-ui/material3-expressive` (+1 SKILL.md + 3 references) captures design-craft
  tactics (shape variety, rich color, typographic emphasis, strategic containment, fluid
  motion, component flexibility), hero-moment composition, spring-motion mechanics, shape
  morphing, the 48-role color system, component replacements, accessibility contracts,
  and the "AI slop" anti-pattern checklist. Complementary to the existing `material3` skill
  (theming/API-setup focus). Includes 8 additive cross-link/agent/command edits (skills
  routers, accessibility, testing, agent, and the commands then named `code-review` /
  `modernize`, now `review-code` / `fix-modernize`). Version bump
  to 1.1.0 (minor version for new skill).
- **Base + workflow-integration mirror system-developer, not apple-developer** —
  system-developer is the exact structural analog for a Bash-only, no-build-MCP,
  `requires_screenshots: false` + cli-fallback plugin. apple-developer was consulted
  only for the verbatim hook scripts (slug renamed to `android-developer`) and the
  richer `workflow-integration/templates/` set, scrubbed of all foreign-platform
  toolchain references so the workflow contract stays Android-clean at the source.
- **7-agent MVP roster** — router + `android-phone-developer` + `kotlin-architector`
  + four utility agents. Phone/tablet is ~95% of Android demand; form-factor
  specialists (wearos/tv/auto) and `performance-engineer` are deferred to a Full
  release as additive, low-risk follow-ups.
- **`kotlin-architector` is opus/xhigh, color green** — architecture pattern
  reasoning (Clean Arch, modularization, Hilt graph, MVI vs MVVM) needs the top tier;
  green per the roster lock.
- **Review-only `and-security-auditor`** — carries `disallowed-tools: Write, Edit` and
  routes all remediation to `and-code-fixer`. Keeps the review/fix separation explicit
  and auditable.
- **2026-07-29: Verb-first command names (supersedes the plain-names decision)** —
  commands adopt the cross-plugin scheme shared with apple-developer and
  system-developer: `review-*`, `fix-*`, `gen-*`, `arch-*`, `analyze-*`. The
  earlier decision ("plain command names, no verb-prefix scheme") is reversed:
  it predated the sibling plugins converging, and divergent names across plugins
  cost more in recall than the flat names saved. `fix-quick` keeps `model: haiku`
  (deterministic linter run); `deps` lost it (catalog parsing + CVE triage +
  upgrade routing is a 20-30% haiku workload, matching its peers).
- **2026-07-29: `analyze-accessibility` is adapted from frontend-developer, not
  apple-developer** — WCAG semantics for a declarative UI tree with a screen
  reader is the closer analog than Apple's VoiceOver/UIKit surface. Compose
  semantics, `mergeDescendants`, and `traversalIndex` have no apple-developer
  counterpart worth transliterating.
- **2026-07-29: `fix-performance` routes to `kotlin-architector` + `and-code-fixer`** —
  this plugin has no `performance-engineer` agent (deferred at the 7-agent MVP,
  see below). Rather than borrow another plugin's agent, which understands
  neither Gradle variants nor recomposition, analysis goes to the architect that
  already owns the module graph and state boundaries. The routing rationale is
  stated in the command file itself so the next reader does not re-litigate it.
- **No build MCP, scoped Bash instead** — no Android build-MCP server exists;
  build/test/lint flow through scoped `Bash(gradle:*)`, `Bash(./gradlew:*)`,
  `Bash(adb:*)`, `Bash(ktlint:*)`, `Bash(detekt:*)`, `Bash(git:*)`. No agent carries
  bare `Bash`.
- **Synthesize-never-copy + per-skill attribution** — all skill prose is rewritten
  in IGRSoft voice; each `SKILL.md` ends with an `## Attribution` section naming its
  source repos. Google `android/skills`-derived skills (`quality/testing`,
  `tooling/gradle-build`) are `license: Apache-2.0`; community-synthesized skills are
  `license: MIT`.

## Source Attribution (skill synthesis)

Skill content is synthesized — not copied — from these community references plus
Google's official `android/skills`. Per-skill `## Attribution` sections name the
specific sources:

- `new-silvermoon` — architecture, compose, concurrency, quality, tooling notes.
- `piyushverma0` — architecture, data, concurrency notes.
- `ayush016` — design-system / compose notes.
- Google `android/skills` (Apache License 2.0) — testing and gradle-build blends.

## Version History

Full release notes live in `CHANGELOG.md` (Keep a Changelog format) as of 1.3.0.
This section keeps the long-form rationale for the entries.

**Agent names are plugin-unique by rule** (since 1.4.0): every functional-role agent
carries the `and-` prefix. A bare name that another dev plugin also ships gets silently
overwritten at install and collides on `error_file`. Do not add an agent without it.

### 1.4.0 — 2026-07-29 Agent Rename + Platform-Leak Audit

The four utility agents took the `and-` prefix (`and-code-fixer`, `and-security-auditor`,
`and-test-generator`, `and-dependency-manager`), adopting the `sys-`/`fe-`/`be-`/`ai-`
convention every other dev plugin already follows. This closes the migration corpflow's
`compatible-plugins.md` § Naming had tracked as owned by this plugin. Two failure modes
motivated it, and only the first is obvious: Claude Code keys agents by frontmatter `name`,
so android's and apple's identically-named agents overwrote each other on install; and
`error_file` derives from the agent basename, so a worktask touching both plugins had two
different agents appending to one `.context/errors/test-generator.md`. BREAKING for any
caller dispatching the old bare names — see the README migration table.

The audit pass targeted one defect class: a rule true for one stack, written as universal.
The load-bearing finds were `analyze-accessibility` (Compose-only checks under an "Android
UI" claim, so View/XML modules got a false-clean report), `--device SERIAL` advertised in
three commands but never reaching an `adb -s`, and `platform-agent.md` naming only
`build.gradle.kts` while `fix-modernize --target kotlin-dsl` exists to convert Groovy
projects. Where the plugin genuinely does not support a variant (View/XML a11y, Koin DI),
the fix narrowed the claim rather than inventing coverage — an unimplemented promise costs
more than an acknowledged gap.

### 1.3.0 — 2026-07-29 Command Unification

Command surface unified with apple-developer / system-developer: six renames to the
verb-first scheme, eight new commands (7 → 15), and one frontmatter standard across all of
them. See the migration table in `README.md` and the full entry in `CHANGELOG.md`.

`deps` became a subcommand dispatcher (`audit` default | `upgrade`), replacing `--fix`, so a
bare `/deps` is read-only. Frontmatter gained `estimated-cost` on the six commands that
lacked it, seeded from apple/system counterparts. Descriptions were cut to ≤120 chars —
including three pre-existing overruns the ≤250 `desc-lint` brake had not caught
(`fix-modernize` at 233, `fix-refactor` and `review-code` at 136).

New: `scripts/check-command-registration.sh`, ported from apple-developer's
`tools/` (it resolves paths via `dirname/..`, so it works unchanged from `scripts/`).
It asserts a bijection between `commands/*.md` and `marketplace.json`'s `commands[]` —
a drift that otherwise fails silently at runtime — and runs as a fatal check in
`scripts/run-checks.sh`.

The `performance-engineer` gap deferred at the 7-agent MVP is now visible in a command:
`fix-performance` routes to `kotlin-architector` + `and-code-fixer` and says so in the file.
If a `performance-engineer` agent ever lands, that command is where it plugs in.

### 1.2.0 — 2026-07-22 corpflow v3.36.0 Port

Compatibility ported v3.17.0 → v3.36.0 (~14 refs across README, this file, the agent
stage-participation headers, and the `workflow-integration` skill). The Dynamic Worktask Sizing
table was already current (DR0 at every tier); the PL0 stamp note now also names
`metadata.test_mode` and `metadata.ui_visual_check` — with the Android nuance that the plugin
keeps `requires_screenshots: false` for systems-style work, so `ui_visual_check` is normally
`false` and its provenance rule applies only when a dispatcher arms it. The v3.17.0 / CC 2.1.169
birth record is preserved, and the pre-existing `_base` manifest-column drift (`Adapter` /
`cli_fallback` → `source` / `cli-fallback`) is fixed.

Screenshot-gate hardening (the design decision is respected, not flipped): an
**evidence-freshness rule** — every `cli-fallback` transcript or `adb shell screencap` row is
produced this run from the actual invocation, never reused; corpflow QA direct-reads the files and
cross-checks the `### build-evidence` log paths, re-opening DV on a stale/duplicated one — plus a
**conditional armed-gate provenance rule**: when a dispatcher arms `ui_visual_check: true` for
UI-critical work, static renders (Roborazzi/Paparazzi, un-interacted screens) do not satisfy it;
reach each substate on a device/emulator through real interactions, confirm controls displayed and
enabled, then `screencap`. `requires_screenshots: false` remains the norm.

Also ported: the **state-patch pointer form** (the manual `read → merge → temp → fsync → rename`
prose replaced by the two-mode `state-patch.sh --stage <CODE> --prev <PREV>` contract — run when
supplied, else silently skip; Layers 2/3 repair from the unconditional `handoff:` frontmatter);
benchmark-driven **Output Budgets** on DV (`_base`, with the three Build-Evidence lines exempt),
AR-consult, DV-support, and DR-support agents, plus a **Complexity Triage** gate on
`kotlin-architector` adapted to its consultation shape (compact vs full consultation, no mode
ladder); and the **Displayed-Enabled Control Sweep** test pattern (`assertIsDisplayed()` +
`assertIsEnabled()` per substate, transition round-trips, 48dp touch-target cross-ref).
Repo-structure linters added: `section-lint.sh` (≤1000-char section cap, warn-only — baseline 39
sections over cap across 85 files, burn-down tracked separately) and `desc-lint.sh` (three-tier
frontmatter `description` brake: agents 500 / commands 250 / skills 500, the last covering the root
skills index). Two pre-existing manifest bugs fixed: the stale `marketplace.json metadata.version`
(1.0.0 → 1.2.0) and the unregistered `compose-ui/material3-expressive` skill (added to
`plugins[0].skills[]`).

Follow-ups: the agent-description diet toward the ≤250 sibling-plugin ideal is eval-gated — all
seven agents exceed 250 (worst 465, `and-security-auditor`; brake 500) — pending evidence that shorter
descriptions still route reliably. There is no CI in this repo yet, so the linters run manually via
`scripts/run-checks.sh` until a workflow lands.
