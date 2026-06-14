# android-developer Plugin Memory

## Version Tracking

| Field | Value |
|-------|-------|
| Plugin version | 1.0.0 |
| igrsoft compatibility | v3.17.0 |
| Claude Code min required | 2.1.169 |
| Last updated | 2026-06-14 |

Version strings move together (plugin.json, marketplace.json metadata, README
header, this table) per the igrsoft `/cc-update` convention.

## Inventory Index

| Category | Count | Quick Summary |
|----------|-------|---------------|
| **Agents** | 7 | android-developer (router), android-phone-developer, kotlin-architector, test-generator, security-auditor, code-fixer, dependency-manager |
| **Commands** | 7 | build-test, lint-fix, code-review, code-refactor, generate-tests, deps-audit, modernize |
| **Skills** | 22 SKILL.md | 1 top + 1 workflow-integration + 6 domain routers + 14 leaves (architecture/4, compose-ui/4, data/3, concurrency-networking/1, quality/1, tooling/1) |
| **Skill domains** | 6 | architecture, compose-ui, data, concurrency-networking, quality, tooling |
| **Hooks** | 3 | audit-tooluse.sh (PostToolUse), audit-subagent.sh (SubagentStop), precompact-checkpoint.sh (PreCompact) |

## CC Features Adopted at 1.0.0

Born on the igrsoft v3.17.0 / CC 2.1.169 baseline, the plugin adopts the current
capability set from the start:

- **Tiered `maxTurns`** — every agent declares a runaway-loop backstop sized to
  its role: haiku/low 30 (`dependency-manager`), haiku/medium 30 (`code-fixer`),
  sonnet/medium 40 (`android-developer` router), sonnet/high 50
  (`android-phone-developer`, `test-generator`, `security-auditor`), opus/xhigh 50
  (`kotlin-architector`).
- **`disallowed-tools: Write, Edit`** — declared on the review-only agent
  (`security-auditor`) as defense-in-depth on top of its already Write/Edit-free
  `tools:` allow-list. Fixes route to `code-fixer`.
- **Fully-qualified `Task(plugin:agent)` references** — all delegations use the
  `Task(android-developer:<agent>)` / `subagent_type="android-developer:<agent>"`
  form; no bare agent names anywhere. Cross-plugin targets keep their own prefix
  (`igrsoft:*`, etc.).
- **Scoped `Bash(cmd:*)` allowlists** — each agent's `tools:` enumerates only the
  toolchain binaries it needs (for example `android-phone-developer`: git, gradle,
  ./gradlew, adb, ktlint, detekt). Because scoped patterns do not match compound
  commands, agents issue single-command invocations (`./gradlew :app:assembleDebug`,
  `adb install -r app.apk`) rather than `cd`-chains.
- **Plugin-scoped advisory hooks** — `hooks/{audit-tooluse,audit-subagent,
  precompact-checkpoint}.sh`, wired in `plugin.json` (PostToolUse / SubagentStop /
  PreCompact). All rows are advisory (`actor: "android-developer:hook:*"`,
  `metadata.advisory: true`) and share igrsoft's `dedupe_key` / `dedupe_key_extended`
  shape so igrsoft's `audit-dedup.sh` keeps the orchestrator row authoritative when
  android-developer runs nested. Each script has `--self-test`.

## Not Adopted (igrsoft-owned infrastructure)

android-developer agents are invoked specialists; igrsoft owns orchestration. The
following stay orchestrator-owned and are deliberately **not** implemented here:

- **`audit-dedup.sh`** — igrsoft-owned. android-developer emits advisory rows with
  matching dedupe keys for igrsoft's helper to reconcile; it does not reconcile
  them itself.
- **`state-merge.sh` / SubagentStop `state.json` merge** — orchestrator-owned. The
  hooks here read and checkpoint state but never merge it. Frontmatter emission is
  unconditional (it is the input igrsoft's merge layer consumes).
- **Screenshot-gate ownership** — igrsoft owns the evidence gate. android-developer
  work defaults to `requires_screenshots: false` and, when a gate demands proof,
  supplies `cli-fallback` terminal transcripts (`./gradlew` build/test output,
  ktlint/detekt reports, `adb logcat`). It does not own or override the gate itself.

## Decisions Log

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
- **Review-only `security-auditor`** — carries `disallowed-tools: Write, Edit` and
  routes all remediation to `code-fixer`. Keeps the review/fix separation explicit
  and auditable.
- **Plain command names** — commands use bare filenames (invoked as
  `/android-developer:<name>`), mirroring system-developer/apple-developer, rather
  than a verb-prefix scheme. `lint-fix` and `deps-audit` run on `model: haiku`.
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
