---
name: architecture
description: Android app architecture for Kotlin: Clean Architecture layering, modularization, Hilt dependency injection, and ViewModel + StateFlow state holders. Use when structuring an app, choosing MVVM vs MVI, splitting modules, or wiring DI.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-15'
  keywords: [android, architecture, clean-architecture, mvvm, mvi, hilt, modularization, kmp]
---

# Architecture (domain index)

Thin router for the architecture skill domain. Pick the leaf skill that matches the
decision in front of you.

| Skill | Use when |
|-------|----------|
| [clean-architecture](clean-architecture/SKILL.md) | Deciding layers (ui/domain/data), boundaries, and the domain model |
| [modularization](modularization/SKILL.md) | Splitting the app into feature/layer modules; convention plugins |
| [hilt-di](hilt-di/SKILL.md) | Wiring Hilt modules, components, and scopes; testable DI |
| [viewmodel-stateflow](viewmodel-stateflow/SKILL.md) | Exposing UI state from a ViewModel via immutable `StateFlow` (UDF) |

## Core principle

Dependencies point **inward**: `ui → domain ← data`. The `domain` layer is pure Kotlin
(no Android framework types), so business rules stay testable and the UI/data layers are
swappable. Everything else in this domain is a refinement of that rule. That purity also
makes `domain` (and a platform-agnostic slice of `data`) a natural **KMP `commonMain`**
module when sharing logic with iOS/desktop.

## Attribution

Synthesized by IGRSoft (MIT) from community Android architecture references
(`new-silvermoon`, `piyushverma0`). No content copied verbatim.
