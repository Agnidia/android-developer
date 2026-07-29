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
| `--check` | default | Report only: the subset of `ktlintCheck` / `detekt` / `lint` the project actually defines (see Workflow step 2). |
| `--fix` | off | Auto-fix: `./gradlew ktlintFormat` and detekt `--auto-correct` where those tasks exist, then re-check. |

## Workflow

1. Confirm `path/gradlew`. Create `.context/logs/`; `LOG=".context/logs/lint-$(date +%Y%m%d-%H%M%S).log"`.
2. **Select the tasks that exist.** `./gradlew tasks --all`, then keep only those of
   `ktlintCheck` / `detekt` / `lint` it lists. Gradle aborts the **whole** invocation on the
   first unknown task, so a hardcoded `ktlintCheck detekt lint` on a project without detekt
   runs *nothing* — this step is what makes rule 4 work.
3. **`--check`**: run the step-2 tasks as one command, those names only
   (`./gradlew ktlintCheck lint 2>&1 | tee -a "$LOG"`). Report the finding counts.
4. **`--fix`**: `./gradlew ktlintFormat` then `./gradlew detekt --auto-correct` — each only
   if that task exists — teeing to `$LOG`; re-run the step-2 check tasks to confirm zero
   remaining. Report what was auto-fixed and what remains (manual).
5. Name every linter skipped for absence: one that never ran is not one that found nothing.

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
| detekt | not configured — skipped | — | — |
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
