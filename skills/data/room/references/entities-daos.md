# Entities & DAOs

- Entities are the persistence shape, not the domain model — map between them.
- DAOs return `Flow<T>` for reactive reads and `suspend` for writes; never blocking
  `List<T>` on the main thread.
- Use `@Upsert` (insert-or-update), `@Transaction` for multi-step reads/writes, and
  `@Relation` for one-to-many without manual joins.
- Index columns used in `WHERE`/`ORDER BY` (`@Entity(indices = [Index("email")])`).
- Generate DAO/entity code with the **KSP processor** (`ksp("androidx.room:room-compiler:…")`);
  KAPT is a legacy fallback only.
- `suspend`/`Flow` DAO methods already run off the main thread; set the query dispatcher
  once on the builder (`.setQueryCoroutineContext(Dispatchers.IO)`) rather than wrapping
  each call.

```kotlin
@Transaction @Query("SELECT * FROM users WHERE id = :id")
fun userWithPosts(id: String): Flow<UserWithPosts>
```

## Attribution
Synthesized by Agnidia (Apache-2.0) from `piyushverma0`, `new-silvermoon`. No verbatim copying.
