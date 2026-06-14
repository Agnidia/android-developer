# DR Support / Fix-Routing Template

When technical-lead (`igrsoft:technical-lead`) returns DR findings, android-developer
agents apply them:

```
Task(android-developer:code-fixer) {
  prompt: "Apply these DR findings to <module>, minimal diff, build-gate after each group:
    1. <finding — file:line — fix>
    2. ...
   Re-run `./gradlew :<module>:assembleDebug` then the changed-scope tests after each group.
   Record per-finding resolution in .context/errors/code-fixer.md."
}
```

- Mechanical findings (ktlint/detekt) → `code-fixer` (auto-fix first).
- Findings that need a design change (module graph, pattern) → `kotlin-architector`.
- Re-run `./gradlew test ktlintCheck detekt` (single scoped commands) after each fix
  group; report each cycle.
