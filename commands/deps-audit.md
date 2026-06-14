---
description: Audit the Gradle version catalog for outdated and CVE-affected dependencies, optionally applying safe one-at-a-time upgrades
argument-hint: [path (default .)] [--fix] [--cve-only]
allowed-tools: Read, Edit, Glob, Grep, Bash
model: haiku
---

# Dependency Audit (Android)
<!-- Updated: June 2026 -->

Parse `gradle/libs.versions.toml`, report outdated and CVE-affected coordinates, and —
with `--fix` — delegate safe, one-at-a-time upgrades to `dependency-manager`.

[Extended thinking: A cheap haiku pass over the version catalog. It surfaces available
updates and known CVEs; `--fix` routes the actual bumping (one entry at a time, behind a
build+test gate) to `dependency-manager` so the upgrade discipline lives in the agent, not
the command.]

## CRITICAL BEHAVIORAL RULES

1. **Catalog is the source of truth.** Audit `gradle/libs.versions.toml`, not scattered
   inline versions.
2. **One agent for fixes.** `--fix` routes to `android-developer:dependency-manager`.
3. **Single-command Bash invocations** (`./gradlew dependencyUpdates`, `osv-scanner`).
4. **Tool-missing never hard-fails** — if `osv-scanner` is absent, report from the
   versions plugin alone and note the gap.
5. **Never enter plan mode.**

## Usage

```bash
/android-developer:deps-audit .
/android-developer:deps-audit . --cve-only
/android-developer:deps-audit . --fix
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `path` | `.` | Project root holding `gradle/libs.versions.toml`. |
| `--fix` | off | Route safe upgrades to `dependency-manager`. |
| `--cve-only` | off | Report only CVE-affected coordinates, not all outdated ones. |

## Workflow

1. Read `gradle/libs.versions.toml` (`[versions]`, `[libraries]`, `[plugins]`, `[bundles]`).
2. **Outdated:** `./gradlew dependencyUpdates 2>&1 | tee -a "$LOG"` (versions plugin) if
   present; otherwise compare against Context7/Ref for current releases.
3. **CVEs:** `osv-scanner --lockfile=... 2>&1 | tee -a "$LOG"` over the catalog/lockfile
   (OSV aggregates GitHub Advisory / NVD). Also flag **EOL/deprecated coordinates** with no
   bump target — notably `androidx.security:security-crypto` (EOL at 1.1.0 → migrate to
   DataStore + `androidx.datastore:datastore-tink`) and SafetyNet/Smart Lock (→ Play
   Integrity / Credential Manager); route these to `security-auditor` rather than a version bump.
4. **`--fix`:**
   **Use Task tool with subagent_type="android-developer:dependency-manager"**
   Prompt: "Upgrade these catalog entries one at a time, build+test gate after each, revert
   any bump that breaks the build:\n{list}\nFlag any major-version migration for the
   implementer. Update `gradle/libs.versions.toml` only."
5. Report outdated, CVE-affected, and (with `--fix`) what was upgraded.

## Output Format

```markdown
## Dependency Audit
**Catalog:** gradle/libs.versions.toml  **Log:** .context/logs/deps-{ts}.log

| Coordinate | Current | Latest | CVE / Status |
|------------|---------|--------|--------------|
| okhttp | 5.2.0 | 5.3.0 | — |
| androidx.security:security-crypto | 1.1.0 | — | EOL → DataStore + Tink |

**Totals:** {n} outdated, {n} with CVEs, {n} EOL/deprecated
<!-- with --fix: -->
**Upgraded:** {n} (delegated to dependency-manager); majors flagged: {list}
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
