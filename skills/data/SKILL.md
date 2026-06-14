---
name: data
description: Android data layer: Room persistence, Retrofit networking, and offline-first repositories with a single source of truth. Use when implementing persistence, API access, or sync.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-15'
  keywords: [data, room, retrofit, offline-first, repository, kmp, android]
---

# Data (domain index)

Thin router for the data skill domain.

| Skill | Use when |
|-------|----------|
| [room](room/SKILL.md) | Local persistence: entities, DAOs, migrations |
| [retrofit-networking](retrofit-networking/SKILL.md) | REST access: API services, interceptors, error handling |
| [offline-first](offline-first/SKILL.md) | Repository as single source of truth; cache + sync |

## Core principle

The repository owns the **single source of truth** (usually the local DB) and exposes it
as a `Flow`. The network refreshes the cache; the UI observes the cache. DTOs never escape
the data layer — map to domain models at the boundary.

## Stack (as of 2026-06)

- **Persistence:** Room (KSP processor; reactive `Flow` reads, `suspend` writes). See [room](room/SKILL.md).
- **Networking:** Retrofit 3 with native `suspend` + the `converter-kotlinx-serialization`
  converter, over OkHttp 5. See [retrofit-networking](retrofit-networking/SKILL.md).
- **KMP:** the data module can move to a KMP module (`commonMain` + `androidMain`) sharing
  the **coroutines + kotlinx.serialization** stack with iOS. **Room KMP**
  (`BundledSQLiteDriver`) and **Ktor** are the shared persistence/networking options
  (Retrofit is JVM/Android only). Keep version literals in the version catalog.

## Attribution

Synthesized by IGRSoft (MIT) from community data references (`piyushverma0`,
`new-silvermoon`). No content copied verbatim.
