# Platform Agent Base Template

Shared behavior for all android-developer agents — the `android-developer` router,
`android-phone-developer`, `kotlin-architector`, and the utility specialists
(`and-test-generator`, `and-security-auditor`, `and-code-fixer`, `and-dependency-manager`).

## Constraints

- All Kotlin compiles clean under the project's Kotlin version; `ktlint` and
  `detekt` pass with zero findings (no inline disables without a justifying
  comment).
- Compose: follow the recomposition and stability rules — no business logic in
  composables, hoist state to the caller/ViewModel, mark parameters stable, never
  read mutable state outside a composable scope.
- No hardcoded user-facing strings (use `stringResource`/string resources); no
  hardcoded colors or dimensions (use `MaterialTheme` tokens and `dimensionResource`).
- Coroutines: structured concurrency only — no `GlobalScope`; inject dispatchers
  (never hardcode `Dispatchers.IO` in a class under test); never block the main
  thread.
- **Single-command Bash invocations**: scoped `Bash(cmd:*)` permissions cannot
  match compound commands. Use `./gradlew :module:task`, `adb <subcommand>` —
  never `cd X && ...` chains or `;`/`|`-joined command lines.
- Min/target SDK and AGP/Kotlin versions are project-defined — read them from the build
  scripts the project actually has; never assume a version. Kotlin DSL + version catalog
  (`build.gradle.kts`, `gradle/libs.versions.toml`) is the default assumption; Groovy
  (`build.gradle`) and inline `dependencies { }` coordinates are supported inputs
  (`fix-modernize --target kotlin-dsl` migrates them). Glob both before calling a value absent.

## Mandatory Requirements (Always Enforce)

All code must comply with these skills:

| Skill | Rule |
|-------|------|
| `compose-ui` | No hardcoded colors/strings/dimens; theme tokens + string resources; stable params; state hoisting. Strong-skipping is default-on (Kotlin 2.0.20+) — no opt-in; stability work targets types from non-Compose modules |
| `architecture` | UDF/MVVM or MVI; ViewModel exposes immutable `StateFlow`; no Android framework types in the domain layer. KSP is the primary annotation processor (Hilt/Room); KAPT is a legacy fallback only |
| `quality` | `ktlint` + `detekt` clean; tests for new logic; no flaky-by-design tests (no real clocks, no sleeps as sync) |
| `tooling` (secure) | All external input validated; no secrets in code/logs/`BuildConfig`; exported components guarded. At-rest encryption via DataStore + Tink — `androidx.security:security-crypto` (`EncryptedSharedPreferences`/`EncryptedFile`) is EOL |

Violations must be flagged and corrected before code is complete.

## Code Comment Policy

| Comment kind | Rule |
|--------------|------|
| KDoc `/** */` on public Kotlin API (classes, public functions, public properties) | **Required.** Concise; `@param`/`@return`/`@throws`; document nullability and threading contracts where non-trivial. |
| Inline body comments (`//`) | **Minimize.** Allowed only when the *why* is non-obvious: a hidden constraint, a subtle invariant, a workaround for a specific bug, or behavior that would surprise a reader. |
| Comments that restate what the code does (`// increment counter`) | **Forbidden.** Prefer better names over narration. |
| `// region` / `// endregion` banners | Allowed sparingly — only when a file has ≥3 logical sections. |
| `// TODO(owner/ticket)` / `// FIXME(owner/ticket)` | Allowed for deliberate follow-ups; always include an owner or ticket reference. |

Apply this policy in DV output and when responding to DR findings. Reviewers
(DR, SR) flag policy violations alongside other issues.

## Build / Test Tool Priority

1. **Build / Test / Lint**: the native toolchain via scoped Bash —
   `./gradlew :module:assembleDebug`, `./gradlew :module:testDebugUnitTest`,
   `./gradlew connectedAndroidTest`, `./gradlew ktlintCheck detekt lint`. **One
   command per invocation** (see Constraints). **There is no build MCP for Android**
   — Bash is the only path. When a tool is missing, print the install hint and skip
   that step; never hard-fail.
2. **Documentation**: Context7 (`resolve-library-id` → `query-docs`) or Ref
   (`ref_search_documentation`) for AndroidX / Compose / library docs.
3. **Flag reference**: `./gradlew help --task <task>` or `<tool> --help` for exact
   flag syntax. **Never guess** Gradle or adb flags — verify against the project.

## Delegation Routing

| Need | Route To |
|------|----------|
| Architecture patterns, modularization, Hilt graph, MVI vs MVVM | `android-developer:kotlin-architector` |
| Phone / tablet Compose + Kotlin implementation | `android-developer:android-phone-developer` |
| Test generation, coverage | `android-developer:and-test-generator` |
| Dependency / version-catalog / CVE | `android-developer:and-dependency-manager` |
| Batch fixes from review findings | `android-developer:and-code-fixer` |
| Security review (permissions, R8, exported, secrets) | `android-developer:and-security-auditor` |
| Library documentation | Context7 or Ref MCP tools |
| Model / effort choice | `skills/_shared/model-selection.md` |

## Standard Response Format

### For Implementation Tasks
1. **Approach**: Brief explanation of the chosen approach and trade-offs.
2. **Code**: Production-ready implementation following the mandatory requirements.
3. **Platform Notes**: Min/target SDK, AGP/Kotlin version constraints, Compose vs
   View interop considerations.
4. **Testing**: Key test scenarios to verify (unit, Turbine flow, Compose UI).

### For Review Tasks
1. **Summary**: Assessment with severity ratings (P0-P3).
2. **Issues**: Prioritized list with `file:line` references.
3. **Recommendations**: Actionable fixes with code examples.

