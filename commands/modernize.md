---
description: Migrate Android code toward modern idioms — XML layouts to Compose, Views to Compose, Groovy build scripts to the Kotlin DSL, or library/API modernization (KSP2, Retrofit 3, OkHttp 5, M3 Expressive, security-crypto to DataStore+Tink)
argument-hint: [path] [--target xml-to-compose|view-to-compose|kotlin-dsl|api-modernize] [--dry-run]
allowed-tools: Read, Glob, Grep, Bash, Edit
---

# Modernize (Android)
<!-- Updated: June 2026 -->

Run a migration playbook toward a modern Android idiom. Consult `kotlin-architector` for
the migration plan, apply via `code-fixer`, and build-gate after each step.

[Extended thinking: Migrations (XML→Compose, View→Compose, Groovy→Kotlin DSL) are
mechanical but risky at scale. This command turns each into an ordered, build-gated step
plan from the architect, applied by the fixer, verified between steps. It is the migration
sibling of code-refactor.]

## CRITICAL BEHAVIORAL RULES

1. **Incremental, build-gated.** One screen/module per step; `./gradlew assembleDebug test`
   after each.
2. **Architect plans, fixer applies.**
3. **Single-command Bash invocations.**
4. **`--dry-run` prints the plan and stops.**
5. **Never enter plan mode.**

## Usage

```bash
/android-developer:modernize :feature:profile --target view-to-compose
/android-developer:modernize . --target kotlin-dsl --dry-run
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `path` | required | Module/package/file to migrate. |
| `--target xml-to-compose\|view-to-compose\|kotlin-dsl\|api-modernize` | required | Migration target. |
| `--dry-run` | off | Print the step plan; make no edits. |

## Migration Playbooks

| Target | Approach |
|--------|----------|
| `xml-to-compose` | Convert layout XML + `findViewById`/binding to composables; hoist state to a ViewModel; one screen per step. |
| `view-to-compose` | Replace a `Fragment`/`View` with a composable + `ComposeView` bridge during transition; migrate navigation last. |
| `kotlin-dsl` | Convert `build.gradle` (Groovy) to `build.gradle.kts`; move versions to `libs.versions.toml`; one module per step. |
| `api-modernize` | Bump deprecated libraries/idioms to current (versions from the catalog, `skill: tooling`): KAPT→**KSP2** (`ksp.useKSP2=true`), Retrofit 2→**Retrofit 3** (`suspend` + `converter-kotlinx-serialization`), OkHttp 4→**OkHttp 5** (BOM), Material 3→**M3 Expressive** (`MaterialExpressiveTheme`), and **`androidx.security:security-crypto` (EOL) → DataStore + `datastore-tink`**. One library/idiom per step. |

## Workflow

1. Read the target (`git ls-files`, the build files / layout XML / View code).
2. **Consult the architect:**
   **Use Task tool with subagent_type="android-developer:kotlin-architector"**
   Prompt: "Produce an ordered, build-gated migration plan for `{target}` to `{target-kind}`.
   Each step builds and passes tests on its own. Return the step list and the files each
   touches."
3. If `--dry-run`: print and stop.
4. For each step: **Use Task tool with subagent_type="android-developer:code-fixer"** to
   apply, then `./gradlew {module}:assembleDebug test 2>&1 | tee -a "$LOG"`. Stop on
   failure and request a correction from the architect.

## Output Format

```markdown
## Modernize → {target}
**Target:** {path}  **Steps:** {n}  **Log:** .context/logs/modernize-{ts}.log

| Step | Change | Build | Tests |
|------|--------|-------|-------|
| 1 | ProfileFragment → ProfileScreen | ✅ | ✅ |

**Result:** COMPLETE / STOPPED at step {k}
```

## Error Handling

### Build fails mid-migration
Stop, report the failing step, route a correction to `android-developer:kotlin-architector`.

## See Also
- `/android-developer:code-refactor` — pattern refactors (clean-arch, MVI, modularize).
- `skill: compose-ui` / `skill: tooling` — Compose idioms and Kotlin-DSL build setup.
