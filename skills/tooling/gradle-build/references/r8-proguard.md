# R8 / ProGuard

R8 is the default shrinker/obfuscator/optimizer for release builds, running in **full mode**
(the default) via `proguard-android-optimize.txt`.

- Enable `isMinifyEnabled` + `isShrinkResources` in the `release` build type.
- Keep-rules only for entry points reached via reflection/serialization (Gson/Moshi
  models, JNI, Hilt-generated where needed). Over-broad `-keep class **` defeats shrinking.
- Retain the `mapping.txt` per release to de-obfuscate crash stack traces.
- Never `isDebuggable = true` in release; verify with `apkanalyzer`.

## Attribution
Synthesized by IGRSoft from `new-silvermoon`, Google `android/skills` (Apache License 2.0).
Apache-2.0. No verbatim copying.
