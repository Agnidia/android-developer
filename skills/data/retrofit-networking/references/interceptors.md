# Interceptors

OkHttp 5 (`okhttp-bom:5.3.0` as of 2026-06; version from the catalog).

| Interceptor | Purpose | Note |
|-------------|---------|------|
| Auth | Inject `Authorization` header / refresh token | Use an `Authenticator` for 401-triggered refresh |
| Logging | `HttpLoggingInterceptor` | `BODY` only in debug — **never `BODY` in release** (leaks credentials/PII); use `NONE` |
| Retry/backoff | Retry idempotent requests on transient failures | Bound the attempts |
| Cache | OkHttp `Cache` for conditional GETs | Respect server cache headers |

Order matters: auth before logging so the logged request shows the header state you
expect; network interceptors vs application interceptors differ in whether they see cached
responses.

## Certificate pinning

Pin production certificates with OkHttp's `CertificatePinner` (or a
`network_security_config.xml` `<pin-set>`) so a compromised/rogue CA cannot MITM the app:

```kotlin
val pinner = CertificatePinner.Builder()
    .add("api.example.com", "sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")
    .build()
OkHttpClient.Builder().certificatePinner(pinner).build()
```

Keep a backup pin and a rotation plan — an expired/rotated leaf with no backup pin bricks
the app. Pinning is defence-in-depth on top of `cleartextTrafficPermitted="false"`.

## Attribution
Synthesized by IGRSoft (Apache-2.0) from `piyushverma0`, `new-silvermoon`. No verbatim copying.
