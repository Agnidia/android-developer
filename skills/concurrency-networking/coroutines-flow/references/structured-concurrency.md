# Structured Concurrency

Coroutines form a parent-child tree: a parent does not complete until its children do, and
cancelling a parent cancels its children. This makes leaks structurally impossible when you
use a real scope.

```kotlin
viewModelScope.launch {                 // parent
    val a = async { repo.a() }          // children
    val b = async { repo.b() }
    combine(a.await(), b.await())       // both finish before the parent completes
}
```

Use `coroutineScope { }` to await a group of children (failure cancels siblings) and
`supervisorScope { }` when one child's failure should not cancel the others.

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
