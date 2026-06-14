---
name: hilt-di
description: Hilt dependency injection for Android: modules and components, scope selection (Singleton/ActivityRetained/ViewModel), binding interfaces, and testable DI with @TestInstallIn. Use when wiring dependencies or making the graph testable.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-14'
  keywords: [hilt, dependency-injection, di, scopes, components, testing, android]
---

# Hilt Dependency Injection (Android)

Wire dependencies with Hilt, choosing the right component scope and keeping the graph
testable.

## Components & scopes

| Scope | Lives as long as | Use for |
|-------|------------------|---------|
| `@Singleton` | The application | App-wide singletons (Retrofit, Room, DataStore) |
| `@ActivityRetainedScoped` | Survives config changes | State that outlives rotation but not the screen |
| `@ViewModelScoped` | The ViewModel | Per-ViewModel collaborators |
| `@ActivityScoped` | The Activity | Activity-bound dependencies |

✅ Correct — bind an interface with `@Binds` in an `abstract` module, scope at `@Singleton`:

```kotlin
@Module @InstallIn(SingletonComponent::class)
abstract class RepositoryModule {
    @Binds @Singleton
    abstract fun bindUserRepository(impl: DefaultUserRepository): UserRepository
}
```

❌ Mistake — `@Provides` for a type you own (verbose) or no scope on a singleton (a new
instance per injection point):

```kotlin
@Provides   // WRONG: prefer @Binds for an interface you own; missing @Singleton
fun provideUserRepository(api: UserApi) = DefaultUserRepository(api)
```

## Testable DI

Prefer **constructor injection** so tests can build objects without the graph. Swap
modules in instrumented tests with `@TestInstallIn`:

```kotlin
@Module @TestInstallIn(components = [SingletonComponent::class], replaces = [RepositoryModule::class])
abstract class FakeRepositoryModule {
    @Binds abstract fun bindUserRepository(fake: FakeUserRepository): UserRepository
}
```

## Anti-patterns

- **Field injection everywhere** → prefer constructor injection (testable without Hilt).
- **Over-scoping** (`@Singleton` on per-screen state) → leaks memory and stale state.
- **Hilt in a pure-Kotlin `domain` module** → keep `domain` framework-free; inject at the
  data/ui boundary.

## See also

- [references/modules-components.md](references/modules-components.md)
- [references/scopes.md](references/scopes.md)
- [references/testing-di.md](references/testing-di.md)

## Attribution

Synthesized by IGRSoft (MIT) from community Android architecture references
(`new-silvermoon`, `piyushverma0`). No content copied verbatim.
