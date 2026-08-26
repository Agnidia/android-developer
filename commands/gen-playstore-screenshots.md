---
description: Plan and assemble the Google Play graphic assets — feature graphic, icon, and per-form-factor screenshot sets with Play's exact dimension and count rules
argument-hint: '[--form-factor phone|tablet7|tablet10|wear|tv|all] [--lang en|uk] [--path <dir>] [--dry-run]'
allowed-tools: Read, Glob, Grep, Write, Bash
estimated-cost:
  min-tokens: 4000
  max-tokens: 25000
  model-distribution:
    haiku: 10%
    sonnet: 80%
    opus: 10%
---

# Play Store Graphic Assets

Assemble the Play Console graphic assets from `PlayStore/graphics/` and the feature copy in
`PlayStore/{locale}/listing.md`: the feature graphic, the app icon, and one screenshot set per form
factor the app declares support for.

[Extended thinking: Play rejects on *counts and ratios*, not on taste. A store listing needs at
least 2 phone screenshots or it cannot be published at all, and a device type declared in the
manifest but left without screenshots downgrades the listing's ranking on that form factor rather
than erroring — a silent failure that is the reason the form-factor set is derived from the
manifest here instead of from a flag alone.]

## CRITICAL BEHAVIORAL RULES

1. **Derive the required form factors from the project**, not from `--form-factor` alone: a
   `<uses-feature>` for leanback or watch, a Wear or TV module in `settings.gradle.kts`, or a
   `tv`/`wear` product flavour each add a required set. `--form-factor` narrows what is produced;
   it never suppresses the report of what is missing.
2. **Never upscale a source image to hit a minimum dimension.** Play accepts it and it looks it.
   Report the shortfall and name the source file.
3. **Assert every count and ratio** in the report — a set that cannot be published is the finding.
4. **Write nothing under `--dry-run`.**
5. **Never enter plan mode.**

## Usage

```bash
/android-developer:gen-playstore-screenshots
/android-developer:gen-playstore-screenshots --form-factor phone
/android-developer:gen-playstore-screenshots --form-factor all --lang uk
/android-developer:gen-playstore-screenshots --dry-run
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `--form-factor` | detected | `phone`, `tablet7`, `tablet10`, `wear`, `tv`, or `all`. |
| `--lang en\|uk` | `en` | Which `listing.md` supplies the caption copy. |
| `--path <dir>` | cwd | Project root. |
| `--dry-run` | off | Print the plan, write nothing. |

## Prerequisites

`PlayStore/` must exist — run `/android-developer:gen-playstore-listing` first if it does not.
Inputs read here:

- `PlayStore/{locale}/listing.md` — App Name, Short Description, Full Description (the caption source)
- `PlayStore/graphics/` — raw device captures, descriptively named (`01-home.png`, `02-search.png`, …)

## Play asset specifications

These are Play Console's own rules; they are not App Store's and do not convert.

### Store-level graphics (one each, not per form factor)

| Asset | Dimensions | Format | Required |
|-------|-----------|--------|----------|
| App icon | 512 × 512 | 32-bit PNG, no alpha transparency | yes |
| Feature graphic | 1024 × 500 | PNG or JPEG, no alpha | yes |
| Promo video | YouTube URL | — | no |

The feature graphic is the banner at the top of the listing and is also what Play uses when the app
is featured. It is **not** a screenshot: text in it must stay legible when Play crops it, so keep
anything load-bearing away from the edges.

### Screenshot sets per form factor

| Form factor | Count | Min edge | Max edge | Aspect |
|-------------|-------|----------|----------|--------|
| Phone | 2–8 (2 is the publish floor) | 320 px | 3840 px | between 16:9 and 9:16 |
| 7" tablet | up to 8 | 320 px | 3840 px | between 16:9 and 9:16 |
| 10" tablet | up to 8 | 1080 px | 7680 px | between 16:9 and 9:16 |
| Wear OS | up to 8 | 384 px | 3840 px | 1:1 |
| Android TV | up to 8 | 320 px | 3840 px | 16:9 landscape only |

The long edge may be at most twice the short edge. PNG or JPEG, no alpha.

## Step 1 — Detect declared form factors

Read `AndroidManifest.xml` for `<uses-feature android:name="android.software.leanback">` (TV) and
`android.hardware.type.watch` (Wear), and `settings.gradle.kts` for `:wear`, `:tv`, or equivalently
named modules. Union that with `--form-factor`. Report any declared form factor with no screenshot
set — that is the failure mode this step exists to catch.

## Step 2 — Inventory and validate sources

Collect `.png`/`.jpg` under `PlayStore/graphics/`, sorted by filename. For each, read the real pixel
dimensions and check them against the table above for every form factor it is a candidate for.
Classify each source as usable, under-minimum, or wrong-aspect. Never upscale.

## Step 3 — Write captions

Parse `## Full Description` from `PlayStore/{locale}/listing.md` into distinct features, one per
screenshot. For each, write a **headline** (3–6 words, the benefit rather than the feature name) and
a **subtitle** (6–12 words). The first screenshot carries the core value proposition — it is the one
shown in search results beside the short description.

## Step 4 — Emit the assembly plan

Write `PlayStore/graphics/PLAN.md`: one section per form factor, one row per slide with source file,
target dimensions, headline, and subtitle, plus a section for the feature graphic and icon.

This command produces the **plan and the copy**, not composited images: this plugin ships no image
compositor, and inventing one silently would produce assets nobody could reproduce. Compose the
final frames in a design tool from `PLAN.md`, or capture them directly at the target dimensions.

## Step 5 — Report

```markdown
# Play Store Graphics — Summary

## Form Factors        ← Factor | Declared by | Required | Sources found | Publishable
## Source Validation   ← File | Dimensions | Verdict (usable / under-minimum / wrong-aspect)
## Slides              ← Factor | # | Source | Headline | Subtitle
## Blockers            ← what prevents publishing, per form factor
## Next Steps          ← compose frames from PLAN.md → upload → Data safety → content rating
```

## Error handling

| Condition | Action |
|-----------|--------|
| `PlayStore/` missing | Suggest `/android-developer:gen-playstore-listing` first |
| Fewer than 2 usable phone screenshots | Report as a **publish blocker**, not a warning |
| A declared form factor has no sources | Report it; the listing is publishable but ranks worse there |
| Source under the minimum edge | Name the file and its actual size; never upscale |

## When to run it

Before a Play Store submission, once `/gen-playstore-listing` has scaffolded `PlayStore/` and real
device captures are in `PlayStore/graphics/`. Also when adding support for a form factor the current
listing has no screenshots for — adding a Wear or TV module without its screenshot set is the common
miss.
