# Interceptors

| Interceptor | Purpose | Note |
|-------------|---------|------|
| Auth | Inject `Authorization` header / refresh token | Use an `Authenticator` for 401-triggered refresh |
| Logging | `HttpLoggingInterceptor` | `BODY` only in debug — `NONE` in release (leaks PII) |
| Retry/backoff | Retry idempotent requests on transient failures | Bound the attempts |
| Cache | OkHttp `Cache` for conditional GETs | Respect server cache headers |

Order matters: auth before logging so the logged request shows the header state you
expect; network interceptors vs application interceptors differ in whether they see cached
responses.

## Attribution
Synthesized by IGRSoft (MIT) from `piyushverma0`, `new-silvermoon`. No verbatim copying.
