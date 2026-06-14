# Unidirectional Data Flow

One immutable state object flows down; events flow up.

```
        ┌────────────┐  state: StateFlow<UiState>   ┌──────┐
        │ ViewModel  │ ───────────────────────────▶ │  UI  │
        │            │ ◀─────────────────────────── │      │
        └────────────┘  events: onX() lambdas        └──────┘
```

- The UI never mutates state directly — it calls `viewModel.onX()`.
- The ViewModel reduces events into a new `UiState` via `_state.update { }`.
- Render is a pure function of `UiState` — same state, same UI.

Model loading/error/content in **one** state object (or a `sealed interface UiState`),
not three loose booleans that can contradict each other.

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
