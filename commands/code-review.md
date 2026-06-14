---
description: Statically review Android/Kotlin code for Compose anti-patterns, coroutine misuse, and architecture violations, optionally routing fixes
argument-hint: [path (default .)] [--fix] [--severity P0|P1|P2|P3]
allowed-tools: Read, Glob, Grep, Bash, Edit
---

# Code Review (Android)
<!-- Updated: June 2026 -->

Statically review changed Kotlin/Compose code against Android best practices and report
findings by severity. With `--fix`, route mechanical findings to `code-fixer` and deep
structural findings to `kotlin-architector`.

[Extended thinking: A review pass that reads the diff, runs the linters for signal, and
classifies findings (Compose stability, coroutine discipline, architecture purity,
resource externalization, lint hygiene) by P0-P3. The happy path is read + report;
`--fix` delegates to exactly one agent per finding class. It does not blindly auto-edit.]

## CRITICAL BEHAVIORAL RULES

1. **Review first, fix second.** Default is report-only.
2. **One agent per finding class.** Mechanical → `android-developer:code-fixer`; structural
   → `android-developer:kotlin-architector`. Never fan out to several at once.
3. **Single-command Bash invocations** (`./gradlew ktlintCheck detekt`, `git diff`).
4. **Tee linter output** to `.context/logs/review-<timestamp>.log`.
5. **Severity-gated.** Honor `--severity` as the minimum reported level.
6. **Never enter plan mode.**

## Usage

```bash
/android-developer:code-review .
/android-developer:code-review app --fix --severity P1
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `path` | `.` | Project/module to review. |
| `--fix` | off | Route findings to the matching agent for application. |
| `--severity P0..P3` | P2 | Minimum severity to report. |

## Review Criteria (see `skill: severity-matrix`, `skill: compose-ui`, `skill: architecture`)

| Area | Looks for | Default severity |
|------|-----------|------------------|
| Compose stability | Unstable params (esp. types from non-Compose modules — strong-skipping is default-on), state read in wrong scope, missing keys, allocation in composition | P1 |
| Coroutine discipline | `GlobalScope`, hardcoded dispatcher, non-lifecycle collection, main-thread blocking | P1 |
| Architecture purity | Android types in `domain`, ViewModel → concrete data source, mutable state exposed | P1 |
| Resource externalization | Hardcoded strings/colors/dimens | P2 |
| Lint hygiene | ktlint/detekt findings, unjustified suppressions | P3 |
| Security surface | Implicitly exported component, secret in code, clear-text traffic, EOL `security-crypto`/`EncryptedSharedPreferences` (→ DataStore + Tink), dead SafetyNet/Smart Lock (→ Play Integrity / Credential Manager) | P0 |

## Workflow

1. Resolve the changed set (`git diff --name-only`); read those files.
2. Run `./gradlew ktlintCheck detekt 2>&1 | tee -a "$LOG"` for mechanical signal.
3. Read each changed Kotlin/Compose file against the criteria; record findings with
   `file:line`, severity, and a fix sketch.
4. **`--fix`**: route by class —
   - mechanical (ktlint/detekt, hardcoded resources, simple recomposition fixes):
     **Use Task tool with subagent_type="android-developer:code-fixer"** with the finding list.
   - structural (layer violation, module-graph, pattern change):
     **Use Task tool with subagent_type="android-developer:kotlin-architector"** with the finding list.
   Re-run `./gradlew :module:assembleDebug test` after each fix group.

## Output Format

```markdown
## Code Review
**Target:** {path}  **Min severity:** {--severity}  **Log:** .context/logs/review-{ts}.log

| # | Severity | Area | Location | Finding |
|---|----------|------|----------|---------|
| 1 | P1 | Compose | Screen.kt:42 | Unstable `List` param forces recomposition |

**Totals:** P0:{n} P1:{n} P2:{n} P3:{n}
<!-- with --fix: -->
**Routed:** {n} mechanical → code-fixer, {n} structural → kotlin-architector
```

## Error Handling

### No changes detected
Report "no changed Kotlin files vs base" and stop (nothing to review).

## See Also
- `/android-developer:lint-fix` — mechanical-only fast pass.
- `/android-developer:code-refactor` — apply a target pattern across the codebase.
- `skill: severity-matrix` — P0-P3 definitions.
