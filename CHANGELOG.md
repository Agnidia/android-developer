# Changelog

All notable changes to the android-developer plugin are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.1] — 2026-09-07

A green Gradle unit-test task prints no test count, so a suite that ran 71 tests and one that ran
zero produce identical stdout and identical exit codes. The build+test command's output template
already promised `{N passed, M failed}` while nothing in its workflow ever obtained either number.
This release makes the count real and makes zero a failure.

### Added

- **`### Phase 5: Count` in `commands/build-test.md`** — resolves the module's own
  `build/test-results` directory, sums the `<testsuite>` attributes over every `TEST-*.xml` with a
  shell helper, and computes `executed = tests - skipped`. It runs unconditionally and *before*
  failure triage, so a red run is triaged with its counts in hand rather than reporting a
  `{M} failed` it never had. The old report phase becomes Phase 6.
- **`## Test Verdicts` in `commands/build-test.md`** — the normative table behind the count. Three
  oracles answer three separate questions: Gradle's per-task console line says what ran, a
  freshness marker touched immediately before the invocation says whose result files these are, and
  the XML says how many. That separation is what distinguishes a legitimately `cached` run, which
  passes, from a `stale` one whose task ran and wrote nothing, which fails on a prior run's totals.
  `--rerun-tasks` is named as the operator's manual disambiguation for `stale` and `unknown`; it is
  not a default and not a new flag, because it invalidates the whole task graph to settle a question
  the log usually answers for free.
- **`### No test results produced` error handling** — the literal message, the likely causes, and
  the reason it does not delegate: the log is green, so `android-phone-developer` would be handed
  nothing to diagnose.
- **`scripts/parser-fixture-check.sh`** (new), run by `scripts/run-checks.sh` as a **fatal** check.
  It extracts both result-reading helpers from the markdown that ships rather than keeping its own
  copy, so what it asserts is what runs; the extraction requires each helper to appear exactly once
  across the tree, which is the mechanical guard behind "reference the counting phase, never copy
  it". **Two consequences for contributors**: a second copy of either helper anywhere in the repo
  fails the gate, and so does reshaping the fenced block they live in — the latter exits with its
  own status and its own message, so a markdown move is not reported as a broken helper.
- **A verdict-table layer in the same check** — every outcome the extractor can produce must have a
  row in the table. The table is prose, and prose has no way to notice a missing case.
- **`### Scoped run executed nothing` in `commands/gen-tests.md`** — the same rule keyed to the
  scoped `--tests <NewClass>` selector rather than a whole-module count. A module whose other tests
  all pass must still fail when the new class ran nothing.

### Changed

- **0 executed is a FAILURE, not a pass**, wherever a test run was attempted — including a module
  with no test source set. `--no-test` is the sole exception: it skips counting entirely and its
  test row reads `⏭ not run (--no-test)`, which is neither a pass nor a failure. No opt-out flag is
  added; the only use for one would be to suppress the signal this release exists to create.
- **`CORPFLOW.md` evidence line** now carries the count as a fixed, greppable token:
  `**Evidence**: <build status>; tests: <N> executed, <M> failed | not run (--no-test); <screenshot status>`.
  A count no downstream reader can locate reliably reproduces the defect at one remove.
- **`commands/gen-tests.md`** verifies by reference to `§ Phase 5: Count` rather than by copying the
  snippet, and its `## Workflow` is split into four steps. Step 1 now defines `$LOG`, which the file
  used but never set.
- **`commands/develop-feature.md`** Phase 3 gate requires a non-zero executed count, and its report
  row reads `{n} added, {e} executed, {m} failed`.
- **`agents/and-test-generator.md`** reports the executed count instead of a pass/fail verdict.

### Fixed

- **`.claude-plugin/plugin.json` description** — a pasted fragment mid-string left it incoherent,
  and it asserted a `requires_screenshots` value contradicting `CORPFLOW.md`. Rewritten as one
  sentence that makes no evidence-norm claim; the seam owns that.
