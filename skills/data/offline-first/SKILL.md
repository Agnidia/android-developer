---
name: offline-first
description: Offline-first repositories: the database as single source of truth, network as a refresh, and conflict-aware sync. Use when an app must work offline or cache remote data.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-14'
  keywords: [offline-first, repository, single-source-of-truth, sync, cache, android]
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

## See also
- [references/repository-pattern.md](references/repository-pattern.md)
- [references/single-source-of-truth.md](references/single-source-of-truth.md)

## Attribution
Synthesized by IGRSoft (MIT) from `piyushverma0`, `new-silvermoon`. No verbatim copying.
