# Stability

A type is *stable* if Compose can trust that `equals` reflects all observable changes.

**Strong-skipping is default-on since Kotlin 2.0.20** (no `enableStrongSkippingMode` opt-in).
With it, Compose skips a composable whose parameters are *equal instances* even when some are
unstable — so most jank now comes from types whose `equals` does not reflect their real state,
not from unstable params alone. Stability still matters for correctness and for lambda memoization.

- Prefer `data class` of stable types; mark `@Immutable`/`@Stable` when you guarantee it.
- `List`/`Map`/`Set` from non-Compose modules are treated as **unstable** — use
  `kotlinx.collections.immutable` (`PersistentList`) or wrap in an `@Immutable` holder.
- For types you **cannot annotate** (third-party / generated classes), list them in a
  **stability-configuration file** and point the compiler at it via the Compose compiler
  extension (`stabilityConfigurationFile`), instead of editing the foreign source.
- Enable the compiler stability report to find unstable params:
  `-P plugin:androidx.compose.compiler.plugins.kotlin:reportsDestination=...`.

## Attribution
Synthesized by IGRSoft (Apache-2.0) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
