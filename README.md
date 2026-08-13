# android-developer

Android development toolkit for Claude Code — specialized agents, skills, and
commands for Kotlin, Jetpack Compose, and Gradle, with full integration into the
corpflow 11-stage pipeline.

| Field | Value |
|-------|-------|
| Plugin version | 1.4.0 |
| License | Apache-2.0 |
| Build tooling | Gradle / adb (Bash-only — no Android build MCP exists) |
| Evidence norm | `requires_screenshots: false` + cli-fallback transcripts |

## What it is

A drop-in sibling to the `system-developer` plugin. android-developer drives the
Android toolchain (`./gradlew`, `adb`, `ktlint`, `detekt`) through **scoped Bash
grants** — there is no Android build-MCP server, so the native toolchain via Bash
is the only build/test path. Because the deliverables produced by these agents are
Kotlin/Compose source with no emulator-render surface by default, the plugin adopts
the system-developer evidence model: `requires_screenshots: false` with CLI/Gradle
transcripts as cli-fallback evidence.

## Agents

Entry point is the `android-developer` router, which detects form factor and
module layout and routes to a specialist. All agents inherit
`agents/_base/platform-agent.md` and delegate via fully-qualified
`Task(android-developer:<name>)` edges.

| Agent | Model / Effort | Role |
|-------|----------------|------|
| `android-developer` (router) | sonnet / medium | DV entry; detects layout, routes, verifies returns |
| `android-phone-developer` | sonnet / high | Phone & tablet Compose + Kotlin implementation (primary DV worker) |
| `kotlin-architector` | opus / xhigh | Clean Architecture, modularization, Hilt graph, MVI vs MVVM |
| `and-test-generator` | sonnet / high | JUnit5/JUnit4, MockK, Turbine, Compose UI test, Roborazzi/Paparazzi |
| `and-security-auditor` | sonnet / high | Permissions, exported components, DataStore/EncryptedFile, R8/ProGuard (review-only) |
| `and-code-fixer` | haiku / medium | DR batch remediation; ktlint/detekt auto-fix; minimal-diff |
| `and-dependency-manager` | haiku / low | Gradle version catalogs, CVE scan, safe one-at-a-time upgrades |

## Skills

Seven domains (Google `android/skills` SKILL.md frontmatter spec). Each leaf
skill is a `SKILL.md` plus a `references/` directory; domain `SKILL.md` files are
thin routers.

| Domain | Skills |
|--------|--------|
| `architecture` | clean-architecture, modularization, hilt-di, viewmodel-stateflow |
| `compose-ui` | compose-best-practices, material3, material3-expressive, navigation, accessibility |
| `data` | room, retrofit-networking, offline-first |
| `concurrency-networking` | coroutines-flow |
| `quality` | testing (Apache-2.0 — Google-blended) |
| `tooling` | gradle-build (Apache-2.0 — Google-blended) |

All skill prose is **synthesized** in IGRSoft voice — never copied verbatim from
source repositories. Each `SKILL.md` carries an `## Attribution` section naming
its sources. Google-derived content (`quality/testing`, `tooling/gradle-build`)
is stamped `license: Apache-2.0`, as is all community-synthesized content.

## Commands

Invoked as `/android-developer:<command>`. The happy path is shell-only
(`./gradlew` / `adb`); on failure they classify the error and delegate to exactly
one fully-qualified `android-developer` agent.

Names follow the cross-plugin verb-first scheme shared with `apple-developer` and
`system-developer` (`review-*`, `fix-*`, `gen-*`, `arch-*`, `analyze-*`).

