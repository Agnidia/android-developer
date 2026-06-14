# Flow Operators

| Operator | Use |
|----------|-----|
| `map`/`filter` | Transform/filter values |
| `combine` | Merge latest of multiple flows |
| `flatMapLatest` | Cancel previous inner flow on new value (search, typeahead) |
| `debounce`/`distinctUntilChanged` | Rate-limit and dedupe input |
| `stateIn`/`shareIn` | Convert a cold flow into shared hot state (with a `WhileSubscribed` policy) |
| `catch` | Handle upstream errors without crashing the collector |

`stateIn(scope, SharingStarted.WhileSubscribed(5_000), initial)` is the standard pattern
for exposing repository data as `StateFlow` from a ViewModel — it stops upstream work 5s
after the last collector leaves.

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
