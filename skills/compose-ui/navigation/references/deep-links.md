# Deep Links

Attach deep links to a typed destination:

```kotlin
composable<Detail>(
    deepLinks = listOf(navDeepLink<Detail>(basePath = "https://example.com/detail"))
) { /* ... */ }
```

Register the intent filter in the manifest with `android:autoVerify="true"` for App Links.
**Validate** every deep-link argument — treat it as untrusted input (a deep link is an
external entry point). Never trust a host/path to grant access; re-check authorization in
the destination.

## Attribution
Synthesized by IGRSoft (Apache-2.0) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
