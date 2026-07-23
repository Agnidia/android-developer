# Touch Targets

Interactive elements must be at least **48dp × 48dp** (Material `minimumInteractiveComponentSize`).

- Material components (`Button`, `IconButton`, `Checkbox`) enforce this automatically.
- Custom `clickable` elements must add `Modifier.sizeIn(minWidth = 48.dp, minHeight = 48.dp)`
  or sit inside a 48dp container, even if the icon itself is 24dp.
- Keep visual spacing between adjacent targets so they are distinguishable by touch and by
  the Accessibility Scanner.

## Attribution
Synthesized by IGRSoft (Apache-2.0) from `new-silvermoon`, `ayush016`. No verbatim copying.