- **`CORPFLOW.md` size budget** — three contradictory rows disagreed on the line ceiling. Only the
  ≤295 row survives.
- **`MEMORY.md`** — corpflow compatibility `v4.0.27`, matching the seam; the command inventory reads
  17 and lists the two `gen-playstore-*` commands 1.5.0 added.

## [1.5.0] — 2026-08-26

Play Store publishing arrives. corpflow is retiring its Apple-only App Store commands to the plugin
that ships to that store; Android had no equivalent at all — a case-insensitive search of this
repository for *Play Console*, *Google Play*, *Play Store*, or *fastlane* returned zero hits before
this release.

### Added

- **`agents/and-release-engineer.md`** (new). Owns everything between a green build and the app
  being live on Play: the Console listing, graphic assets, release track, rollout, and the
  declarations Play blocks review on. `sonnet` / `effort: high` / `maxTurns: 50`. It builds nothing
  itself — the AAB comes from `/android-developer:build-test` like every other build here.
  Encodes the three checks that break a release most often (`versionCode` monotonicity, R8 mapping
  upload, `targetSdk` floor), the four-track model with staged rollout as the production default,
  and the fact that **halting a rollout stops distribution but does not roll back users who already
  updated** — the only forward path from a bad release is a higher `versionCode`.
- **`commands/gen-playstore-listing.md`** — scaffolds `PlayStore/` and generates the listing from
  the project README, asserting Play's own per-field budgets (app name 30, short description 80,
  full description 4000, release notes 500) rather than App Store Connect's. Play has **no keywords
  field**, so search relevance has to live inside the prose; the command says so instead of
  emitting an empty section for a field that does not exist.
- **`commands/gen-playstore-screenshots.md`** — validates sources against Play's dimension and count
  rules and emits an assembly plan. It derives required form factors from the manifest and module
  list rather than from the flag, because a device type the app declares but ships no screenshots
  for is not an error at upload — it silently ranks worse on that form factor.
- **RE row in `CORPFLOW.md`**, marked *consultation only* exactly as AR is: corpflow keeps the stage
  and every `state.json` write. The same agent is reachable outside the pipeline through corpflow's
  `/appstore` command, and in that mode still emits handoff frontmatter and still writes no
  `state.json`. `Targets corpflow` → `4.0.26`.

### Fixed

- **`marketplace.json` `metadata.version` had drifted to `1.4.1` while `plugin.json` read `1.4.3`.**
  This repository has no manifest-parity test to catch it, so nothing reported the mismatch. Both
  now read `1.5.0`.

### Notes

- **In-app purchases are deliberately not included.** Porting App Store Connect's IAP flow is not a
  translation: Play Billing's product setup differs field by field, and the browser automation would
  have to be reverse-engineered against a live console. Deferred rather than approximated.
- **`gen-playstore-screenshots` produces a plan and copy, not composited images.** This plugin ships
  no image compositor; inventing one would produce assets nobody could reproduce.

## [1.4.3] — 2026-08-15

### Fixed

- **`CORPFLOW.md` now states the build/test contract, and no longer contradicts it.** The seam
  file said nothing about how to build or test, so a sibling agent denied by corpflow's
  test-execution gate had no sanctioned next step. In a measured four-platform run two streams
  were denied, both invented `--build-only` (not a real flag on any plugin's command, so it
  classifies as a full test run and is denied again), and both then fell back to invoking the
  toolchain directly — which `agents/developer.md` forbids. The file now says: build and test
  only through this plugin's `build-test` command, pass `--no-test` when you only need to
  compile, and if the gate still denies you, record `requests_test_evidence` or return
  `verdict: blocked` — never reach for the toolchain.

- **Added a worktree-isolation section.** A sibling dispatched for DV runs in an isolated
  worktree, and the file previously said only "Write to `.context/`. Nothing else in the
  repository is yours to create" — which is wrong for DV, and silent on the tree check. Two
  agents in identical situations resolved it differently: one blocked correctly, one entered a
  different worktree and relocated its tree. The file now states that a resolved-vs-assigned
  mismatch means stop and report, that agents neither create nor move worktrees, and that the
  pin must be re-confirmed before each write batch rather than only at entry.

