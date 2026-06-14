# Semantics

The semantics tree is what TalkBack and tests read. Tune it with `Modifier.semantics`:

```kotlin
Modifier.semantics {
    contentDescription = "Play"
    stateDescription = if (playing) "Playing" else "Paused"
    role = Role.Button
}
```

- Merge a composite item so it reads as one: `semantics(mergeDescendants = true)`.
- Use `clearAndSetSemantics` to replace a noisy subtree's description with one label.
- Add `testTag` for stable test selectors (it does not affect TalkBack).

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `ayush016`. No verbatim copying.
