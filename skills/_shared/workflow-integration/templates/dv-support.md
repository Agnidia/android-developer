# DV Support Routing Template

The `android-developer` router uses this when forwarding DV work to a specialist.

```
Task(android-developer:android-phone-developer) {
  metadata:
    agent: "android-developer:android-phone-developer"
    model: "sonnet"
    error_file: ".context/errors/android-phone-developer.md"
    plan_file: "<resolved plan file>"
    run_index: <N>
    requires_screenshots: <pass-through, default false>
    # rework only:
    gate_from_stage: "<DR|QA>"
    gate_blockers: ["<verbatim blocker>", ...]
}
```

Routing rules:
- Compose/Kotlin feature implementation → `android-phone-developer`.
- Architecture / module-graph / Hilt design → `kotlin-architector`.
- Test scaffolding → `test-generator`.
- Forward all gate/screenshot/rework metadata **unchanged** — the router relays, it
  does not consume or rewrite. After return, run the Return Verification (BINDING)
  contract before reporting to the orchestrator.
