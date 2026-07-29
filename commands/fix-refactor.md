---
description: Refactor Android/Kotlin code toward a target architecture pattern, build-gated after each incremental step
argument-hint: [target] [--pattern clean-arch|mvi|modularize] [--dry-run]
allowed-tools: Read, Glob, Grep, Bash, Edit
estimated-cost:
  min-tokens: 5000
  max-tokens: 25000
  model-distribution:
    haiku: 20%
    sonnet: 70%
    opus: 10%
---

# Code Refactor
<!-- Updated: June 2026 -->

Refactor existing Kotlin/Compose code toward a target architecture pattern. Consult
`kotlin-architector` for the plan, apply via `and-code-fixer`, and build-gate after each
incremental step — never a big-bang rewrite.

[Extended thinking: Refactoring is risk; this command makes it incremental and gated. It
asks the architect for an ordered, independently-shippable step plan, applies each step
through the fixer, and runs assemble+test between steps so a regression is caught at the
step that introduced it.]

## CRITICAL BEHAVIORAL RULES

1. **Incremental, build-gated.** One small step at a time; `./gradlew assembleDebug test`
   after each. Never apply the whole plan blind.
2. **Architect plans, fixer applies.** `kotlin-architector` produces the step plan;
   `and-code-fixer` applies each step.
3. **Single-command Bash invocations.**
4. **`--dry-run` prints the plan and stops** — no edits.
5. **Never enter plan mode** (the architect produces the plan, not CC plan mode).

## Usage

```bash
/android-developer:fix-refactor :feature:cart --pattern clean-arch
/android-developer:fix-refactor . --pattern modularize --dry-run
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `target` | required | Module/package to refactor. |
| `--pattern clean-arch\|mvi\|modularize` | required | Target pattern. |
| `--dry-run` | off | Print the step plan; make no edits. |

## Workflow

1. Read the target's current structure (`git ls-files`, the build files, the package tree).
2. **Consult the architect:**
   **Use Task tool with subagent_type="android-developer:kotlin-architector"**
   Prompt: "Produce an ordered, independently-shippable refactor plan to move `{target}`
   to `{pattern}`. Each step must build and pass tests on its own. Return the step list
   with the files each touches."
3. If `--dry-run`: print the plan and stop.
4. For each step, in order:
   - **Use Task tool with subagent_type="android-developer:and-code-fixer"** with the step's
     edits.
   - `./gradlew {target}:assembleDebug 2>&1 | tee -a "$LOG"` then the changed-scope tests.
   - On failure, stop, report, and ask the architect for a correction — do not proceed.

## Output Format

```markdown
## Refactor toward {pattern}
**Target:** {target}  **Plan steps:** {n}  **Log:** .context/logs/refactor-{ts}.log

| Step | Change | Build | Tests |
|------|--------|-------|-------|
| 1 | Extract domain models | ✅ | ✅ |

**Result:** COMPLETE ({n}/{n} steps) / STOPPED at step {k}
```

## Error Handling

### Build fails mid-plan
Stop at the failing step, report it, and route a correction request to
`android-developer:kotlin-architector`. Do not continue the plan.

## See Also
- `/android-developer:fix-modernize` — XML→Compose / View→Compose / Groovy→Kotlin-DSL migration.
- `skill: architecture` — pattern catalog and module strategy.
