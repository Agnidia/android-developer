# Build Performance

`gradle.properties`:

```
org.gradle.caching=true
org.gradle.parallel=true
org.gradle.configuration-cache=true
org.gradle.jvmargs=-Xmx4g -XX:+UseParallelGC
```

- Prefer `ksp` over `kapt`.
- Avoid unnecessary `api` dependencies (they widen the recompile graph) — use
  `implementation`.
- Keep modules cohesive so an edit rebuilds the minimum set.
- Measure before tuning: `./gradlew assembleDebug --scan` (build scan) and `--profile`.

## Attribution
Synthesized by IGRSoft from `new-silvermoon`, Google `android/skills` (Apache License 2.0).
Apache-2.0. No verbatim copying.
