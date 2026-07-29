---
description: Identify, quantify, and prioritize Android technical debt across code, architecture, dependency, and test axes
argument-hint: [path (default .)] [--axis code|arch|deps|tests|all] [--top N]
allowed-tools: Read, Glob, Grep, Bash
estimated-cost:
  min-tokens: 5000
  max-tokens: 25000
  model-distribution:
    haiku: 20%
    sonnet: 60%
    opus: 20%
---

# Technical Debt Analysis
<!-- Updated: June 2026 -->

Inventory technical debt across an Android codebase, quantify each item's cost and risk,
and return a prioritized remediation queue. Read-only — this command produces the plan,
not the patch.

[Extended thinking: Debt analysis is worthless as an undifferentiated list of smells. The
value is ranking: which items actually slow the team down or carry release risk. So each
finding gets an estimated remediation effort and an impact, and the output is a queue
ordered by impact/effort — not a wall of findings. Android's highest-yield axes are the
module graph, Compose recomposition debt, deprecated/EOL libraries, and untested seams.]

## CRITICAL BEHAVIORAL RULES

1. **Read-only. This command NEVER edits.** `allowed-tools` deliberately excludes `Write`
   and `Edit`. Remediation routes to `/android-developer:fix-refactor`,
   `/android-developer:fix-modernize`, or `/android-developer:deps upgrade`.
2. **Quantify or drop it.** Every item carries an effort estimate and a concrete impact. A
   finding with neither is noise — leave it out.
3. **Rank, don't dump.** Output is ordered by impact/effort, truncated to `--top`.
4. **Single-command Bash invocations** (`git ls-files`, `./gradlew`, `cloc`).
5. **Tool-missing never hard-fails** — report from the axes that could be measured and name
   the gap.
6. **Never enter plan mode.**

## Usage

```bash
/android-developer:analyze-tech-debt .
/android-developer:analyze-tech-debt :feature:cart --axis arch
/android-developer:analyze-tech-debt . --axis all --top 10
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `path` | `.` | Module, package, or project root to analyze. |
| `--axis code\|arch\|deps\|tests\|all` | `all` | Restrict the inventory to one axis. |
| `--top N` | 15 | Cap the ranked queue. |

## Debt Axes

### Code debt (`--axis code`)
Duplication, long functions, deep nesting, god classes/ViewModels, poor naming, and
`TODO`/`FIXME`/`@Suppress` density. Android-specific: unstable Compose parameters and
allocation in composition (`skill: compose-best-practices`), hardcoded strings/colors/dimens
that should be resources, `!!` non-null assertions, blocking calls on the main thread,
`runBlocking` outside tests. Run `./gradlew detekt` for the mechanical signal and read the
top files for the structural ones. Thresholds come from `skill: severity-matrix` § Code
Smell Indicators.

### Architecture debt (`--axis arch`)
**Use Task tool with subagent_type="android-developer:kotlin-architector"**
Prompt: "Inventory architecture debt in `{path}` using `skill: architecture`. Report:
layer violations (Android types in `domain`, ViewModel bound to a concrete data source),
module-graph problems (feature→feature edges, cyclic or over-broad `api` dependencies,
missing `:core:` extraction), missing abstractions (repeated logic with no interface),
god modules, and boundaries with no test seam. Give each item a `file:line`, a remediation
sketch, and an effort estimate in developer-days."

### Dependency debt (`--axis deps`)
Outdated majors, CVE-affected coordinates, EOL/deprecated libraries with no bump target
(`androidx.security:security-crypto`, SafetyNet, Smart Lock), KAPT still in use where KSP2
applies, Groovy build scripts, and AGP/Kotlin/compileSdk lag. Reuse
`/android-developer:deps audit` for the catalog scan rather than re-implementing it.

### Test debt (`--axis tests`)
Coverage gaps on the seams the architecture depends on, unit-only modules with no
instrumented or screenshot coverage, flaky or `@Ignore`d tests, `Thread.sleep` in tests
instead of Turbine/idling, and slow suites. Framework matrix from
`skill: testing-principles`.

## Scoring

Each item gets:

| Field | Scale |
|-------|-------|
| **Impact** | High (blocks releases / recurring incidents / blocks a roadmap item) · Medium (slows change in a hot area) · Low (localized annoyance) |
| **Effort** | S (<1 day) · M (1-3 days) · L (1-2 weeks) · XL (>2 weeks) |
| **Risk of delay** | What gets worse if this is deferred one quarter |

Rank by impact/effort; break ties toward items that unblock other items.

## Output Format

```markdown
## Technical Debt: {path}
**Axes:** {code, arch, deps, tests}  **Items found:** {n}  **Shown:** top {N}

### Remediation Queue
| # | Item | Axis | Impact | Effort | Location | Remediate with |
|---|------|------|--------|--------|----------|----------------|
| 1 | `domain` depends on Android `Context` | arch | High | M | CartUseCase.kt:12 | `/android-developer:fix-refactor --pattern clean-arch` |
| 2 | `security-crypto` EOL, no bump target | deps | High | M | libs.versions.toml:41 | `/android-developer:fix-modernize --target api-modernize` |

### By Axis
| Axis | Items | High impact | Est. total effort |
|------|------:|------------:|-------------------|
| code | {n} | {n} | {days} |

### Deferred (below the cut)
{count} items ranked below the top {N}; re-run with a larger `--top` to see them.

### Coverage Notes
- {axis or tool that could not be measured, and why}
```

## Error Handling

### detekt / coverage tooling absent
Note it, analyze that axis by reading instead of measuring, and mark the axis
"unmeasured — qualitative only."

### Scope too large to read
Sample: rank modules by change frequency (`git log --format= --name-only | sort | uniq -c`)
and analyze the hottest ones first; report the sampling boundary explicitly.

## See Also
- `skill: severity-matrix` — smell thresholds and P0-P3 definitions.
- `/android-developer:arch-review` — the deeper single-pattern architecture pass.
- `/android-developer:fix-refactor`, `/android-developer:fix-modernize`,
  `/android-developer:deps upgrade` — where the queue items get executed.
