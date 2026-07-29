# Changelog

All notable changes to the android-developer plugin are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

igrsoft compatibility ported v3.17.0 → v3.36.0. Screenshot-gate hardening
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

Initial release on the igrsoft v3.17.0 / CC 2.1.169 baseline: 7 agents, 7
commands, 23 skills across 6 domains, and 3 plugin-scoped advisory hooks.
