# DV Evidence Manifest Template (cli-fallback)

Android/Compose work defaults to `metadata.requires_screenshots: false`. There are two
cases:

## Case 1 — gate not armed (default)

Write a one-line skip-rationale in `development-N.md` instead of a manifest:

```
> Skipped: metadata.requires_screenshots = false. Rationale: no visual surface — <logic/data/build> change verified by Gradle/CLI evidence.
```

## Case 2 — gate armed (`requires_screenshots: true`)

Write `.context/images/<worktask_id>/screenshots.md` with one row per captured surface.
For Android, captures are **terminal transcripts** (no emulator screenshot is required as
the primary source):

```markdown
---
worktask_id: <worktask_id>
screenshot_count: 3
---

| name | path | source | design_ref | notes |
|------|------|--------|------------|-------|
| build | .context/images/<id>/build.txt | cli-fallback | | `./gradlew :app:assembleDebug` output |
| unit-tests | .context/images/<id>/tests.txt | cli-fallback | | `./gradlew :feature:testDebugUnitTest` transcript |
| screen-render | .context/images/<id>/screen.png | cli-fallback | designs/screen.png | `adb shell screencap` of the changed screen (optional) |
```

- `source` is `cli-fallback` for Gradle/adb evidence.
- `design_ref` stays blank unless a Compose screen maps to a mockup (QA design-diff join).
- `screenshot_count` MUST equal the number of table rows.
- Render text transcripts via the cli-fallback chain (`silicon` → ImageMagick → `.txt`
  placeholder) if an image artifact is required by the gate; the `.txt` transcript itself
  is sufficient evidence for logic/build surfaces.
