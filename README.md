# android-developer

Android development toolkit for Claude Code — specialized agents, skills, and
commands for Kotlin, Jetpack Compose, and Gradle, with full integration into the
igrsoft 11-stage worktask workflow.

| Field | Value |
|-------|-------|
| Plugin version | 1.2.0 |
| igrsoft compatibility | v3.36.0 |
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
| `test-generator` | sonnet / high | JUnit5/JUnit4, MockK, Turbine, Compose UI test, Roborazzi/Paparazzi |
| `security-auditor` | sonnet / high | Permissions, exported components, DataStore/EncryptedFile, R8/ProGuard (review-only) |
| `code-fixer` | haiku / medium | DR batch remediation; ktlint/detekt auto-fix; minimal-diff |
| `dependency-manager` | haiku / low | Gradle version catalogs, CVE scan, safe one-at-a-time upgrades |

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
| `_shared` | workflow-integration + model-selection, severity-matrix, testing-principles |

All skill prose is **synthesized** in IGRSoft voice — never copied verbatim from
source repositories. Each `SKILL.md` carries an `## Attribution` section naming
its sources. Google-derived content (`quality/testing`, `tooling/gradle-build`)
is stamped `license: Apache-2.0`, as is all community-synthesized content.

## Commands

Invoked as `/android-developer:<command>`. The happy path is shell-only
(`./gradlew` / `adb`); on failure they classify the error and delegate to exactly
one fully-qualified `android-developer` agent.

| Command | Model | Purpose |
|---------|-------|---------|
| `build-test` | default | Detect Gradle wrapper, assemble + unit-test a variant/module |
| `lint-fix` | haiku | `ktlintCheck`/`detekt`/`lint` report or `ktlintFormat`/`--auto-correct` fix |
| `code-review` | default | Static review (Compose anti-patterns, coroutine misuse, arch violations) |
| `code-refactor` | default | Refactor toward clean-arch / MVI / modularization |
| `generate-tests` | default | Detect framework, delegate test-generator, verify suite |
| `deps-audit` | haiku | Parse `libs.versions.toml`, CVE scan, safe upgrades |
| `modernize` | default | XML→Compose, View→Compose, Groovy→Kotlin-DSL migration |

## Install

Add the plugin via its marketplace entry:

```bash
/plugin marketplace add IGRSoft/android-developer
/plugin install android-developer
```

Or load locally from a checkout by pointing your marketplace config at this
directory's `.claude-plugin/marketplace.json`.

## igrsoft integration

When `.context/state.json` is present, agents operate inside an igrsoft worktask.
The plugin contributes at:

- **DV** (primary) — `igrsoft:developer` routes `platform=android` to the
  `android-developer` router, which routes to `android-phone-developer`.
- **DR** (support) — `code-fixer` applies fixes; `kotlin-architector` consults on
  patterns.
- **SR** (context) — `security-auditor` supplies permissions/exported/R8/secrets
  findings to `igrsoft:security-reviewer`.
- **QA** (support) — `test-generator` produces JUnit/MockK/Turbine/Compose tests.
- **RE** (packaging) — `dependency-manager` freezes version-catalog pins.

The handoff contract (numbered `development-N.md`, `state.json` atomic patch,
`handoff:` frontmatter) is documented in
`skills/_shared/workflow-integration/SKILL.md`.

## Tech Stack

Targets Kotlin 2.0, Jetpack Compose, Gradle 8.x, Hilt 2.x, Room 2.6.x,
Retrofit 2.10.x, Kotlin Coroutines 1.8.x, and Material Design 3.

## Hooks

Plugin-scoped advisory hooks (`hooks/`): `audit-tooluse.sh` (PostToolUse),
`audit-subagent.sh` (SubagentStop), `precompact-checkpoint.sh` (PreCompact). All
rows carry `metadata.advisory: true` and igrsoft-compatible dedupe keys; each
script has a `--self-test`. See `hooks/README.md`.

## License

Apache License 2.0 — see [LICENSE](LICENSE) for details.
