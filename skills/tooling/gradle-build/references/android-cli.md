# Android CLI

Single scoped commands (no `cd`/`&&` chains):

| Tool | Command | Purpose |
|------|---------|---------|
| adb | `adb install -r app.apk` | Install/replace an APK |
| adb | `adb logcat` | Stream device logs |
| adb | `adb shell am start -n pkg/.Activity` | Launch an activity |
| adb | `adb shell screencap -p /sdcard/s.png` | Capture a screen (cli-fallback evidence) |
| apkanalyzer | `apkanalyzer apk file-size app.apk` | APK size |
| apkanalyzer | `apkanalyzer dex packages app.apk` | Method/package breakdown |
| gradlew | `./gradlew :app:assembleDebug` | Build a variant |

## Attribution
Synthesized by IGRSoft from `new-silvermoon`, Google `android/skills` (Apache License 2.0).
Apache-2.0. No verbatim copying.
