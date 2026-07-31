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

## Workflow Stage Participation

android-developer agents participate in the company-workflow 11-stage workflow system
(v4.0.0+; canonical spec: `company-workflow:skills/worktask/references/handoff-protocol.md`).

### Handoff Contract (BINDING)

All cross-plugin invocations follow `skills/_shared/workflow-integration/SKILL.md`:
plan-file resolution (`task.metadata.plan_file` → newest `.context/planning-*.md`
glob), Required Inputs, pre-flight Verification, output frontmatter schema
(≤30 lines, ≤200 tokens), state.json atomic write, and the per-stage required
`metadata.*` matrix.

**state.json patching is REQUIRED before returning** — but do NOT hand-roll a
`jq` or manual read→merge→rename. Use company-workflow's single, lock-serialized
implementation, or skip and let the safety-net layers repair the ledger from
your frontmatter:

- **Primary (script)**: when the dispatching prompt or
  `task.metadata.state_patch_script` supplies the path to company-workflow's
  `state-patch.sh` (it ships in the company-workflow plugin under
  `skills/worktask/scripts/`), run `bash <path>/state-patch.sh --stage <CODE>
  --prev <PREV>`. It parses this artifact's `handoff:` frontmatter and atomically
  merges `stages.<CODE>` plus the `<PREV>→<CODE>` handoff edge into
  `.context/state.json` — single implementation, lock-serialized, idempotent.
- **Degrade (silent skip)**: if no script path was supplied, or `jq`/`state.json`
  is absent, skip — do NOT reconstruct the merge inline. The orchestrator's
  post-stage re-read (Layer 2) and company-workflow's SubagentStop `state-merge.sh` hook
  (Layer 3) repair the ledger from your frontmatter.

**Frontmatter emission is therefore unconditional**: an artifact without
`handoff:` YAML breaks the entire three-layer safety net (agent self-patch →
orchestrator re-read → SubagentStop hook).

**Artifact filenames use the numbered `<stage>-N.md` contract** (`N = run_index`,
allocated by PL0 and propagated via `task.metadata.run_index`; e.g.
`development-0.md`). The basenames are canonical; only the `-N` suffix changes.
Readers fall back to newest-glob (`<basename>-*.md`).

### DV Stage (Development) — Android notes

- Implement features in Kotlin / Compose under the Constraints above.
- Run only the tests covering changed files —
  `./gradlew :module:testDebugUnitTest --tests <FullyQualifiedClass>`. Full-suite
  regression belongs to QA.
- Include a security-surface summary in `.context/development-N.md` for DR and SR.
- On retry, append the narrative to `.context/errors/{agent-basename}.md`.
- **Evidence gate**: Android/Compose work defaults `requires_screenshots: false` —
  PL0 should set it explicitly, and DV writes the skip-rationale manifest
  (`> Skipped: metadata.requires_screenshots = false. Rationale: <one line>`). When
  the gate is armed (`metadata.requires_screenshots: true`), capture `./gradlew`
  build/test output and `adb logcat` / `adb shell screencap` transcripts as
  `source: cli-fallback` rows (manifest `source` column: `cli-fallback`) in
  `.context/images/<worktask_id>/screenshots.md` before returning — else company-workflow's
  `dv-screenshot-gate.sh` blocks `SubagentStop`.
- **Consuming rework remediation**: on a re-dispatch after a failed DR/QA gate
  (`metadata.retry_count > 0`), read the prepended `REMEDIATION (from <DR|QA> gate…)`
  block plus `metadata.gate_from_stage` + `metadata.gate_blockers[]`, and fix those
  exact findings first (do not re-scope). Keep the diff minimal; record per-blocker
  resolution in `.context/errors/{agent-basename}.md`.

### Output Budget (DV)

`development-N.md` ≤250 lines; no full-file listings — cite `path:line-range` or
pass anchors, not pasted bodies (generated code lives in the repo, not the
artifact). Final return ≤250 tok (inside the ≤500 template). Target ≤80 tool
calls/run: batch multi-file edits into one edit pass, never re-Read a file
unchanged since your last Read (trust the buffer), re-run only scoped tests
(`./gradlew test --tests <pattern>`, a single connected/instrumented class where a
device is available — failed subset first), and keep narration lean — no per-file
play-by-play, no restating what the artifact already holds. **Build Evidence is
exempt from every cap here**: the Kotlin/AGP version line, the ktlint/detekt
finding counts, and the `.context/logs/` test-transcript path stay mandatory
(§ DV Stage) — never trim them to save lines or tokens.

### DR Stage (Developer Review) — Provide Context

Technical-lead (`company-workflow:technical-lead`) reviews DV output against Android-specific
criteria (Compose stability/recomposition, coroutine discipline, architecture-layer
purity, lint hygiene, resource externalization). android-developer agents support
DR by:

- Flagging known trade-offs in `development-N.md` under a "DR Focus" section.
- Responding to DR findings by routing to `android-developer:and-code-fixer` (minimal-
  diff application) or `android-developer:kotlin-architector` (pattern consult).
- Re-running `./gradlew test ktlintCheck detekt` (single scoped commands) after each
  fix group.
- **Gate-feedback**: DR writes a `## blockers` list of concrete, individually-
  actionable strings; the orchestrator forwards it verbatim as
  `metadata.gate_blockers[]` (with `gate_from_stage: "DR"`) on the DV re-dispatch.

See `skills/_shared/workflow-integration/templates/dr-review.md`.

### SR Stage (Security Review) — Provide Context

Document Android-specific security concerns:

| Area | Documentation Required |
|------|------------------------|
| **Permissions** | Declared (`AndroidManifest.xml`) and runtime-requested permissions; each justified; no over-broad grants |
| **Exported Components** | `android:exported` audited; intent filters validated; no implicitly exported activities/services/receivers |
| **Secrets** | No API keys in code, `BuildConfig`, resources, or logs; credential sources documented (Keystore / DataStore + Tink — not the EOL `security-crypto`) |
| **Data Protection** | DataStore + `datastore-tink` (Keystore-backed) for sensitive at-rest data — `EncryptedSharedPreferences`/`EncryptedFile` are EOL; `network-security-config` pins/clear-text policy; no PII in logs |
| **R8 / ProGuard** | Release obfuscation/shrinking enabled; no `debuggable true` in release; keep-rules minimal and justified |

### RE Stage (Release Engineering) — Provide Context

| Item | Provide |
|------|---------|
| **Version** | `versionCode` / `versionName`; module/library coordinates if published |
| **Distribution** | Play (internal/closed/open/production), APK/AAB, or internal channel |
| **Platform Notes** | Min/target SDK, signing config, ABI splits, R8 mapping retention |
| **What's New** | Android-specific release notes |

### IR Stage (Emergency) — Hotfix Constraints

For the `emergency:` workflow trigger:
- **Minimal changes only** — touch only the necessary code.
- **No new features** — fix the issue, nothing else.
- **Use feature flags / remote config** — enable rollback where possible.
- **Expedited review** — available for P0/P1 (24-48h).
