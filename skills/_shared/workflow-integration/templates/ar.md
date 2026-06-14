# AR Stage Frontmatter Template

Copy to the top of `.context/analyzing-N.md` when `kotlin-architector` contributes
architecture consultation (`N = run_index`):

```yaml
---
handoff:
  stage: AR
  verdict: ok            # ok | blocked | escalate
  summary: "<architecture decision — ≤200 chars>"
  key_decisions:
    - { id: ad1, summary: "<pattern/module/Hilt decision>", anchor: "analyzing-0.md#decisions" }
  next_stage_focus: "<hint for TL/DV — ≤240 chars>"
  refs:
    plan: planning-0.md#requirements
    decisions: analyzing-0.md#decisions
---
```

android-developer AR contribution: pattern selection (MVVM vs MVI), module-graph
design (by-feature vs by-layer, convention plugins), Hilt component scoping, and the
dependency direction (always inward to `domain`). Record each decision with its
trade-off under `## decisions`.
