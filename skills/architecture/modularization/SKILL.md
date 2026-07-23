---
name: modularization
description: Android modularization: by-feature vs by-layer module splits, the :core/:feature convention, and Gradle convention plugins for shared build logic. Use when an app grows past a single module or build times degrade.
license: Apache-2.0
metadata:
  author: IGRSoft
  last-updated: '2026-06-15'
  keywords: [modularization, feature-module, convention-plugin, gradle, android, build-logic, kmp]
---

# Modularization (Android)

Split a growing app into modules to parallelize builds, enforce boundaries, and scope
ownership.

## Strategy

| Approach | Shape | Best for |
|----------|-------|----------|
| by-feature | `:feature:login`, `:feature:profile` | Scaling teams; each feature owns its ui/domain/data |
| by-layer | `:core:ui`, `:core:data`, `:core:domain` | Shared infrastructure consumed by many features |
| hybrid (recommended) | `:feature:*` for features + `:core:*` for shared | Most multi-team apps |

✅ Correct — a feature module depends on core, never on another feature:

```
:app  →  :feature:login, :feature:home
:feature:login  →  :core:ui, :core:domain, :core:data
:core:data  →  :core:domain
```

❌ Mistake — feature-to-feature dependency creates a tangle:

```
:feature:home  →  :feature:login   // WRONG: route via :app or a shared :core contract
```

## Convention plugins

Move repeated build config (Android library setup, Compose, Kotlin options) into a
`build-logic` included build with convention plugins, so each module's build file is a
few lines:

```kotlin
// feature/login/build.gradle.kts
plugins { id("myapp.android.feature") }
```

## Extracting a KMP module

A pure-Kotlin `:core:domain` (and a platform-agnostic slice of `:core:data`) extracts
cleanly into a **Kotlin Multiplatform** module: move the code to `commonMain` and keep
Android-specific bits in `androidMain`. The shared `commonMain` reuses the coroutines +
kotlinx.serialization stack (and Room/Ktor on their KMP paths) with iOS/desktop. KMP for
shared business/data logic is stable — modularize with that extraction in mind when a
second platform is on the horizon.

## Anti-patterns

- **God `:core` module** holding everything → split by concern (`:core:network`,
  `:core:database`, `:core:ui`).
- **Circular module dependencies** → Gradle fails; invert the dependency through a shared
  contract module.
- **Copy-pasted build config** across modules → extract a convention plugin.

## See also

- [references/by-feature.md](references/by-feature.md)
- [references/by-layer.md](references/by-layer.md)
- [references/convention-plugins.md](references/convention-plugins.md)

## Attribution

Synthesized by IGRSoft (Apache-2.0) from community Android architecture references
(`new-silvermoon`, `piyushverma0`). No content copied verbatim.
