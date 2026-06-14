# DR Review Criteria & Output Template (Android)

technical-lead reviews `development-N.md` against Android criteria and writes
`developer-review-N.md`.

## Review Criteria

| Area | Pass condition |
|------|----------------|
| Compose stability | Stable params; state hoisted; no logic in composables; keys on lazy items; no allocation in composition |
| Coroutine discipline | No `GlobalScope`; injected dispatchers; lifecycle-aware collection; no main-thread blocking |
| Architecture purity | No Android types in `domain`; immutable `StateFlow` from ViewModel; dependency direction inward |
| Resource externalization | No hardcoded strings/colors/dimens |
| Lint hygiene | 0 ktlint + 0 detekt findings; suppressions justified |

## Output Frontmatter

```yaml
---
handoff:
  stage: DR
  verdict: pass          # pass | fail
  summary: "<assessment — ≤200 chars>"
  key_decisions:         # = findings
    - { id: f1, summary: "<finding>", anchor: "developer-review-0.md#findings" }
  refs:
    development: development-0.md#files-changed
---
```

On `verdict: fail`, write a `## blockers` list of concrete, individually-actionable
strings; the orchestrator forwards them verbatim as `metadata.gate_blockers[]`.
