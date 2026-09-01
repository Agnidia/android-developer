---
description: Scaffold the PlayStore/ publishing folder and generate the Google Play store listing from README, with per-field character budgets
argument-hint: '[--lang en|uk|all] [--path <dir>] [--readme-only] [--dry-run]'
allowed-tools: Read, Glob, Grep, Write
estimated-cost:
  min-tokens: 2000
  max-tokens: 12000
  model-distribution:
    haiku: 20%
    sonnet: 80%
---

# Play Store Listing Content

Scaffold the `PlayStore/` publishing folder and generate every Google Play store-listing field from
the project README — writing the README from source first if it is missing.

[Extended thinking: Play's field budgets are not App Store's and are not interchangeable. The short
description is 80 characters and is what shows in search results; the full description is 4000 and
is what shows on the page. A listing generated against the wrong budget looks fine in a file and is
rejected or silently truncated at upload, which is why the character count is asserted per field
here rather than left as prose guidance.]

## CRITICAL BEHAVIORAL RULES

1. **Assert every character budget.** Emit the count beside each generated field and flag any
   over-budget field rather than truncating it silently.
2. **Never invent a URL or a policy.** A privacy-policy URL that does not exist blocks review.
   Leave the bracketed placeholder and report it.
3. **Adapt, do not translate literally.** The Ukrainian listing must read naturally.
4. **Write nothing under `--dry-run`.** Print the full output instead.
5. **Never enter plan mode.**

## Usage

```bash
/android-developer:gen-playstore-listing
/android-developer:gen-playstore-listing --lang uk
/android-developer:gen-playstore-listing --path ~/projects/MyApp
/android-developer:gen-playstore-listing --readme-only
/android-developer:gen-playstore-listing --dry-run
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `--path <dir>` | cwd | Project root. |
| `--lang en\|uk\|all` | `all` | Which listing locales to generate. Play's locale code for Ukrainian is `uk`, not `ua`. |
| `--readme-only` | off | Generate/update `README.md` only; skip the `PlayStore/` scaffold. |
| `--dry-run` | off | Print everything, write nothing. |

## Step 1 — README pre-check

- **Present**: read `README.md` for the listing source material.
- **Missing**: detect the module layout (`settings.gradle.kts`, `build.gradle.kts`, the
  `applicationId`), read the entry Activity, the DI graph, and the feature packages for purpose and
  capabilities, then write a concise `README.md` covering App Name, Description, Key Features,
  Requirements, and Installation/Usage.

## Step 2 — Scaffold folder structure

Create under the project root, skipping any path that already exists: `PlayStore/en-US/listing.md`,
`PlayStore/uk/listing.md`, `PlayStore/graphics/` (empty; `/gen-playstore-screenshots` fills it), and
`PlayStore/changelog.md`.

Play's release-notes file convention is one file per locale under `PlayStore/<locale>/`; keep the
locale directory names exactly as Play spells them (`en-US`, `uk`) so a later Fastlane or Play
Publisher upload finds them without a mapping step.

## Step 3 — Generate `PlayStore/en-US/listing.md`

Title the file `# Google Play Listing — English (en-US)`, then emit one `##` section per row below,
in order, each carrying its budget as an HTML comment and its value from README.md — a bracketed
placeholder where the source does not settle it.

### `listing.md` template — store listing fields

| Section | Budget | Value |
|---------|--------|-------|
| `## App Name` | 30 characters | `[App name]` |
| `## Short Description` | 80 characters — shown in search results | `[One-line value proposition]` |
| `## Full Description` | 4000 characters | `[Features, benefits, use cases]` |
| `## Release Notes` | 500 characters per release | `[What changed in this version]` |

Play has **no keywords field.** Search relevance comes from the app name, the short description, and
the full description, so the keywords a reader would expect to search for belong inside that prose.
Keyword-stuffing the description is a policy violation, not a tactic.

### `listing.md` template — store settings and contact

| Section | Budget | Value |
|---------|--------|-------|
| `## App Category` | — | `[e.g. Productivity]` |
| `## Tags` | up to 5, chosen from Play's fixed list | `[tag1, tag2]` |
| `## Contact Email` | required | `[support@example.com]` |
| `## Contact Website` | optional | `[https://example.com]` |
| `## Contact Phone` | optional | `[+1 555 0100]` |
| `## Privacy Policy URL` | required for review | `[https://example.com/privacy]` |

## Step 4 — Generate `PlayStore/uk/listing.md`

Same structure and section names as `en-US` (names stay English, values Ukrainian). Character
budgets apply per locale — Ukrainian prose is typically longer than the English it renders, so a
short description that fits in English routinely does not, and must be rewritten rather than cut.

## Step 5 — Report

```markdown
# Play Store Listing — Summary

## README                ← Status | File
## Files Created         ← Status | File (one row per scaffolded path)
## Field Budgets         ← Field | Locale | Chars | Budget | Status
## Placeholders Left     ← Field | Why it could not be filled
## Next Steps            ← fill placeholders → /gen-playstore-screenshots → Data safety form →
                           content rating questionnaire → upload
```

## Error handling

| Condition | Action |
|-----------|--------|
| No `build.gradle.kts` or `build.gradle` under `--path` | Report that this is not an Android project root and stop |
| README missing and sources unreadable | Generate the scaffold with placeholders; report every unfilled field |
| A generated field exceeds its budget | Keep the text, flag the field, and report the overage — never truncate mid-sentence |

## When to run it

Before a Play Store submission that needs listing copy: a new app, a significant version, or a newly
added locale. Run it before `/gen-playstore-screenshots`, which reads the app name and feature copy
from the `listing.md` this command writes.

`## Release Notes` is the one field that changes every release — fill it from the release notes
rather than rewriting the description.
