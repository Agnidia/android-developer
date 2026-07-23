# Type-Safe Navigation

Navigation Compose 2.8+ accepts `@Serializable` route classes, removing stringly-typed
paths.

```kotlin
@Serializable data object Home
@Serializable data class Detail(val id: String)

composable<Detail> { entry -> val d = entry.toRoute<Detail>(); DetailScreen(d.id) }
navController.navigate(Detail(id = "42"))
```

Args are typed and checked at compile time. Pass IDs, not whole entities. Use
`popBackStack`/`navigate(route) { popUpTo(...) }` for back-stack control.

## Attribution
Synthesized by IGRSoft (Apache-2.0) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