- **Named the authoritative screenshot manifest.** `state.json facts.screenshots` is capped and
  merged last-writer-wins, so in a multi-stream run it reflects one stream and drops the rest.
  A stream discovered this alone and invented its own ledger key to avoid erasing a sibling's
  rows. The file now directs captures to the run's `screenshots.md` manifest and says not to
  read or write the ledger key.

- **Stated that returning is what settles a stage.** The completion patch keys on the return
  summary; reporting out of band does not mark a stage complete. A stage that finished its work
  and reported by message left its artifact on disk while the ledger still read `in_progress`.

- **Corrected the `## Artifacts` scope line** so it no longer tells a DV agent that nothing
  outside `.context/` is its to create.

## [1.4.2] — 2026-08-15

### Fixed

- **Audit rows are no longer duplicated across installed plugins.** Every installed dev
  plugin registers its own copy of `hooks/audit-tooluse.sh` and `hooks/audit-subagent.sh`,
  and all of them fire on the same event, so one tool call was recorded six times — twelve
  for subagent-stop, which fires twice per stop. A measured five-hour run produced 2,837
  audit rows of which 2,265 (80%) were advisory duplicates, and every reader of
  `audit.jsonl` paid to parse them.

  `metadata.dedupe_key` was already present and already identical across all copies, and
  nothing consulted it at write time. A reconciler does exist — corpflow's
  `skills/agent-coordination/scripts/audit-dedup.sh`, which keeps the `hook:*` row and drops
  agent rows for the same key — but it is a **read-time filter invoked only by
  `/cost-report`**, not the automatic "audit-dedup hook" these headers name. So the rows still
  accumulate on disk in full, and every other reader of the trail pays for them.

  Both hooks now reconcile at the point of writing: if the key is already present in the tail
  of `audit.jsonl`, the advisory row is dropped. This is consistent with `audit-dedup.sh` —
  the canonical `hook:*` row is never suppressed, so a later read-time dedup still resolves
  every group the same way.

  The canonical orchestrator row is never suppressed — it is written by a different hook
  that carries no advisory flag and performs no such check. Distinct events are unaffected;
  only exact `dedupe_key` repeats are dropped.

- **`build-test` now resolves the Android toolchain environment itself.** Gradle needs both
  `ANDROID_HOME` (or a `sdk.dir` in `local.properties`) and `JAVA_HOME`, and neither is
  guaranteed to be exported in the shell a given stage runs in. In a measured run one stage
  inherited them and built successfully; the next stage, invoking the same command, failed
  with a `sdk.dir` error that reads as a broken project rather than a missing variable.
  Phase 1 now honours an existing `ANDROID_HOME`/`ANDROID_SDK_ROOT` or a pinned `sdk.dir`,
  falls back to the standard SDK location per platform, and falls back to Android Studio's
  bundled JBR for `JAVA_HOME` — which is frequently the only JDK present. If neither an SDK
  path nor `sdk.dir` resolves, the command now stops up front instead of failing minutes
  later on a misleading message.

## [1.4.1] — 2026-08-15

### Changed

- corpflow contract: the worktask state ledger moved from `stages.<CODE>` to `tasks.<ID>`
  (`state.json` `version: 2`), so `CORPFLOW.md` names the new path. corpflow retired Claude Code's
  Task System after CC 2.1.233 removed those tools on every model it dispatches.
- `hooks/README.md`: corpflow's audit hook now matches `Write|Edit|Bash`, recording Bash rows only
  for ledger patches.

## [Unreleased]

## [1.4.0] — 2026-07-29

Four agents renamed to carry the plugin-unique `and-` prefix, resolving a silent
name collision with `apple-developer`, plus an audit pass for one-stack rules
stated as universal.

### Changed — BREAKING

