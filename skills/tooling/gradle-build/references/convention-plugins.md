# Convention Plugins

Extract repeated build setup into an included `build-logic` build so each module's build
file is a few lines.

```kotlin
// build-logic/convention/.../AndroidLibraryConventionPlugin.kt
class AndroidLibraryConventionPlugin : Plugin<Project> {
    override fun apply(target: Project) = with(target) {
        pluginManager.apply("com.android.library")
        pluginManager.apply("org.jetbrains.kotlin.android")
        // Read the shared SDK level from one source (catalog/extra prop), not a literal —
        // current Android stable, e.g. 36 as of 2026-06.
        extensions.configure<LibraryExtension> {
            compileSdk = libs.findVersion("compileSdk").get().toString().toInt()
        }
    }
}
```

Apply with `plugins { id("myapp.android.library") }`. One change updates every module —
no per-module drift. Convention plugins also centralize the annotation processor: prefer
**KSP** (enable **KSP2** with `ksp.useKSP2=true`, required for Kotlin 2.2+) over KAPT.

## Attribution
Synthesized by IGRSoft from `new-silvermoon`, Google `android/skills` (Apache License 2.0).
Apache-2.0. No verbatim copying.
