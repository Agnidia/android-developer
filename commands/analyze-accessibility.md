---
description: Audit Android UI accessibility — TalkBack, Compose semantics, touch targets, contrast — and triage findings by severity
argument-hint: [path or module (default .)] [--level A|AA|AAA] [--device SERIAL]
allowed-tools: Read, Glob, Grep, Bash
estimated-cost:
  min-tokens: 3000
  max-tokens: 25000
  model-distribution:
    haiku: 25%
    sonnet: 60%
    opus: 15%
---

# Accessibility Audit
<!-- Updated: June 2026 -->

Audit Android UI against WCAG 2.2 and the Android accessibility guidelines: TalkBack
labelling, Compose semantics, touch-target size, contrast, focus order, and state
announcement. Read-only — findings triage to P0-P3; fixes route out to a separate command.

[Extended thinking: Automated Android a11y tooling (Accessibility Scanner, the
`accessibility-test-framework` checks wired into Espresso/Compose tests) catches roughly the
machine-detectable third: missing content descriptions, small targets, low contrast. It
cannot tell you whether a label is *meaningful*, whether focus order matches reading order,
or whether a state change is announced. So this command treats tooling as evidence and the
semantics review as the actual audit — and it never reports a screen "accessible" on a green
scan alone. Compose changes the shape of the problem: `contentDescription`, `Modifier.semantics`,
`mergeDescendants`, and `stateDescription` are the surface, not View XML attributes.]

## CRITICAL BEHAVIORAL RULES

1. **Read-only. This command NEVER edits.** `allowed-tools` excludes `Write`/`Edit`. Fixes
   route to `/android-developer:fix-quick` (mechanical) or
   `/android-developer:review-code --fix` (semantic).
2. **Automated tooling is evidence, not a verdict.** A clean scan does not mean accessible.
   Always report which categories the tooling cannot check — meaningful labels, focus
   order, state announcement, gesture alternatives — and mark them "requires manual review."
3. **One agent.** `android-developer:android-phone-developer` performs the semantics review.
4. **Triage every finding** to a WCAG 2.2 success criterion and a severity from
   `skill: severity-matrix`. `--level` bounds which criteria are in scope.
5. **Single-command Bash invocations** (`./gradlew :app:connectedDebugAndroidTest`,
   `adb shell settings get secure enabled_accessibility_services`).
6. **No device is not a failure** — fall back to static source analysis and mark the report
   reduced-coverage.
7. **Never enter plan mode.**

## Usage

