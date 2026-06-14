---
name: compose-ui
description: Jetpack Compose UI for Android: recomposition and stability, Material 3 theming, type-safe navigation, and accessibility. Use when building Compose screens, fixing jank/recomposition, theming, or making UI accessible.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-14'
  keywords: [compose, jetpack-compose, material3, navigation, accessibility, recomposition]
---

# Compose UI (domain index)

Thin router for the Compose UI skill domain.

| Skill | Use when |
|-------|----------|
| [compose-best-practices](compose-best-practices/SKILL.md) | Recomposition, stability, state hoisting, side-effects |
| [material3](material3/SKILL.md) | Theming, color roles, typography |
| [navigation](navigation/SKILL.md) | Type-safe navigation, deep links |
| [accessibility](accessibility/SKILL.md) | Semantics, TalkBack, touch targets |

## Core principle

A composable is a pure function of its inputs that emits UI. Keep it **stateless** (hoist
state to the caller/ViewModel), pass **stable** parameters, and isolate effects in the
effect APIs (`LaunchedEffect`, `rememberCoroutineScope`). Recomposition is cheap only when
these rules hold.

## Attribution

Synthesized by IGRSoft (MIT) from community Compose references (`new-silvermoon`,
`piyushverma0`, `ayush016`). No content copied verbatim.
