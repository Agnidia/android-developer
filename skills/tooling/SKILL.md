---
name: tooling
description: Android Gradle tooling: version catalogs, convention plugins, build performance, R8/ProGuard, and the Android CLI (adb/apkanalyzer). Use when configuring the build, speeding it up, or shrinking the release.
license: Apache-2.0
metadata:
  author: IGRSoft
  last-updated: '2026-06-15'
  keywords: [gradle, version-catalog, convention-plugin, build-perf, r8, proguard, adb, ksp]
---

# Tooling (domain index)

Thin router for the tooling skill domain.

| Skill | Use when |
|-------|----------|
| [gradle-build](gradle-build/SKILL.md) | Version catalogs, convention plugins, build perf, R8/ProGuard, adb/apkanalyzer |

## Core principle

The build is configuration, not code: centralize versions in `gradle/libs.versions.toml`
(BOM-driven, dated pins), share logic via convention plugins, prefer KSP (KSP2) over KAPT,
and keep the release build shrunk and obfuscated with R8 full mode. Build commands run
through the Gradle wrapper as single scoped invocations.

## Attribution

Synthesized by IGRSoft from community tooling references (`new-silvermoon`) blended with
patterns from Google's official `android/skills` (**Apache License 2.0 — Google
android/skills**). Licensed Apache-2.0; no content copied verbatim.
