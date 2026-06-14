# DV Stage Frontmatter Template

Copy this block to the top of `.context/development-N.md` (`N = run_index`; e.g.
`development-0.md`):

```yaml
---
handoff:
  stage: DV
  verdict: ok            # ok | blocked | escalate
  summary: "<what was implemented — ≤200 chars>"
  files_touched:         # REQUIRED for DV
    - path/to/Screen.kt
  next_stage_focus: "<hint for DR/QA — ≤240 chars>"
  key_decisions: []
  open_questions: []
  screenshots:           # required only when metadata.requires_screenshots != false
    manifest: .context/images/<worktask_id>/screenshots.md
    captured:
      - name: "<surface name>"
        path: .context/images/<worktask_id>/<file>.txt
        source: cli-fallback        # cli-fallback for Gradle/adb transcript evidence
  remediation_consumed: []   # rework only (metadata.retry_count>0): gate_blockers[] addressed
  refs:
    plan: planning-0.md#requirements
    decisions: analyzing-0.md#decisions
---
```

- **Android default is `metadata.requires_screenshots: false`.** Omit the
  `screenshots:` block and write the skip-rationale manifest
  (`> Skipped: metadata.requires_screenshots = false. Rationale: <one line>`). Only when
  the gate is armed (`true`) must the manifest at
  `.context/images/<worktask_id>/screenshots.md` exist before returning, with
  `source: cli-fallback` transcript rows — else `dv-screenshot-gate.sh` blocks
  `SubagentStop`. Full manifest format: `templates/dv-screenshots.md`.
- `remediation_consumed:` is populated only on a rework re-dispatch — list the
  `metadata.gate_blockers[]` strings (from the DR/QA gate) that this run fixed. See
  `workflow-integration/SKILL.md § Gate-Feedback Contract`.