```bash
/android-developer:analyze-accessibility .
/android-developer:analyze-accessibility :feature:checkout --level AA
/android-developer:analyze-accessibility app --device emulator-5554
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `path` | `.` | Module, package, or composable file to audit. |
| `--level A\|AA\|AAA` | AA | WCAG 2.2 conformance level. AA is the baseline; AAA is reported as advisory. |
| `--device SERIAL` | first attached | Device for the on-device checks. |

## Phase 1: Static Source Analysis

Read the target's composables and layouts for:

| Check | Looks for | WCAG SC |
|-------|-----------|---------|
| Missing accessible name | `Icon`/`IconButton`/`Image` with `contentDescription = null` where the element is interactive or informative | 1.1.1 |
| Decorative marked as content | A purely decorative image given a description (noise for TalkBack) | 1.1.1 |
| Touch target | `Modifier.size` below 48dp on a clickable, or clickable applied to the icon rather than the padded container | 2.5.8 |
| Semantics merging | Composite rows without `Modifier.semantics(mergeDescendants = true)`, so TalkBack reads fragments | 1.3.1 |
| State not announced | Toggle/selection state carried only visually, no `stateDescription`/`toggleableState`/`selected` role | 4.1.2 |
| Custom actions | Swipe/long-press-only affordances with no `customActions` equivalent | 2.1.1 |
| Live regions | Async status (loading, error, cart count) with no `liveRegion` | 4.1.3 |
| Text scaling | Hardcoded `sp`→`dp`, fixed heights around text, `maxLines = 1` on user-facing copy | 1.4.4 |
| Contrast | Literal colors bypassing the M3 color roles (`skill: material3`) | 1.4.3 |
| Heading structure | No `heading()` semantics on screen/section titles | 1.3.1 |
| Focus order | Traversal order diverging from reading order without `traversalIndex`/`isTraversalGroup` | 2.4.3 |

`skill: accessibility` (`references/semantics.md`, `references/touch-targets.md`) is the
canonical reference for the Compose surface.

## Phase 2: Automated Evidence (device)

If a device is attached:

1. Run the project's accessibility checks if wired in:
   `./gradlew :{module}:connectedDebugAndroidTest 2>&1 | tee -a "$LOG"` — Compose UI tests
   with `AccessibilityChecks`/`accessibility-test-framework` enabled report target size,
   contrast, and missing-label violations.
2. Confirm TalkBack availability:
   `adb shell settings get secure enabled_accessibility_services`.
3. Note that Accessibility Scanner is a manual, on-device sweep — recommend it for the
   screens flagged in Phase 1 rather than claiming its coverage.

If no device: skip this phase, mark the report "static-only — automated coverage
unavailable," and continue.

## Phase 3: Semantics Review

**Use Task tool with subagent_type="android-developer:android-phone-developer"**
Prompt: "Review accessibility for `{path}` at WCAG 2.2 {level}. Static findings:
{phase 1}. Automated evidence: {phase 2 or 'none — no device'}. Using
`skill: accessibility` (semantics, touch targets) and `skill: material3` (color roles and
contrast), confirm each finding against its success criterion and add what the tooling
cannot detect: whether each `contentDescription` is *meaningful* rather than merely present,
whether TalkBack traversal order matches the visual reading order, whether state changes
and async results are announced, and whether every gesture-only affordance has a
custom-action equivalent. Return a P0-P3 list with `file:line`, the success criterion, and
a concrete Compose fix per item. Review-only — do NOT edit."

## Severity

| Severity | Meaning |
|----------|---------|
| P0 | A TalkBack or switch-access user cannot complete the task — unlabelled critical control, no non-gesture path |
| P1 | Serious barrier — contrast failure on body text, sub-48dp primary action, state never announced |
| P2 | Degraded experience — fragmented reading order, missing headings, unhelpful label |
| P3 | Advisory / AAA |

## Output Format

```markdown
## Accessibility Audit (WCAG 2.2 — {level})
**Target:** {path}  **Device:** {serial|none — static only}
**Automated:** {connectedAndroidTest ✅ | unavailable}  **Log:** .context/logs/a11y-{ts}.log

### Summary
| Priority | Count | Example SC |
|----------|------:|------------|
| P0 | {n} | 1.1.1 Non-text Content |
| P1 | {n} | 2.5.8 Target Size, 1.4.3 Contrast |

### Findings
| File:Line | SC | Severity | Issue | Fix |
|-----------|----|----------|-------|-----|
| CartScreen.kt:88 | 1.1.1 | P0 | remove-item `IconButton` has `contentDescription = null` | describe the action, not the glyph |
| CartRow.kt:31 | 1.3.1 | P2 | row read as 3 fragments | `Modifier.semantics(mergeDescendants = true)` |

### Requires Manual Review (tooling-blind)
- 2.4.3 focus order: {note} — verify with TalkBack on {screen}
- 4.1.3 status messages: {note}

### Coverage Notes
- {what was not measured and why}
```

## Error Handling

### No device attached
```
Note: adb devices lists no device — automated a11y checks skipped.
Proceeding with static source analysis (reduced coverage).
Suggestion: start an emulator, then re-run for target-size and contrast evidence.
```

### Accessibility checks not wired into the test suite
Report that `AccessibilityChecks` is not enabled in the instrumented tests, name it as a
gap, and suggest `/android-developer:gen-tests --type ui` to add coverage.

## See Also
- `skill: accessibility` — Compose semantics and touch-target reference.
- `skill: material3` — color roles that carry contrast compliance.
- `skill: severity-matrix` — P0-P3 definitions used by the triage.
- `/android-developer:review-code --fix` — route the confirmed semantic fixes.
- `/android-developer:gen-tests --type ui` — lock fixes in with accessibility assertions.
