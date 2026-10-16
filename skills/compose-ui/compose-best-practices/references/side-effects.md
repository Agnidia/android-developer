# Side-Effects

| API | When | Cancellation |
|-----|------|--------------|
| `LaunchedEffect(key)` | Suspend work on enter / key change | cancelled on leave or key change |
| `rememberCoroutineScope()` | Launch from a callback (click) | tied to composition |
| `DisposableEffect(key)` | Register + clean up a listener | `onDispose { }` runs on leave |
| `SideEffect` | Push Compose state to a non-Compose object | every successful recomposition |
| `produceState` | Convert non-Compose source → State | cancelled on leave |
| `snapshotFlow` | Observe Compose state as a Flow | within the collecting scope |

Never start coroutines or mutate external state directly in the composable body — it runs
on every recomposition.

## Attribution
Synthesized by Agnidia (Apache-2.0) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
