---
name: clean-architecture
description: Clean Architecture for Android: ui/domain/data layering, dependency-inversion boundaries, and a pure-Kotlin domain layer. Use when structuring a feature, deciding where logic belongs, or reviewing layer purity.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-14'
  keywords: [clean-architecture, layering, domain-layer, boundaries, use-case, android]
---

# Clean Architecture (Android)

Structure a feature into three layers with dependencies pointing inward.

## Layers

| Layer | Holds | Depends on | Android types? |
|-------|-------|------------|----------------|
| `ui` | Composables, ViewModels, UI state | `domain` | Yes (Compose, lifecycle) |
| `domain` | Use-cases, domain models, repository **interfaces** | nothing | **No** — pure Kotlin |
| `data` | Repository **implementations**, data sources (Room, Retrofit), DTO↔domain mappers | `domain` | Yes |

✅ Correct — the repository interface lives in `domain`, the implementation in `data`:

```kotlin
// domain
interface UserRepository { suspend fun user(id: UserId): Result<User> }
class GetUserUseCase(private val repo: UserRepository) {
    suspend operator fun invoke(id: UserId) = repo.user(id)
}
// data
class DefaultUserRepository(private val api: UserApi, private val dao: UserDao) : UserRepository { /* ... */ }
```

❌ Mistake — domain importing Android or a concrete data type:

```kotlin
// domain/User.kt  — WRONG: Android type leaks into the domain layer
import android.net.Uri
data class User(val avatar: Uri)   // couples domain to the framework
```

## Anti-patterns

- **Fat ViewModel reaching into Retrofit/Room directly** — it should depend on a use-case
  or repository interface, never a concrete data source.
- **DTOs used as UI models** — map at the data boundary; the UI consumes domain/UI models.
- **A `domain` layer that imports `androidx.*`** — the give-away that the boundary leaked.

## See also

- [references/layers.md](references/layers.md) — what each layer may and may not contain
- [references/boundaries.md](references/boundaries.md) — dependency inversion in practice
- [references/domain-layer.md](references/domain-layer.md) — keeping `domain` pure

## Attribution

Synthesized by IGRSoft (MIT) from community Android architecture references
(`new-silvermoon`, `piyushverma0`). No content copied verbatim.
