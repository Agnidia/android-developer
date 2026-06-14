# Recomposition

Compose recomposes the smallest scope whose inputs changed. Keep that scope small and its
inputs stable.

- **Defer state reads** to the lowest composable that needs them — reading `state.value`
  high up recomposes the whole subtree.
- **`derivedStateOf`** when a value is computed from other state and changes less often
  than its inputs (e.g. `isScrolledToTop` from a scroll position).
- **Lazy list keys** (`items(list, key = { it.id })`) keep stable identity across updates.
- **Hoist lambdas/Modifiers** out of hot recomposition paths to avoid per-frame allocation.

Diagnose with Layout Inspector recomposition counts and the Compose compiler stability
report (`reportsDestination`).

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