| Command | Model | Purpose |
|---------|-------|---------|
| `analyze-accessibility` | default | TalkBack, Compose semantics, touch targets, contrast — read-only |
| `analyze-tech-debt` | default | Rank debt across code / architecture / dependency / test axes — read-only |
| `arch-review` | default | Review a module against its detected pattern; boundary violations by severity |
| `arch-select` | default | Choose a pattern for new work and produce the package structure — read-only |
| `build-test` | default | Detect Gradle wrapper, assemble + unit-test a variant/module |
| `debug` | default | Configure logcat/StrictMode/layout inspection, or root-cause a crash or ANR |
| `deps` | default | `audit` (default) the version catalog, or `upgrade` one entry at a time |
| `develop-feature` | default | Feature end-to-end: architecture → implementation → tests → security |
| `fix-modernize` | default | XML→Compose, View→Compose, Groovy→Kotlin-DSL, library/API migration |
| `fix-performance` | default | Macrobenchmark/Perfetto measurement; optimizations behind `--apply` |
| `fix-quick` | haiku | `ktlintCheck`/`detekt`/`lint` report or `ktlintFormat`/`--auto-correct` fix |
| `fix-refactor` | default | Refactor toward clean-arch / MVI / modularization |
| `gen-docs` | default | KDoc for Kotlin/Compose declarations; optional Dokka run |
| `gen-tests` | default | Detect framework, delegate and-test-generator, verify suite |
| `review-code` | default | Static review (Compose anti-patterns, coroutine misuse, arch violations) |

`.claude-plugin/marketplace.json` must list exactly the files in `commands/`;
`scripts/check-command-registration.sh` enforces that bijection and runs as part
of `scripts/run-checks.sh`.

### Migration: old → new names

#### Agents — renamed in 1.4.0 (BREAKING)

Four agents gained the plugin-unique `and-` prefix. Their bare names collided with
identically-named `apple-developer` agents: Claude Code keys agents by frontmatter
`name`, so the two plugins silently overwrote each other, and both wrote to the same
`.context/errors/<basename>.md`. The old IDs no longer resolve — update any `Task()`
grant, `subagent_type=` string, or saved invocation.

| Old (≤1.3.0) | New (1.4.0) |
|--------------|-------------|
| `android-developer:code-fixer` | `android-developer:and-code-fixer` |
| `android-developer:security-auditor` | `android-developer:and-security-auditor` |
| `android-developer:test-generator` | `android-developer:and-test-generator` |
| `android-developer:dependency-manager` | `android-developer:and-dependency-manager` |

`android-developer`, `android-phone-developer`, and `kotlin-architector` are unchanged.

#### Commands — renamed in 1.3.0

The old names no longer resolve — update any saved invocation.

| Old (≤1.2.0) | New (1.3.0) | Note |
|--------------|-------------|------|
| `code-review` | `review-code` | |
| `lint-fix` | `fix-quick` | keeps `model: haiku` |
| `modernize` | `fix-modernize` | |
| `code-refactor` | `fix-refactor` | |
| `generate-tests` | `gen-tests` | |
| `deps-audit` | `deps audit` | now a subcommand; bare `deps` defaults to `audit`, `deps upgrade` replaces `--fix` |
| `build-test` | `build-test` | unchanged |

## Install

Add the plugin via its marketplace entry:

```bash
/plugin marketplace add IGRSoft/android-developer
/plugin install android-developer
```

Or load locally from a checkout by pointing your marketplace config at this
directory's `.claude-plugin/marketplace.json`.

## corpflow integration

When `.context/state.json` is present, agents operate inside a corpflow worktask.
The plugin contributes at:

- **DV** (primary) — `corpflow:developer` routes `platform=android` to the
  `android-developer` router, which routes to `android-phone-developer`.
- **DR** (support) — `and-code-fixer` applies fixes; `kotlin-architector` consults on
  patterns.
- **SR** (context) — `and-security-auditor` supplies permissions/exported/R8/secrets
  findings to `corpflow:security-reviewer`.
- **QA** (support) — `and-test-generator` produces JUnit/MockK/Turbine/Compose tests.
- **RE** (packaging) — `and-dependency-manager` freezes version-catalog pins.

The handoff contract (numbered `development-N.md`, `state.json` atomic patch,
`handoff:` frontmatter) is documented in

## Tech Stack

Targets Kotlin 2.0, Jetpack Compose, Gradle 8.x, Hilt 2.x, Room 2.6.x,
Retrofit 2.10.x, Kotlin Coroutines 1.8.x, and Material Design 3.

## Hooks

Plugin-scoped advisory hooks (`hooks/`): `audit-tooluse.sh` (PostToolUse),
`audit-subagent.sh` (SubagentStop), `precompact-checkpoint.sh` (PreCompact). All
rows carry `metadata.advisory: true` and corpflow-compatible dedupe keys; each
script has a `--self-test`. See `hooks/README.md`.

## License

Apache License 2.0 — see [LICENSE](LICENSE) for details.
