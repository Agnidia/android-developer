# Dependency Inversion at the Boundary

The repository **interface** belongs to `domain`; the **implementation** belongs to
`data`. The arrow points inward — `data` depends on `domain`, never the reverse.

```
domain:  interface UserRepository
data:    class DefaultUserRepository(...) : UserRepository   // depends inward
ui:      ViewModel(getUser: GetUserUseCase)                  // depends inward
```

DI (Hilt) binds the implementation to the interface at the app boundary, so neither `ui`
nor `domain` knows the concrete type.

## Mapping at the boundary

DTOs (network/DB shapes) never cross into `domain`. Map at the data edge:

```kotlin
fun UserDto.toDomain() = User(id = UserId(id), name = name)
```

This keeps a backend rename or a schema change from rippling into business rules or UI.

## Attribution
Synthesized by IGRSoft (Apache-2.0) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
