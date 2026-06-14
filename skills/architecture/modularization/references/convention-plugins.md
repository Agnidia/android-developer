# Gradle Convention Plugins

Centralize repeated build configuration in an included `build-logic` build so module
build files stay tiny.

```kotlin
// build-logic/convention/src/main/kotlin/AndroidFeatureConventionPlugin.kt
class AndroidFeatureConventionPlugin : Plugin<Project> {
    override fun apply(target: Project) = with(target) {
        pluginManager.apply("com.android.library")
        pluginManager.apply("org.jetbrains.kotlin.android")
        // shared compileSdk, Compose, Kotlin options, common deps ...
    }
}
```

```kotlin
// feature/x/build.gradle.kts
plugins { id("myapp.android.feature") }
```

This removes per-module drift (different compileSdk, missing Compose setup) and makes a
toolchain bump a one-file change.

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, Google `android/skills`-style build
conventions (Apache-2.0 patterns, re-described). No verbatim copying.
