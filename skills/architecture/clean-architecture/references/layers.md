# Layer Responsibilities

| Layer | May contain | Must NOT contain |
|-------|-------------|------------------|
| `ui` | Composables, ViewModels, UI state mappers, navigation | Network/DB calls, business rules |
| `domain` | Use-cases, domain models, repository interfaces, value types | Android framework types, DTOs, framework annotations |
| `data` | Repository impls, Room/Retrofit sources, DTOs, mappers | UI concerns, navigation |

The `domain` layer is the stable core: it changes only when business rules change, not
when the UI framework or a data source changes.

## Use-cases

A use-case is a single-responsibility callable in `domain`:

```kotlin
class ObserveCartTotal(private val cart: CartRepository) {
    operator fun invoke(): Flow<Money> = cart.items().map { it.sumOf(LineItem::subtotal) }
}
```

Keep them thin — orchestration, not framework glue. Trivial pass-throughs can call the
repository directly from the ViewModel; add a use-case when there is real logic to host.

## Attribution
Synthesized by Agnidia (Apache-2.0) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
