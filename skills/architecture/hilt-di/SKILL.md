---
name: hilt-di
description: Hilt dependency injection for Android: modules and components, scope selection (Singleton/ActivityRetained/ViewModel), binding interfaces, and testable DI with @TestInstallIn. Use when wiring dependencies or making the graph testable.
license: Apache-2.0
metadata:
  author: Agnidia
  last-updated: '2026-06-15'
  keywords: [hilt, dependency-injection, di, scopes, components, testing, android]
---

# Hilt Dependency Injection (Android)

Wire dependencies with Hilt, choosing the right component scope and keeping the graph
testable.

## Setup

Wire versions through the version catalog; **KSP is the recommended processor** (KAPT is a
legacy fallback only):

```kotlin
// build.gradle.kts
plugins {
    id("com.google.dagger.hilt.android")
    id("com.google.devtools.ksp")          // apply KSP, not kapt
}
dependencies {
    implementation(libs.hilt.android)      // com.google.dagger:hilt-android (e.g. 2.59.2 as of 2026-06)
    ksp(libs.hilt.compiler)                // com.google.dagger:hilt-compiler
}
```

The version lives in the catalog (see the `gradle-build` skill); the snippet shows the
*mechanism*. Prefer KSP everywhere — only fall back to `kapt(...)` on a module that cannot
yet run KSP.

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

## ViewModel injection

`@HiltViewModel` lives in core `hilt-android` — there is no separate
`hilt-lifecycle-viewmodel` artifact. Constructor-inject dependencies directly:

```kotlin
@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val getUser: GetUserUseCase,
    savedState: SavedStateHandle,          // runtime args survive process death
) : ViewModel()
```

For runtime args that are **not** Parcelable, use assisted injection — annotate the
constructor with `@AssistedInject`, mark assisted params with `@Assisted`, and point the
annotation at an `@AssistedFactory`:

```kotlin
@HiltViewModel(assistedFactory = MovieViewModel.Factory::class)
class MovieViewModel @AssistedInject constructor(
    @Assisted val movieId: Int,
    private val getMovie: GetMovieUseCase,
) : ViewModel() {
    @AssistedFactory interface Factory { fun create(movieId: Int): MovieViewModel }
}
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

Synthesized by Agnidia (Apache-2.0) from community Android architecture references
(`new-silvermoon`, `piyushverma0`). No content copied verbatim.
