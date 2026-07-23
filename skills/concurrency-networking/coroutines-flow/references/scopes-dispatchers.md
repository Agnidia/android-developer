# Scopes & Dispatchers

| Scope | Lifetime | Cancelled when |
|-------|----------|----------------|
| `viewModelScope` | The ViewModel | ViewModel cleared |
| `lifecycleScope` | A LifecycleOwner | Lifecycle destroyed |
| custom `CoroutineScope(SupervisorJob() + dispatcher)` | You manage it | You call `cancel()` |

Inject the dispatcher as a constructor parameter (default to the real one) so tests pass a
`StandardTestDispatcher`. Never reference `Dispatchers.IO` directly inside a class you want
to unit-test — it makes timing non-deterministic.

## Attribution
Synthesized by IGRSoft (Apache-2.0) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
