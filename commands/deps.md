---
description: Audit the Gradle version catalog for outdated, CVE, and EOL coordinates, or safely upgrade one at a time
argument-hint: <audit|upgrade> [path (default .)] [--cve-only] [--dry-run]
allowed-tools: Read, Edit, Glob, Grep, Bash
estimated-cost:
  min-tokens: 3000
  max-tokens: 18000
  model-distribution:
    haiku: 30%
    sonnet: 60%
    opus: 10%
---

# Dependency Lifecycle (audit / upgrade)
<!-- Updated: June 2026 -->

Two subcommands over `gradle/libs.versions.toml`:

- **`deps audit [path]`** — report outdated, CVE-affected, and EOL/deprecated coordinates.
  Read-only. See **Audit** below.
- **`deps upgrade [path]`** — delegate safe, one-at-a-time version bumps to
  `dependency-manager` behind a build+test gate. See **Upgrade** below.

**Dispatch**: parse the first token of `$ARGUMENTS`. If it is `upgrade`, run the Upgrade
workflow with the remaining args as scope. Otherwise (`audit`, or no subcommand) run the
Audit workflow — audit is the default.

[Extended thinking: The catalog is the single place versions live, so both modes read it
rather than chasing inline versions. Audit stays cheap and read-only; the risky part —
actually bumping — lives in `dependency-manager`, which owns the one-at-a-time,
gate-after-each discipline. Splitting the two by subcommand keeps a bare `/deps` safe.]

## CRITICAL BEHAVIORAL RULES

1. **Catalog is the source of truth.** Audit `gradle/libs.versions.toml`, not scattered
   inline versions.
2. **Audit mode is read-only.** `allowed-tools` includes `Edit` because `upgrade` needs it;
   the audit workflow MUST NOT modify files.
3. **One agent for upgrades.** `upgrade` routes to `android-developer:dependency-manager`.
4. **Single-command Bash invocations** (`./gradlew dependencyUpdates`, `osv-scanner`).
5. **Tool-missing never hard-fails** — if `osv-scanner` is absent, report from the
   versions plugin alone and note the gap.
6. **Never enter plan mode.**

## Usage

```bash
/android-developer:deps audit .
/android-developer:deps audit . --cve-only
/android-developer:deps .                    # no subcommand → audit
/android-developer:deps upgrade .
/android-developer:deps upgrade . --dry-run
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `audit` \| `upgrade` | `audit` | Subcommand; first token of `$ARGUMENTS`. |
| `path` | `.` | Project root holding `gradle/libs.versions.toml`. |
| `--cve-only` | off | Audit only: report CVE-affected coordinates, not all outdated ones. |
| `--dry-run` | off | Upgrade only: print the bump list; make no edits. |

## Audit (deps audit)

1. Read `gradle/libs.versions.toml` (`[versions]`, `[libraries]`, `[plugins]`, `[bundles]`).
2. **Outdated:** `./gradlew dependencyUpdates 2>&1 | tee -a "$LOG"` (versions plugin) if
   present; otherwise compare against Context7/Ref for current releases.
3. **CVEs:** `osv-scanner --lockfile=... 2>&1 | tee -a "$LOG"` over the catalog/lockfile
   (OSV aggregates GitHub Advisory / NVD).
4. **EOL/deprecated:** flag coordinates with no bump target — notably
   `androidx.security:security-crypto` (EOL at 1.1.0 → migrate to DataStore +
   `androidx.datastore:datastore-tink`) and SafetyNet/Smart Lock (→ Play Integrity /
   Credential Manager). Route these to `security-auditor` rather than a version bump.
5. Report outdated, CVE-affected, and EOL/deprecated counts. Make no edits.

## Upgrade (deps upgrade)

1. Run the Audit workflow to produce the candidate bump list.
2. If `--dry-run`: print the list and stop.
3. **Delegate:**
   **Use Task tool with subagent_type="android-developer:dependency-manager"**
   Prompt: "Upgrade these catalog entries one at a time, build+test gate after each, revert
   any bump that breaks the build:\n{list}\nFlag any major-version migration for the
   implementer. Update `gradle/libs.versions.toml` only."
4. Report what was upgraded, what was reverted, and which majors were flagged.

## Output Format

```markdown
## Dependency Audit
**Catalog:** gradle/libs.versions.toml  **Log:** .context/logs/deps-{ts}.log

| Coordinate | Current | Latest | CVE / Status |
|------------|---------|--------|--------------|
| okhttp | 5.2.0 | 5.3.0 | — |
| androidx.security:security-crypto | 1.1.0 | — | EOL → DataStore + Tink |

**Totals:** {n} outdated, {n} with CVEs, {n} EOL/deprecated
<!-- upgrade mode: -->
**Upgraded:** {n} (delegated to dependency-manager); reverted: {n}; majors flagged: {list}
```

## Error Handling

### No version catalog
```
Error: No gradle/libs.versions.toml under {path}.
Suggestion: Migrate inline versions to a version catalog first.
```

### osv-scanner missing
Note it, report from the versions plugin alone, and suggest `brew install osv-scanner`.

## See Also
- `skill: tooling` — version catalogs and BOMs.
- `/android-developer:build-test` — verify after upgrades.
- `/android-developer:fix-modernize` — `--target api-modernize` for major-version migrations.
