# Convention Plugins

Extract repeated build setup into an included `build-logic` build so each module's build
file is a few lines.

```kotlin
// build-logic/convention/.../AndroidLibraryConventionPlugin.kt
class AndroidLibraryConventionPlugin : Plugin<Project> {
    override fun apply(target: Project) = with(target) {
        pluginManager.apply("com.android.library")
        pluginManager.apply("org.jetbrains.kotlin.android")
        extensions.configure<LibraryExtension> { compileSdk = 35 /* shared config */ }
    }
}
```

Apply with `plugins { id("myapp.android.library") }`. One change updates every module —
no per-module drift.

## Attribution
Synthesized by IGRSoft from `new-silvermoon`, Google `android/skills` (Apache License 2.0).
Apache-2.0. No verbatim copying.
