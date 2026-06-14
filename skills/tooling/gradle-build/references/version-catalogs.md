# Version Catalogs

`gradle/libs.versions.toml` is the single source of truth for dependency and plugin
versions.

- `[versions]` — named version constants; `[libraries]` — coordinates with `version.ref`;
  `[plugins]` — plugin ids; `[bundles]` — groups of libraries applied together.
- Reference in build files as `libs.<alias>` (dots in aliases become camelCase accessors).
- No inline versions, no dynamic versions (`+`, `latest.release`). Use BOMs for aligned
  families (Compose, Firebase, OkHttp).

## Attribution
Synthesized by IGRSoft from `new-silvermoon`, Google `android/skills` (Apache License 2.0).
Apache-2.0. No verbatim copying.
