---
name: coroutines-flow
description: Coroutines and Flow: scope and dispatcher selection, structured concurrency, Flow operators (map/combine/flatMapLatest), and cooperative cancellation. Use when implementing async work or composing reactive streams.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-14'
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

## Flow operators

```kotlin
// search: cancel the previous query when input changes
queryFlow.debounce(300).distinctUntilChanged().flatMapLatest { repo.search(it) }
// combine two states
combine(userFlow, settingsFlow) { user, settings -> Header(user, settings) }
```

Use `flatMapLatest` for "cancel previous on new input" (search/typeahead);
`flatMapMerge`/`flatMapConcat` when you must keep all. `stateIn`/`shareIn` to share a cold
flow as hot state.

## Cancellation

Cancellation is cooperative — suspending functions check it, but tight CPU loops must call
`ensureActive()`/`yield()`. Never catch `CancellationException` and swallow it (it breaks
structured cancellation); rethrow it.

```kotlin
try { work() } catch (e: CancellationException) { throw e } catch (e: Exception) { handle(e) }
```

## See also
- [references/scopes-dispatchers.md](references/scopes-dispatchers.md)
- [references/flow-operators.md](references/flow-operators.md)
- [references/structured-concurrency.md](references/structured-concurrency.md)
- [references/cancellation.md](references/cancellation.md)

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
