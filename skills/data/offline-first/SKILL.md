---
name: offline-first
description: Offline-first repositories: the database as single source of truth, network as a refresh, and conflict-aware sync. Use when an app must work offline or cache remote data.
license: Apache-2.0
metadata:
  author: Agnidia
  last-updated: '2026-06-15'
  keywords: [offline-first, repository, single-source-of-truth, sync, cache, kmp, android]
---

# Offline-First

The local DB is the single source of truth; the UI observes it; the network refreshes it.

✅ Correct — observe the DB, refresh from network:

```kotlin
class UserRepository(private val api: UserApi, private val dao: UserDao) {
    fun observe(id: String): Flow<User?> = dao.observe(id).map { it?.toDomain() }
    suspend fun refresh(id: String): Result<Unit> =
        runCatching { dao.upsert(api.user(id).toEntity()) }
}
```

The UI collects `observe(id)` and shows cached data instantly; `refresh(id)` updates the
DB, which re-emits. The screen never waits on the network to show *something*.

❌ Mistake — network-first with no cache (blank screen offline):

```kotlin
fun user(id: String): Flow<User> = flow { emit(api.user(id).toDomain()) }   // WRONG — fails offline, no cache
```

## Sync

For background sync use `WorkManager` with a unique periodic work request and a backoff
policy. Resolve conflicts deterministically (last-write-wins with a server timestamp, or a
merge function) — document the rule.

## KMP

The repository, its DTO↔domain mappers, and the SSOT contract are platform-agnostic — move
them to a KMP `commonMain` module to share with iOS. Back it with **Room KMP**
(`BundledSQLiteDriver`) for persistence and **Ktor** for networking; `WorkManager` stays in
`androidMain`. See [room](../room/SKILL.md) and
[retrofit-networking](../retrofit-networking/SKILL.md).

## See also
- [references/repository-pattern.md](references/repository-pattern.md)
- [references/single-source-of-truth.md](references/single-source-of-truth.md)

## Attribution
Synthesized by Agnidia (Apache-2.0) from `piyushverma0`, `new-silvermoon`. No verbatim copying.
