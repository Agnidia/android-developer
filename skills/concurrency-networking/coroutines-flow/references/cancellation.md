# Cancellation

Cancellation is cooperative:

- Suspending functions (`delay`, `withContext`, most library calls) check for cancellation
  and throw `CancellationException`.
- CPU-bound loops must opt in: call `ensureActive()` or `yield()` periodically.
- **Never swallow `CancellationException`** — a `catch (e: Exception)` that handles it
  breaks structured cancellation. Rethrow it explicitly.
- Clean up resources in `finally` (which runs on cancellation) or with
  `use`/`invokeOnCompletion`.

```kotlin
val job = scope.launch { /* ... */ }
job.cancel()              // requests cancellation
job.cancelAndJoin()       // and waits for it to finish unwinding
```

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
