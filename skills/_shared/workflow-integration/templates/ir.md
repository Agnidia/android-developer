# IR Stage Hotfix Template (Android)

For the `emergency:` workflow trigger. android-developer agents implement hotfixes under
expedited, minimal-diff constraints.

## Constraints
- **Minimal changes only** — touch only the necessary code; no refactors.
- **No new features** — fix the issue, nothing else.
- **Feature flags / remote config** — gate the fix for fast rollback where possible.
- **Expedited review** — P0/P1 reviewed within 24-48h.

## Output Frontmatter

```yaml
---
handoff:
  stage: IR
  verdict: ok            # ok | blocked | escalate
  summary: "<hotfix — ≤200 chars>"
  files_touched:
    - path/to/Fix.kt
  next_stage_focus: "DV/DR: verify minimal diff, no scope creep; QA: regression on <area>"
  refs:
    incident: incident-0.md#root-cause
---
```

Verify: `./gradlew :<module>:assembleRelease` builds; the regression test for the incident
passes; R8 mapping retained for crash de-obfuscation.
