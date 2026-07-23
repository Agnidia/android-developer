---
name: coroutines-flow
description: Coroutines and Flow: scope and dispatcher selection, structured concurrency, Flow operators (map/combine/flatMapLatest), and cooperative cancellation. Use when implementing async work or composing reactive streams.
license: Apache-2.0
metadata:
  author: IGRSoft
  last-updated: '2026-06-15'
  keywords: [coroutines, flow, scopes, dispatchers, cancellation, structured-concurrency]
---

# Coroutines & Flow

## Scopes & dispatchers

✅ Correct — `viewModelScope`, injected dispatcher:

```kotlin
class VM(private val repo: Repo, private val io: CoroutineDispatcher = Dispatchers.IO) : ViewModel() {
    fun save(x: X) = viewModelScope.launch { withContext(io) { repo.save(x) } }
}
```

❌ Mistake — `GlobalScope` (unstructured, leaks) + hardcoded dispatcher (untestable):

```kotlin
fun save(x: X) = GlobalScope.launch(Dispatchers.IO) { repo.save(x) }   // WRONG on both counts
```

| Dispatcher | Use for |
|------------|---------|
| `Main` | UI updates, calling suspend functions that touch UI |
| `Main.immediate` | Avoid an extra dispatch when already on Main |
| `IO` | Network, disk, blocking JVM calls |
| `Default` | CPU-bound work (sorting, parsing, JSON) |

Bound a noisy IO source with `Dispatchers.IO.limitedParallelism(n)` (e.g. a connection pool
or a rate-limited API) so it can't starve the shared IO pool.

## Flow operators

```kotlin
// search: cancel the previous query when input changes
queryFlow.debounce(300).distinctUntilChanged().flatMapLatest { repo.search(it) }
// combine two states
combine(userFlow, settingsFlow) { user, settings -> Header(user, settings) }
```

Use `flatMapLatest` for "cancel previous on new input" (search/typeahead);
`flatMapMerge`/`flatMapConcat` when you must keep all. Share a cold flow as hot state with
`stateIn(scope, SharingStarted.WhileSubscribed(5_000), initial)` — the 5s timeout keeps
upstream alive across config changes but stops it when nothing collects.

## Cancellation

Cancellation is cooperative — suspending functions check it, but tight CPU loops must call
`ensureActive()`/`yield()`. Never catch `CancellationException` and swallow it (it breaks
structured cancellation); rethrow it.

```kotlin
try { work() } catch (e: CancellationException) { throw e } catch (e: Exception) { handle(e) }
```

## KMP

`kotlinx-coroutines-core` and `Flow` live in `commonMain` — write suspend/Flow logic once and
share it across Android and iOS. Keep `Dispatchers.IO` out of `commonMain` (it is JVM-only);
inject the dispatcher (as above) so each target supplies its own.

## See also
- [references/scopes-dispatchers.md](references/scopes-dispatchers.md)
- [references/flow-operators.md](references/flow-operators.md)
- [references/structured-concurrency.md](references/structured-concurrency.md)
- [references/cancellation.md](references/cancellation.md)

## Attribution
Synthesized by IGRSoft (Apache-2.0) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
