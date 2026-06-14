# Entities & DAOs

- Entities are the persistence shape, not the domain model — map between them.
- DAOs return `Flow<T>` for reactive reads and `suspend` for writes; never blocking
  `List<T>` on the main thread.
- Use `@Upsert` (insert-or-update), `@Transaction` for multi-step reads/writes, and
  `@Relation` for one-to-many without manual joins.
- Index columns used in `WHERE`/`ORDER BY` (`@Entity(indices = [Index("email")])`).

```kotlin
@Transaction @Query("SELECT * FROM users WHERE id = :id")
fun userWithPosts(id: String): Flow<UserWithPosts>
```

## Attribution
Synthesized by IGRSoft (MIT) from `piyushverma0`, `new-silvermoon`. No verbatim copying.