- **Four agents renamed.** Claude Code keys installed agents by frontmatter
  `name`, so `android-developer` and `apple-developer` shipping the same bare
  names silently overwrote each other. Separately, `error_file` derives from the
  agent basename, so a worktask touching both plugins had them writing to the
  same `.context/errors/test-generator.md`.

  | Old `plugin:agent` ID | New `plugin:agent` ID |
  |---|---|
  | `android-developer:code-fixer` | `android-developer:and-code-fixer` |
  | `android-developer:security-auditor` | `android-developer:and-security-auditor` |
  | `android-developer:test-generator` | `android-developer:and-test-generator` |
  | `android-developer:dependency-manager` | `android-developer:and-dependency-manager` |

  The old names no longer resolve. Anything dispatching them — `Task()` grants in
  another plugin's agent frontmatter, `subagent_type=` strings, saved invocations,
  the company-workflow registry — must be updated. `android-developer`,
  `android-phone-developer`, and `kotlin-architector` are unchanged; the four
  `error_file` paths move to `.context/errors/and-*.md` with them.

  This adopts the `sys-` / `fe-` / `be-` / `ai-` convention the other dev plugins
  already follow, and closes the migration tracked in company-workflow's
  `compatible-plugins.md` § Naming.

### Fixed — platform-leak audit

Rules true for one stack but written as universal, which mis-instruct agents on a
variant the plugin accepts as input:

- **`analyze-accessibility` claimed a coverage it does not have.** It advertised
  auditing "Android UI" and instructed reading "composables and layouts", but all
  eleven Phase 1 checks are Compose-only. On a View/XML module every check found
  nothing and the command emitted a clean report. Narrowed the claim to the
  Compose surface, added a UI-toolkit detection step, and added a View/XML branch
  that reports unaudited coverage instead of a pass. Note this narrows the claim
  rather than adding View/XML checks — the plugin does not implement them.
- **`--device SERIAL` was advertised but never wired.** `debug`,
  `analyze-accessibility`, and `fix-performance` all documented it, yet `adb -s`
  appeared nowhere in the repo; every adb call was bare, which fails with
  `more than one device/emulator` in exactly the multi-device case the flag exists
  for. All three now thread the serial through adb and the Gradle connected runs.
- **`build.gradle.kts` was the only build script named.** `agents/_base/platform-agent.md`
  — inherited by all seven agents — told them to read `build.gradle.kts` and
  `libs.versions.toml` in a rule whose point is "never assume a version", while
  `fix-modernize --target kotlin-dsl` exists precisely to migrate Groovy
  `build.gradle` projects. Now names both.
- **`fix-quick` could not honour its own skip-missing rule.** It ran
  `./gradlew ktlintCheck detekt lint` as one command; Gradle aborts the entire
  invocation on the first unknown task, so a project without detekt ran *no*
  linters rather than "the rest". Now enumerates available tasks first and reports
  each linter skipped for absence.
- **`gen-tests --framework` was documented as an override and then ignored.** The
  workflow only auto-detected and the output reported `{detected}`. The override
  is now honoured and a contradiction with detection is surfaced.
- **Koin was offered as a detected DI framework with no guidance behind it.**
  `arch-select` and `arch-review` both report `{Hilt|Koin|manual}`, but every DI
  rule routes to `skill: hilt-di`, so a Koin project was detected then reviewed
  against Hilt rules. Both now scope the Hilt playbook explicitly and fall back to
  framework-independent DI properties.

## [1.3.0] — 2026-07-29

Command-surface unification with the sibling `apple-developer` and
`system-developer` plugins: a shared verb-first naming scheme, a single
frontmatter standard, and the eight commands android-developer was missing.
Command count goes from 7 to 15.

### Added

- **`arch-select`** — choose an architecture pattern for new work and produce the
  concrete Gradle module and package structure. Read-only. Routes to
  `kotlin-architector`.
- **`arch-review`** — detect the pattern a module actually uses and report layer,
  module-boundary, state-ownership, and DI violations by severity. Routes to
  `kotlin-architector`.
- **`analyze-tech-debt`** — rank technical debt across code, architecture,
  dependency, and test axes by impact/effort, and point each item at the command
  that remediates it. Read-only.
