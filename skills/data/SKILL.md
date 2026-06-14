---
name: data
description: Android data layer: Room persistence, Retrofit networking, and offline-first repositories with a single source of truth. Use when implementing persistence, API access, or sync.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-14'
  keywords: [data, room, retrofit, offline-first, repository, android]
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

## Attribution

Synthesized by IGRSoft (MIT) from community data references (`piyushverma0`,
`new-silvermoon`). No content copied verbatim.
