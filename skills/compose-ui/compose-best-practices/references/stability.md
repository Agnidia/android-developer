# Stability

A type is *stable* if Compose can trust that `equals` reflects all observable changes.
Unstable parameters skip skipping — the composable recomposes even on equal input.

- Prefer `data class` of stable types; mark `@Immutable`/`@Stable` when you guarantee it.
- `List`/`Map`/`Set` from non-Compose modules are treated as **unstable** — use
  `kotlinx.collections.immutable` (`PersistentList`) or wrap in an `@Immutable` holder.
- Enable the compiler stability report to find unstable params:
  `-P plugin:androidx.compose.compiler.plugins.kotlin:reportsDestination=...`.

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
