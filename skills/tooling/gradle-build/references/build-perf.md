# Build Performance

`gradle.properties`:

```
org.gradle.caching=true
org.gradle.parallel=true
org.gradle.configuration-cache=true   # stable / expected as of 2026-06
org.gradle.jvmargs=-Xmx4g -XX:+UseParallelGC
ksp.useKSP2=true                      # KSP2, required for Kotlin 2.2+
```

- Prefer `ksp` over `kapt` (KAPT is the legacy fallback); enable KSP2 (`ksp.useKSP2=true`).
- Avoid unnecessary `api` dependencies (they widen the recompile graph) — use
  `implementation`.
- Keep modules cohesive so an edit rebuilds the minimum set.
- Measure before tuning: `./gradlew assembleDebug --scan` (build scan) and `--profile`.

## Attribution
Synthesized by Agnidia from `new-silvermoon`, Google `android/skills` (Apache License 2.0).
Apache-2.0. No verbatim copying.
