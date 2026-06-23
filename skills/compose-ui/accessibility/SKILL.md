---
name: accessibility
description: Compose accessibility: semantics, content descriptions, TalkBack, merged semantics, and minimum touch targets. Use when making screens usable with assistive technologies.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-23'
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

## M3 Expressive a11y

Expressive raises the motion/shape stakes — the floor still holds. When building Expressive UI
([material3-expressive/SKILL.md](../material3-expressive/SKILL.md)):

- **Reduce motion** — when `ANIMATOR_DURATION_SCALE == 0`, fall back to `snap()`/simple fades and
  switch from the expressive motion scheme to the standard one.
- **High contrast** — respond to `UiModeManager.getContrast()` for high-contrast themes.
- **Touch targets** — keep interactive areas ≥ 48dp **throughout** a shape morph (the visual
  silhouette may animate; the hit target must not shrink).
- **Interruptible springs** — keep every animation interruptible; this is a core a11y benefit of the
  spring system, not just polish.

## See also
- [references/semantics.md](references/semantics.md)
- [references/touch-targets.md](references/touch-targets.md)
- [material3-expressive/SKILL.md](../material3-expressive/SKILL.md) — Expressive design-craft (reduce-motion, morphing targets)

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `ayush016`. No verbatim copying.
