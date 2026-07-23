# Hilt Modules & Components

- `@Module @InstallIn(<Component>::class)` declares where bindings live.
- `@Binds` (in an `abstract` module) binds an interface to its implementation — preferred
  for types you own.
- `@Provides` (in an `object`/concrete module) constructs types you do **not** own
  (Retrofit, Room, OkHttp).

```kotlin
@Module @InstallIn(SingletonComponent::class)
object NetworkModule {
    @Provides @Singleton fun retrofit(): Retrofit = Retrofit.Builder()/* ... */.build()
    @Provides @Singleton fun userApi(r: Retrofit): UserApi = r.create(UserApi::class.java)
}
```

Component hierarchy mirrors the Android lifecycle: `Singleton` → `ActivityRetained` →
`Activity`/`ViewModel` → `Fragment`/`View`. A binding is visible to its component and all
children.

## Processor

Generate the graph with **KSP** — `ksp("com.google.dagger:hilt-compiler:…")` (version from
the catalog). KSP is the recommended path; `kapt` is a legacy fallback for modules that
cannot yet run it.

## ViewModels

`@HiltViewModel` is in core `hilt-android` (no `hilt-lifecycle-viewmodel` artifact).
Constructor-inject with `@Inject`; for non-Parcelable runtime args use
`@HiltViewModel(assistedFactory = …)` + `@AssistedInject`/`@Assisted` (see the SKILL).

## Attribution
Synthesized by IGRSoft (Apache-2.0) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