- **`gen-docs`** — KDoc for Kotlin and Compose declarations plus an optional
  Dokka run, gated on a green compile.
- **`debug`** — two modes: configure logcat filters, StrictMode, and Compose
  layout inspection for an ongoing investigation, or triage a specific crash,
  ANR, or exception. Triage is advisory and does not mutate source.
- **`analyze-accessibility`** — audit TalkBack labelling, Compose semantics,
  touch-target size, contrast, and focus order against WCAG 2.2. Read-only.
  Routes to `android-phone-developer`. Adapted from the `frontend-developer`
  audit, which is the closer domain analog.
- **`fix-performance`** — Macrobenchmark, Perfetto, and `gfxinfo` measurement
  with baseline profiles. The default path measures only; applying optimizations
  requires `--apply` plus an explicit phase checkpoint, and every applied change
  is re-measured or reverted.
- **`develop-feature`** — feature development end-to-end through
  `kotlin-architector` → `android-phone-developer` → `test-generator` →
  `security-auditor`, build-gated per phase with an approval checkpoint between
  phases.
- **`scripts/check-command-registration.sh`** — validator asserting a bijection
  between `commands/*.md` and `marketplace.json`'s `commands[]`. Wired into
  `scripts/run-checks.sh` as a fatal check.
- **`CHANGELOG.md`** — this file. Prior releases are reconstructed from
  `MEMORY.md`'s version history.

### Changed

- **Commands renamed** to the cross-plugin verb-first scheme. Old names no
  longer resolve:

  | Old | New |
  |-----|-----|
  | `code-review` | `review-code` |
  | `lint-fix` | `fix-quick` |
  | `modernize` | `fix-modernize` |
  | `code-refactor` | `fix-refactor` |
  | `generate-tests` | `gen-tests` |
  | `deps-audit` | `deps` |

  `build-test` is unchanged.
- **`deps` restructured to subcommand dispatch** — `deps audit` (the default when
  no subcommand is given) and `deps upgrade`, replacing the old `--fix` flag.
  Audit is read-only; upgrade routes to `dependency-manager`.
- **Frontmatter standardized across all 15 commands** — `estimated-cost` added to
  the six commands that lacked it, seeded from their apple/system counterparts.
  Descriptions are verb-first and trimmed to ≤120 characters, including three
  pre-existing overruns (`fix-modernize` was 233).
- **`model: haiku` removed from `deps`** — its work spans catalog parsing, CVE
  triage, and upgrade routing, matching the 20-30% haiku distribution of its
  peers rather than a haiku-only pass. `fix-quick` keeps `model: haiku`: it is a
  deterministic linter run.
- **The `(Android)` suffix dropped from every command H1** — the
  `/android-developer:` namespace already carries the identity.

### Fixed

- Stale command references in `README.md`, `MEMORY.md`, `agents/code-fixer.md`,
  and `skills/compose-ui/material3-expressive/references/anti-patterns.md`.

## [1.2.0] — 2026-07-22

company-workflow compatibility ported v3.17.0 → v3.36.0. Screenshot-gate hardening
(evidence-freshness rule, conditional armed-gate provenance rule), state-patch
pointer form, output budgets on DV/AR/DR agents, complexity triage on
`kotlin-architector`, and the displayed-enabled control sweep test pattern.
Added `scripts/section-lint.sh` and `scripts/desc-lint.sh`. Fixed the stale
`marketplace.json metadata.version` and registered the
`compose-ui/material3-expressive` skill.

## [1.1.0] — 2026-06-23

Added the `compose-ui/material3-expressive` skill (SKILL.md plus three
references) covering M3 Expressive design craft, spring motion, shape morphing,
the 48-role color system, component replacements, and the "AI slop" anti-pattern
checklist.

## [1.0.0]

Initial release on the company-workflow v3.17.0 / CC 2.1.169 baseline: 7 agents, 7
commands, 23 skills across 6 domains, and 3 plugin-scoped advisory hooks.
