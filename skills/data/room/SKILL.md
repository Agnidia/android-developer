---
name: room
description: Room persistence: entities, DAOs with Flow queries, relations, and schema migrations. Use when adding local storage, writing queries, or evolving the schema safely.
license: Apache-2.0
metadata:
  author: IGRSoft
  last-updated: '2026-06-15'
  keywords: [room, sqlite, dao, entity, migration, flow, ksp, kmp, android]
---

# Room

Local persistence with compile-time-checked SQL. Use the **KSP processor**
(`ksp("androidx.room:room-compiler:…")` — Room `2.8.4` as of 2026-06; version from the
catalog) — KAPT is a legacy fallback only.

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
`fallbackToDestructiveMigration()` for dev builds only — it wipes user data. For additive
column changes prefer `autoMigrations` (`@Database(autoMigrations = [...])`) — see
[references/migrations.md](references/migrations.md).

## KMP (shared persistence)

Room KMP is stable: put `room-runtime` in `commonMain`, drive it with the
**`BundledSQLiteDriver`** (`androidx.sqlite:sqlite-bundled`, `2.6.2` as of 2026-06;
ships SQLite from source for consistent behaviour across platforms), and declare the
database constructor via `@ConstructedBy` + an `expect object : RoomDatabaseConstructor`.

```kotlin
@Database(entities = [UserEntity::class], version = 1)
@ConstructedBy(AppDbConstructor::class)
abstract class AppDb : RoomDatabase() { abstract fun userDao(): UserDao }

@Suppress("KotlinNoActualForExpect")
expect object AppDbConstructor : RoomDatabaseConstructor<AppDb> { override fun initialize(): AppDb }

fun buildDb(builder: RoomDatabase.Builder<AppDb>): AppDb = builder
    .setDriver(BundledSQLiteDriver())
    .setQueryCoroutineContext(Dispatchers.IO)   // run queries off the main thread
    .build()
```

## See also
- [references/entities-daos.md](references/entities-daos.md)
- [references/migrations.md](references/migrations.md)

## Attribution
Synthesized by IGRSoft (Apache-2.0) from `piyushverma0`, `new-silvermoon`. No verbatim copying.
