---
name: concurrency-networking
description: Kotlin coroutines and Flow on Android: scopes, dispatchers, structured concurrency, Flow operators, and cancellation. Use when writing async code, collecting flows, or reasoning about cancellation.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-14'
  keywords: [coroutines, flow, concurrency, dispatchers, structured-concurrency, cancellation]
---

# Concurrency & Networking (domain index)

Thin router for the concurrency skill domain.

| Skill | Use when |
|-------|----------|
| [coroutines-flow](coroutines-flow/SKILL.md) | Scopes, dispatchers, Flow operators, structured concurrency, cancellation |

## Core principle

Structured concurrency: every coroutine runs in a scope that owns its lifetime
(`viewModelScope`, `lifecycleScope`). No `GlobalScope`. Inject the dispatcher so it is
swappable in tests. Cancellation is cooperative — respect it.

## Attribution

Synthesized by IGRSoft (MIT) from community coroutine references (`new-silvermoon`,
`piyushverma0`). No content copied verbatim.
