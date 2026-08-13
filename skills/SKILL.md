---
name: skills
description: >-
  Comprehensive Android development skills for Kotlin and Jetpack Compose. Use
  when designing app architecture (Clean Architecture, MVVM, MVI, modularization,
  Hilt), building Compose UI (recomposition, Material 3, navigation, accessibility),
  implementing data layers (Room, Retrofit, offline-first), writing coroutine/Flow
  concurrency, testing (JUnit/MockK/Turbine/Compose/screenshot), or configuring
  Gradle builds (version catalogs, convention plugins, R8).
license: Apache-2.0
metadata:
  author: IGRSoft
  last-updated: '2026-06-23'
  keywords: [android, kotlin, jetpack-compose, gradle, architecture, testing]
---

# Skills Index

## Overview

This collection provides guidance for Android development across seven domains —
architecture, Compose UI, data, concurrency-networking, quality, tooling, and the
shared workflow integration. The emphasis is on **modern, idiomatic Kotlin**:
unidirectional data flow, stable and recomposition-efficient Compose, structured
concurrency, and a version-catalog-driven Gradle build. When a library or API
claim matters, verify it against the project's declared versions
(`gradle/libs.versions.toml`) and current docs (Context7/Ref) rather than trusting
memory.

## Quick Navigation

| Domain | Entry | Focus |
|--------|-------|-------|
| [Architecture](architecture/SKILL.md) | `architecture/SKILL.md` | Clean Architecture, modularization, Hilt DI, ViewModel + StateFlow |
| [Compose UI](compose-ui/SKILL.md) | `compose-ui/SKILL.md` | Recomposition/stability, Material 3 theming + M3 Expressive design-craft, navigation, accessibility |
| [Data](data/SKILL.md) | `data/SKILL.md` | Room, Retrofit networking, offline-first repositories |
| [Concurrency & Networking](concurrency-networking/SKILL.md) | `concurrency-networking/SKILL.md` | Coroutines, Flow, scopes/dispatchers, cancellation |
| [Quality](quality/SKILL.md) | `quality/SKILL.md` | JUnit/MockK/Turbine, Compose UI tests, screenshot tests |
| [Tooling](tooling/SKILL.md) | `tooling/SKILL.md` | Gradle version catalogs, convention plugins, build perf, R8 |
| [Shared](_shared/_index.md) | `_shared/_index.md` | Workflow integration, model/severity/testing helpers |

## I need help with...

| Task | Go to |
|------|-------|
| Structuring layers (ui/domain/data) and boundaries | [architecture/clean-architecture/SKILL.md](architecture/clean-architecture/SKILL.md) |
| Splitting the app into feature/layer modules | [architecture/modularization/SKILL.md](architecture/modularization/SKILL.md) |
| Wiring Hilt modules, components, and scopes | [architecture/hilt-di/SKILL.md](architecture/hilt-di/SKILL.md) |
| Exposing UI state from a ViewModel | [architecture/viewmodel-stateflow/SKILL.md](architecture/viewmodel-stateflow/SKILL.md) |
| Fixing recomposition / stability problems | [compose-ui/compose-best-practices/SKILL.md](compose-ui/compose-best-practices/SKILL.md) |
| Theming with Material 3 color roles | [compose-ui/material3/SKILL.md](compose-ui/material3/SKILL.md) |
| M3 Expressive design-craft: spring motion, shape variety/morphing, emphasis, hero moments, anti-patterns | [compose-ui/material3-expressive/SKILL.md](compose-ui/material3-expressive/SKILL.md) |
| Type-safe navigation and deep links | [compose-ui/navigation/SKILL.md](compose-ui/navigation/SKILL.md) |
| Making a screen accessible (TalkBack, touch targets) | [compose-ui/accessibility/SKILL.md](compose-ui/accessibility/SKILL.md) |
| Persisting with Room (entities, DAOs, migrations) | [data/room/SKILL.md](data/room/SKILL.md) |
| Calling an API with Retrofit | [data/retrofit-networking/SKILL.md](data/retrofit-networking/SKILL.md) |
| Building an offline-first repository | [data/offline-first/SKILL.md](data/offline-first/SKILL.md) |
| Coroutine scopes, dispatchers, Flow operators | [concurrency-networking/coroutines-flow/SKILL.md](concurrency-networking/coroutines-flow/SKILL.md) |
| Writing JUnit/MockK/Turbine/Compose tests | [quality/testing/SKILL.md](quality/testing/SKILL.md) |
| Setting up version catalogs / convention plugins / R8 | [tooling/gradle-build/SKILL.md](tooling/gradle-build/SKILL.md) |
| Participating in a corpflow stage | [_shared/workflow-integration/SKILL.md](_shared/workflow-integration/SKILL.md) |

## Conventions

- **Unidirectional data flow.** State flows down (immutable `StateFlow<UiState>`),
  events flow up (lambdas). No mutable domain state inside composables.
- **Lint as a gate.** Kotlin is expected to build ktlint- and detekt-clean; tests
  cover new logic.
- **Version-catalog discipline.** All dependency versions live in
  `gradle/libs.versions.toml`; no inline or dynamic versions.
- **Synthesized & attributed.** Every skill's prose is original IGRSoft synthesis;
  each `SKILL.md` carries an `## Attribution` section naming its sources.

## Attribution

Index and navigation original to IGRSoft (Apache-2.0). Domain skills synthesize Android
community references (`new-silvermoon`, `piyushverma0`, `ayush016`) and Google's
official `android/skills` (Apache License 2.0); see each skill's `## Attribution`
section for specifics.
