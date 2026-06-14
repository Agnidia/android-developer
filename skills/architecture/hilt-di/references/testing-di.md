# Testing with Hilt

Prefer **constructor injection** so unit tests need no graph:

```kotlin
@Test fun loadsUser() = runTest {
    val vm = ProfileViewModel(GetUserUseCase(FakeUserRepository()))   // no Hilt needed
    // ...
}
```

For instrumented tests that exercise the graph, replace modules with `@TestInstallIn`:

```kotlin
@Module @TestInstallIn(components = [SingletonComponent::class], replaces = [NetworkModule::class])
object FakeNetworkModule { @Provides fun userApi(): UserApi = FakeUserApi() }
```

Annotate the test with `@HiltAndroidTest` and use `HiltAndroidRule`. Keep Hilt out of pure
unit tests — its value there is zero and it slows them down.

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
