# Version Catalogs

`gradle/libs.versions.toml` is the single source of truth for dependency and plugin
versions.

- `[versions]` — named version constants; `[libraries]` — coordinates with `version.ref`;
  `[plugins]` — plugin ids; `[bundles]` — groups of libraries applied together.
- Reference in build files as `libs.<alias>` (dots in aliases become camelCase accessors).
- No inline versions, no dynamic versions (`+`, `latest.release`). Use BOMs for aligned
  families (Compose, Firebase, OkHttp).

```toml
[versions]
kotlin = "2.3.21"                     # as of 2026-06
compose-bom = "2026.05.00"            # latest stable as of 2026-06

[libraries]
compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "compose-bom" }
compose-ui = { group = "androidx.compose.ui", name = "ui" }   # version from the BOM

[plugins]
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }
compose-compiler = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
```

```kotlin
// build.gradle.kts — BOM aligns the family; member libs need no version
implementation(platform(libs.compose.bom))
implementation(libs.compose.ui)
```

- **The Compose Compiler is a Kotlin plugin** (`org.jetbrains.kotlin.plugin.compose`,
  `version.ref = "kotlin"`) — it is **not** part of the Compose BOM and follows the Kotlin
  release cadence, not the BOM coordinate.
- Bump the BOM (one line) to move the whole Compose family; pinned literals carry a date stamp
  so staleness is visible (`# latest stable as of 2026-06`).

## Attribution
Synthesized by IGRSoft from `new-silvermoon`, Google `android/skills` (Apache License 2.0).
Apache-2.0. No verbatim copying.
