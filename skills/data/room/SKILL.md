---
name: room
description: Room persistence: entities, DAOs with Flow queries, relations, and schema migrations. Use when adding local storage, writing queries, or evolving the schema safely.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-14'
  keywords: [room, sqlite, dao, entity, migration, flow, android]
---

# Room

Local persistence with compile-time-checked SQL.

✅ Correct — entity + DAO returning `Flow` for reactive reads:

```kotlin
@Entity(tableName = "users")
data class UserEntity(@PrimaryKey val id: String, val name: String)

@Dao interface UserDao {
    @Query("SELECT * FROM users WHERE id = :id") fun observe(id: String): Flow<UserEntity?>
    @Upsert suspend fun upsert(user: UserEntity)
}
```

❌ Mistake — blocking query on the main thread (no suspend/Flow):

```kotlin
@Query("SELECT * FROM users") fun all(): List<UserEntity>   // WRONG — synchronous main-thread query
```

## Migrations

Never ship a schema change without a migration (or you crash on upgrade):

```kotlin
val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE users ADD COLUMN email TEXT NOT NULL DEFAULT ''")
    }
}
Room.databaseBuilder(ctx, AppDb::class.java, "app.db").addMigrations(MIGRATION_1_2).build()
```

Export the schema (`room.schemaLocation`) and add a `MigrationTestHelper` test. Reserve
`fallbackToDestructiveMigration()` for dev builds only — it wipes user data.

## See also
- [references/entities-daos.md](references/entities-daos.md)
- [references/migrations.md](references/migrations.md)

## Attribution
Synthesized by IGRSoft (MIT) from `piyushverma0`, `new-silvermoon`. No verbatim copying.
