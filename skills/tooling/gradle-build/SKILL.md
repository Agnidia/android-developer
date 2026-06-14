---
name: gradle-build
description: Gradle build for Android: version catalogs (libs.versions.toml), convention plugins, build-performance tuning, R8/ProGuard shrinking, and the Android CLI (adb, apkanalyzer). Use when editing build files, fixing build speed, or configuring release shrinking.
license: Apache-2.0
metadata:
  author: IGRSoft
  last-updated: '2026-06-15'
  keywords: [gradle, version-catalog, convention-plugin, build-perf, r8, proguard, adb, apkanalyzer]
---

# Gradle Build (Android)

## Version catalogs

✅ Correct — versions in `gradle/libs.versions.toml`, referenced by alias:

```toml
[versions]
compose-bom = "2026.05.00"            # latest stable as of 2026-06
agp = "9.x"                           # AGP 9.x, current stable as of 2026-06
kotlin = "2.3.21"                     # as of 2026-06; Compose compiler plugin follows this
[libraries]
compose-bom = { group = "androidx.compose", name = "compose-bom", version.ref = "compose-bom" }
[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }
compose-compiler = { id = "org.jetbrains.kotlin.plugin.compose", version.ref = "kotlin" }
```

The Compose Compiler is a Kotlin plugin (`version.ref = "kotlin"`) — it is **not** in the
Compose BOM and follows the Kotlin cadence, not the BOM coordinate.

```kotlin
// build.gradle.kts
implementation(platform(libs.compose.bom))
implementation(libs.compose.ui)
```

❌ Mistake — inline and dynamic versions:

```kotlin
implementation("androidx.compose.ui:ui:1.+")   // WRONG — inline + dynamic version
```

## Build performance

- `org.gradle.caching=true`, `org.gradle.parallel=true`, configuration cache
  (`org.gradle.configuration-cache=true`) in `gradle.properties`. The configuration cache is
  stable and expected as of 2026-06.
- Prefer `ksp` over `kapt` (faster annotation processing; KAPT is the legacy fallback). Enable
  **KSP2** with `ksp.useKSP2=true` in `gradle.properties` — required for Kotlin 2.2+.
- Configure Kotlin via the `compilerOptions {}` DSL (the old `kotlinOptions {}` block is
  error-level on Kotlin 2.2+):

  ```kotlin
  kotlin { compilerOptions { jvmTarget = JvmTarget.JVM_17 } }
  ```

- Modularize so changes rebuild fewer modules; avoid cross-module `api` leakage.
- Profile with `./gradlew assembleDebug --scan` / `--profile`.

## R8 / ProGuard

Release builds shrink, obfuscate, and optimize:

```kotlin
buildTypes {
    release {
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}
```

Keep-rules minimal (only reflection/serialization entry points); retain the mapping file
for crash de-obfuscation; never `isDebuggable = true` in release.

## Android CLI

- `adb install -r app.apk`, `adb logcat`, `adb shell am start`, `adb shell screencap`.
- `apkanalyzer apk file-size app.apk`, `apkanalyzer dex packages app.apk` for size audits.
- One command per invocation (scoped Bash) — no `cd`/`&&` chains.

## See also
- [references/version-catalogs.md](references/version-catalogs.md)
- [references/convention-plugins.md](references/convention-plugins.md)
- [references/build-perf.md](references/build-perf.md)
- [references/r8-proguard.md](references/r8-proguard.md)
- [references/android-cli.md](references/android-cli.md)

## Attribution

Synthesized by IGRSoft from `new-silvermoon` and Google's official `android/skills` build
guidance (**Apache License 2.0 — Google android/skills**). Licensed Apache-2.0; no content
copied verbatim.
