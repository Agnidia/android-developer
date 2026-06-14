---
name: navigation
description: Type-safe Navigation Compose: serializable route types, argument passing, nested graphs, and deep links. Use when wiring screen navigation or handling deep links.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-14'
  keywords: [navigation, navigation-compose, type-safe, deep-links, routes, compose]
---

# Navigation (Compose)

Use type-safe routes (Navigation Compose 2.8+) with `@Serializable` destinations — no
stringly-typed routes.

✅ Correct — serializable route with typed args:

```kotlin
@Serializable data class Profile(val userId: String)

NavHost(navController, startDestination = Home) {
    composable<Home> { HomeScreen(onUser = { navController.navigate(Profile(it)) }) }
    composable<Profile> { backStack ->
        val args = backStack.toRoute<Profile>()
        ProfileScreen(userId = args.userId)
    }
}
```

❌ Mistake — string routes with manual arg parsing (fragile, untyped):

```kotlin
navController.navigate("profile/$userId")   // WRONG — typos compile, args untyped
```

## Patterns

- Pass **IDs**, not whole objects — fetch in the destination's ViewModel.
- Hoist `navController` to a single `AppNavHost`; pass navigation lambdas down, not the
  controller, so screens stay testable and previewable.
- Group related screens in nested graphs (`navigation<Graph>{}`).

## See also
- [references/type-safe-nav.md](references/type-safe-nav.md)
- [references/deep-links.md](references/deep-links.md)

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
