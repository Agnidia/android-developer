# State Hoisting

Move state up to the lowest common owner of the composables that read or write it. The
composable becomes stateless: `value` in, `onValueChange` out.

```kotlin
@Composable fun SearchBar(query: String, onQueryChange: (String) -> Unit) =
    TextField(value = query, onValueChange = onQueryChange)
```

Screen-level state lives in the ViewModel (`StateFlow<UiState>`). Local, ephemeral UI
state with no business meaning (e.g. "is this dropdown expanded") may stay in `remember`
inside the composable.

## Attribution
Synthesized by IGRSoft (Apache-2.0) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
