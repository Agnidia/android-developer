---
name: model-selection
description: Model and effort selection for android-developer agents — cost tiers, per-agent assignments, and opus+xhigh override paths. Reference when delegating to or overriding an android-developer specialist.
effort: low
---

# Model & Effort Selection (android-developer)

Companion to igrsoft's `skills/shared/model-selection.md`. This file pins the
**android-developer** per-agent assignments and the override paths the agents
expose. Frontmatter in `agents/*.md` is the source of truth — keep this table in
sync with it.

## Cost Tiers

| Model | Relative Cost | Use For |
|-------|---------------|---------|
| **haiku** | 1x (baseline) | Mechanical remediation, dependency operations, formatting |
| **sonnet** | ~10x haiku | Implementation, review, test generation, routing |
| **opus** | ~50x haiku | Architecture selection, deep threat analysis |

## Effort Levels

`low` ○, `medium` ◐, `high` ●, `xhigh` ⬣.

- `xhigh` is honored **only on Opus** — Sonnet/Haiku silently fall back to `high`,
  so raising effort without raising the model is a no-op.
- Reserve `xhigh` for the hardest long-chain reasoning (architecture trade-offs,
  module-graph design, deep threat modeling).

## Per-Agent Assignment

| Agent | Model | Effort | maxTurns | Override path |
|-------|-------|--------|----------|---------------|
| `android-developer` (router) | sonnet | medium | 40 | — routes work to specialists |
| `android-phone-developer` | sonnet | high | 50 | → `opus` + `xhigh` for novel, cross-module design |
| `kotlin-architector` | opus | xhigh | 50 | already top tier; self-limits scope at Low complexity per § Complexity Triage |
| `and-test-generator` | sonnet | high | 50 | — sonnet sufficient for pattern work |
| `and-security-auditor` | sonnet | high | 50 | → `opus` + `xhigh` for deep threat modeling (review-only: `disallowed-tools: Write, Edit`) |
| `and-code-fixer` | haiku | medium | 30 | — deterministic minimal-diff remediation |
| `and-dependency-manager` | haiku | low | 30 | — mechanical version-catalog/CVE operations |

## Applying an Override

Pass `model`/`effort` on the `Task()` call (per-invocation; does not edit
frontmatter). Only override when complexity warrants it — the sonnet/high default
covers the overwhelming majority of Android work. `and-security-auditor` keeps its
`disallowed-tools: Write, Edit` restriction regardless of model: fixes route to
`android-developer:and-code-fixer`.
