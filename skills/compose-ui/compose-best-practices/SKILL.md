---
name: compose-best-practices
description: Compose recomposition and stability: state hoisting, stable/immutable parameters, remember/derivedStateOf, lazy-list keys, and correct side-effect APIs. Use when a screen janks, recomposes too often, or holds state in the wrong place.
license: Apache-2.0
metadata:
  author: Agnidia
  last-updated: '2026-06-15'
  keywords: [recomposition, stability, state-hoisting, side-effects, compose, performance]
---

# Compose Best Practices

## State hoisting

✅ Stateless composable — state in, events out:

```kotlin
@Composable
fun Counter(count: Int, onIncrement: () -> Unit) {
    Button(onClick = onIncrement) { Text("Count: $count") }
}
```

❌ State trapped in the composable (not testable, not reusable):

```kotlin
@Composable
fun Counter() {
    var count by remember { mutableStateOf(0) }   // WRONG for screen state — hoist it
    Button(onClick = { count++ }) { Text("Count: $count") }
}
```

## Stability

Strong-skipping is **default-on since Kotlin 2.0.20** — there is no `enableStrongSkippingMode`
opt-in to apply. It lets Compose skip composables with unstable parameters when their instances
are equal, so the focus shifts to making *types from non-Compose modules* stable.

Unstable parameters still force recomposition when values differ. Make types stable:

```kotlin
@Immutable data class Filters(val tags: PersistentList<String>)   // stable
// vs an unstable List<String> from a non-Compose module → mark @Immutable or use a stable collection
```

## Recomposition hygiene

- `remember` expensive computations; `derivedStateOf` for state derived from other state.
- Provide a stable `key` on `LazyColumn`/`LazyRow` items so reorders don't recompose all.
- No allocation in composition (`Modifier` chains, lambdas) on a hot path — hoist them.

## Side-effects

| API | Use for |
|-----|---------|
| `LaunchedEffect(key)` | Suspend work tied to composition (load on first show / key change) |
| `rememberCoroutineScope()` | Launch from an event callback (button click) |
| `DisposableEffect` | Register/unregister a listener; clean up on leave |
| `SideEffect` | Publish Compose state to a non-Compose object every successful recomposition |

❌ Mistake — launching a coroutine in composition body (runs every recomposition):

```kotlin
@Composable fun Screen(vm: VM) {
    vm.viewModelScope.launch { vm.load() }   // WRONG — use LaunchedEffect(Unit) { vm.load() }
}
```

## See also
- [references/recomposition.md](references/recomposition.md)
- [references/stability.md](references/stability.md)
- [references/state-hoisting.md](references/state-hoisting.md)
- [references/side-effects.md](references/side-effects.md)

## Attribution
Synthesized by Agnidia (Apache-2.0) from `new-silvermoon`, `piyushverma0`, `ayush016`. No verbatim copying.
