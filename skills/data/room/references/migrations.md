# Migrations

Every schema version bump needs a `Migration` or the app crashes on upgrade.

- Export schemas (`ksp { arg("room.schemaLocation", "$projectDir/schemas") }`) and commit
  them — they're the migration test fixtures.
- Test with `MigrationTestHelper`: create vN, run the migration, assert vN+1 shape + data.
- `fallbackToDestructiveMigration()` wipes data — dev/debug only, never release.
- Auto-migrations (`@Database(autoMigrations = [...])`) handle simple column adds; write a
  manual `Migration` for renames, type changes, and data transforms.

## Attribution
Synthesized by IGRSoft (Apache-2.0) from `piyushverma0`, `new-silvermoon`. No verbatim copying.
