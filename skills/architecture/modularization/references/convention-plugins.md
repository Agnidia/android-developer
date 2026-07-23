# Gradle Convention Plugins

Centralize repeated build configuration in an included `build-logic` build so module
build files stay tiny.

```kotlin
// build-logic/convention/src/main/kotlin/AndroidFeatureConventionPlugin.kt
class AndroidFeatureConventionPlugin : Plugin<Project> {
    override fun apply(target: Project) = with(target) {
        pluginManager.apply("com.android.library")
        pluginManager.apply("org.jetbrains.kotlin.android")
        // set the shared compileSdk from ONE project-defined source (a catalog value or a
        // build-logic constant — current Android stable, e.g. 36 as of 2026-06), plus the
        // shared Compose, compilerOptions {}, and common deps ...
    }
}
```

```kotlin
// feature/x/build.gradle.kts
plugins { id("myapp.android.feature") }
```

This removes per-module drift (a different `compileSdk` per module, missing Compose setup)
and makes a toolchain bump a one-file change. Read `compileSdk` from a single shared source
so no literal is duplicated across modules.

## Attribution
Synthesized by IGRSoft (Apache-2.0) from `new-silvermoon`, Google `android/skills`-style build
conventions (Apache-2.0 patterns, re-described). No verbatim copying.
