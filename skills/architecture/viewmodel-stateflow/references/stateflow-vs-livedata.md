# StateFlow vs LiveData

`StateFlow` is the default for new Kotlin/Compose code; `LiveData` is legacy interop.

| Need | Use |
|------|-----|
| New ViewModel state in Compose | `StateFlow` + `collectAsStateWithLifecycle()` |
| Existing `LiveData` you must observe | `observeAsState()` (Compose) or migrate via `asFlow()` |
| One-shot events (navigation, snackbars) | A `Channel`/`SharedFlow` consumed once — not `StateFlow` (which replays) |

Collect `StateFlow` lifecycle-aware to avoid work while the UI is stopped:

```kotlin
val state by viewModel.state.collectAsStateWithLifecycle()
```

Do not model one-shot events as `StateFlow` — its replay re-fires the event on rotation.

## Attribution
Synthesized by Agnidia (Apache-2.0) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
