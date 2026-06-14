---
name: severity-matrix
description: Reusable severity and priority definitions for android-developer commands and agents
---

# Severity Matrix Reference

Shared definitions for severity levels, priority matrices, and effort/impact
assessments used by android-developer agents and commands.

## Severity Levels

| Level | Description | Response Time | Android Examples |
|-------|-------------|---------------|------------------|
| Critical | Security, data loss, crash-on-launch | Immediate | Exported component with no validation, hardcoded API key, ANR on main thread, data corruption in Room migration |
| High | Major functionality, leaks, jank | Within sprint | Activity/coroutine scope leak, unbounded recomposition jank, clear-text traffic, unchecked permission |
| Medium | Code quality, minor performance | Quarterly | Hardcoded string/color, `GlobalScope` usage, missing dispatcher injection, weak test coverage |
| Low | Style, nice-to-have | Opportunistic | ktlint formatting drift, naming, missing KDoc |

## Review Finding Priorities (P0-P3)

| Priority | Definition | Android Examples |
|----------|------------|------------------|
| P0 | Must fix before merge — correctness/security broken | Implicitly exported component, secret in code, main-thread blocking I/O, failing tests |
| P1 | Fix in this change — defect likely to bite | Leaked scope, recomposition storm, clear-text endpoint, `GlobalScope`, mutable state from a ViewModel |
| P2 | Should fix — quality/maintainability | Hardcoded resources, Android types in domain, magic numbers, weak coverage on changed code |
| P3 | Nice to have — style | Formatting, naming, KDoc polish (auto-fixable via ktlint/detekt) |

## Priority Matrix (impact × effort)

| Priority | Impact | Effort | Action |
|----------|--------|--------|--------|
| P0 | Critical | Any | Immediate remediation |
| P1 | High | Low | Do first (quick wins) |
| P2 | High | High | Plan and schedule |
| P3 | Medium | Low | Batch together |

## Code Smell Indicators

| Smell | Threshold | Impact |
|-------|-----------|--------|
| Long function | >30 lines (Kotlin) | Hard to test |
| Large composable | >1 screen of nesting / many responsibilities | Recomposition + readability |
| Cyclomatic complexity | >10 (detekt `ComplexMethod`) | Error-prone |
| Nesting depth | >3 levels | Reduced readability |
| Parameters | >5 (consider a data class / state holder) | Hard to use correctly |
| God ViewModel | >1 screen's worth of state/logic | Untestable, coupled |

## Coverage Requirements

| Scope | Minimum | Target |
|-------|---------|--------|
| Domain / use-cases | 90% | 95%+ |
| ViewModels / repositories | 75% | 80%+ |
| Utilities | 60% | 70%+ |
| UI (Compose) | smoke + key interactions | critical-path screenshot coverage |

## Usage

Reference this file in commands using:
```markdown
See: skills/_shared/severity-matrix.md for severity definitions
```
