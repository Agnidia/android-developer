---
name: viewmodel-stateflow
description: ViewModel state holders with StateFlow: unidirectional data flow, immutable UiState, event handling, and StateFlow vs LiveData. Use when exposing screen state or deciding how the UI observes the ViewModel.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-15'
  keywords: [viewmodel, stateflow, udf, uistate, livedata, android, compose]
---

# ViewModel + StateFlow (UDF)

Expose screen state as a single immutable `StateFlow<UiState>` and accept events as
function calls — unidirectional data flow.

✅ Correct — immutable state out, events in, lifecycle-aware collection:

```kotlin
data class UiState(val loading: Boolean = false, val user: User? = null, val error: String? = null)

class ProfileViewModel(private val getUser: GetUserUseCase) : ViewModel() {
    private val _state = MutableStateFlow(UiState())
    val state: StateFlow<UiState> = _state.asStateFlow()   // immutable to the UI

    fun onLoad(id: UserId) = viewModelScope.launch {
        _state.update { it.copy(loading = true) }
        getUser(id)
            .onSuccess { u -> _state.update { it.copy(loading = false, user = u) } }
            .onFailure { e -> _state.update { it.copy(loading = false, error = e.message) } }
    }
}
```

```kotlin
// UI — collect with lifecycle awareness
val state by viewModel.state.collectAsStateWithLifecycle()
```

When state **derives from a cold source** (a repository `Flow`), build it with `stateIn`
and `WhileSubscribed(5_000)` so upstream work stops shortly after the UI leaves and
restarts cheaply on return:

```kotlin
val state: StateFlow<UiState> = repo.observeUser()
    .map { UiState(user = it) }
    .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), UiState(loading = true))
```

❌ Mistake — exposing the mutable flow or holding state in the composable:

```kotlin
val state: MutableStateFlow<UiState> = _state   // WRONG: UI can mutate ViewModel state
// or, inside a composable:
var user by remember { mutableStateOf<User?>(null) }  // WRONG: screen state belongs in the ViewModel
```

## StateFlow vs LiveData

| Aspect | `StateFlow` | `LiveData` |
|--------|-------------|------------|
| Initial value | Required (always has a value) | Optional |
| Coroutine-native | Yes | No (needs `asFlow`/`liveData{}`) |
| Lifecycle | `collectAsStateWithLifecycle` / `repeatOnLifecycle` | Built-in |
| Recommendation | **Default** for new Kotlin/Compose code | Legacy interop only |

## See also

- [references/udf.md](references/udf.md)
- [references/stateflow-vs-livedata.md](references/stateflow-vs-livedata.md)

## Attribution

Synthesized by IGRSoft (MIT) from community Android architecture references
(`new-silvermoon`, `piyushverma0`). No content copied verbatim.
