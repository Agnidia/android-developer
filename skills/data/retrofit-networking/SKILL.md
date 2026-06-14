---
name: retrofit-networking
description: Retrofit + OkHttp networking: suspend API services, interceptors, and typed error handling. Use when calling a REST API, adding auth/logging interceptors, or modeling network errors.
license: MIT
metadata:
  author: IGRSoft
  last-updated: '2026-06-14'
  keywords: [retrofit, okhttp, networking, interceptor, error-handling, android]
---

# Retrofit Networking

Type-safe REST with `suspend` API methods.

✅ Correct — suspend service + result mapping at the boundary:

```kotlin
interface UserApi {
    @GET("users/{id}") suspend fun user(@Path("id") id: String): UserDto
}

suspend fun fetchUser(id: String): Result<User> = runCatching { api.user(id).toDomain() }
    .recoverCatching { throw it.toDomainError() }
```

❌ Mistake — leaking the DTO and swallowing errors:

```kotlin
suspend fun fetchUser(id: String): UserDto? = try { api.user(id) } catch (e: Exception) { null }
// WRONG: DTO escapes the data layer; error context lost; null hides the failure cause
```

## Interceptors

```kotlin
OkHttpClient.Builder()
    .addInterceptor { chain -> chain.proceed(chain.request().newBuilder().header("Authorization", "Bearer $token").build()) }
    .addInterceptor(HttpLoggingInterceptor().apply { level = if (DEBUG) BODY else NONE })  // never BODY in release — leaks PII
    .build()
```

## Error handling

Map HTTP/IO failures to a domain error type (timeout, unauthorized, server, network-off)
so the ViewModel renders the right state. Never expose raw `HttpException`/`IOException` to
the UI.

## See also
- [references/api-services.md](references/api-services.md)
- [references/interceptors.md](references/interceptors.md)

## Attribution
Synthesized by IGRSoft (MIT) from `piyushverma0`, `new-silvermoon`. No verbatim copying.
