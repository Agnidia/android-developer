---
description: Run ktlint, detekt, and Android Lint in report mode, or auto-format and auto-correct Kotlin/Compose code
argument-hint: [path (default .)] [--check | --fix]
allowed-tools: Read, Edit, Glob, Grep, Bash
model: haiku
estimated-cost:
  min-tokens: 500
  max-tokens: 6000
  model-distribution:
    haiku: 90%
    sonnet: 10%
---

# Lint & Fix
<!-- Updated: June 2026 -->

Run the project's linters (ktlint, detekt, Android Lint) report-only, or apply their
auto-fixers. This is a shallow, deterministic pass — it never delegates to an agent.

[Extended thinking: A cheap haiku-model pass that runs the configured linters via the
Gradle wrapper and tees output. `--check` reports; `--fix` runs the auto-formatters then
re-checks. It does not attempt semantic fixes — deep findings are surfaced for
`/android-developer:review-code` or an agent, not silently rewritten here.]

## CRITICAL BEHAVIORAL RULES

1. **Shell-only, no delegation.** This is a mechanical pass; report findings, don't route.
2. **Single-command Bash invocations** via `./gradlew`.
3. **Tee to the log** at `.context/logs/lint-<timestamp>.log`.
4. **Tool-missing never hard-fails** — if a linter plugin is absent, note it and run the
   ones present.
5. **Never enter plan mode.**

## Usage

```bash
/android-developer:fix-quick .            # defaults to --check
/android-developer:fix-quick . --fix
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `path` | `.` | Project root holding `gradlew`. |
| `--check` | default | Report only: `./gradlew ktlintCheck detekt lint`. |
| `--fix` | off | Auto-fix: `./gradlew ktlintFormat` and detekt `--auto-correct`, then re-check. |

## Workflow

1. Confirm `path/gradlew`. Create `.context/logs/`; `LOG=".context/logs/lint-$(date +%Y%m%d-%H%M%S).log"`.
2. **`--check`**: `./gradlew ktlintCheck detekt lint 2>&1 | tee -a "$LOG"`. Report the
   finding counts.
3. **`--fix`**: `./gradlew ktlintFormat 2>&1 | tee -a "$LOG"` then
   `./gradlew detekt --auto-correct 2>&1 | tee -a "$LOG"`, then re-run `ktlintCheck detekt`
   to confirm zero remaining. Report what was auto-fixed and what remains (manual).
4. If a task is missing (no ktlint/detekt plugin), skip it, note it, run the rest.

## Tool Availability

| Missing | Hint |
|---------|------|
| ktlint Gradle plugin | Add `org.jlleitschuh.gradle.ktlint` or the official `ktlint` plugin. |
| detekt Gradle plugin | Add `io.gitlab.arturbosch.detekt`. |

## Output Format

```markdown
## Lint Report
**Mode:** check / fix
**Log:** .context/logs/lint-{timestamp}.log

| Linter | Findings | Auto-fixed | Remaining |
|--------|----------|------------|-----------|
| ktlint | N | M | N-M |
| detekt | N | M | N-M |
| Android Lint | N | 0 | N |

**Result:** CLEAN / {N} findings remain (run /android-developer:review-code for deep fixes)
```

## Error Handling

### No Gradle wrapper
```
Error: No ./gradlew found under {path}. Run from the project root.
```

## See Also
- `/android-developer:review-code` — semantic review and routed fixes for deep findings.
- `/android-developer:build-test` — build after fixing to confirm compilation.
- `skill: quality` — lint hygiene and the QA gate.
