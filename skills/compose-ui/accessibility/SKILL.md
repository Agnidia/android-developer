---
name: accessibility
description: Compose accessibility: semantics, content descriptions, TalkBack, merged semantics, and minimum touch targets. Use when making screens usable with assistive technologies.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-14'
  keywords: [accessibility, a11y, semantics, talkback, touch-targets, compose]
---

# Accessibility (Compose)

Make screens usable with TalkBack and switch access.

✅ Correct — meaningful content description, merged semantics, 48dp target:

```kotlin
IconButton(onClick = onShare, modifier = Modifier.sizeIn(minWidth = 48.dp, minHeight = 48.dp)) {
    Icon(Icons.Default.Share, contentDescription = stringResource(R.string.share))
}
```

❌ Mistake — decorative icon with a description, or interactive element below 48dp:

```kotlin
Icon(Icons.Default.Star, contentDescription = "star")  // WRONG if decorative — use null
Box(Modifier.size(24.dp).clickable { })                // WRONG — touch target too small
```

## Rules

- **Content descriptions** for meaningful images/icons; `null` for purely decorative ones.
- **Touch targets** ≥ 48dp × 48dp (`minimumInteractiveComponentSize` is applied by
  Material components; custom clickables must enforce it).
- **Merge semantics** for a row that reads as one item (`Modifier.semantics(mergeDescendants = true)`).
- **State** announced via `stateDescription`/`toggleable`/`selectable` so TalkBack reads
  checked/selected.
- Test with TalkBack and the Accessibility Scanner; assert `contentDescription` in Compose
  UI tests.

## See also
- [references/semantics.md](references/semantics.md)
- [references/touch-targets.md](references/touch-targets.md)

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `ayush016`. No verbatim copying.
