---
name: retrofit-networking
description: Retrofit + OkHttp networking: suspend API services, interceptors, and typed error handling. Use when calling a REST API, adding auth/logging interceptors, or modeling network errors.
license: Apache-2.0
metadata:
  author: Agnidia
  last-updated: '2026-06-15'
  keywords: [retrofit, okhttp, ktor, networking, interceptor, error-handling, kmp, android]
---

# Retrofit Networking

Type-safe REST with native `suspend` API methods. **Retrofit 3** (`3.0.0` as of 2026-06)
over **OkHttp 5** (pin `okhttp-bom:5.3.0` as of 2026-06 and declare artifacts without a
version); wire it with the idiomatic **`converter-kotlinx-serialization`** converter — not
Gson. Versions come from the catalog.

✅ Correct — suspend service + result mapping at the boundary:

```kotlin
interface UserApi {
    @GET("users/{id}") suspend fun user(@Path("id") id: String): UserDto
}

// reified create() (Kotlin extension)
val api: UserApi = retrofit.create()

suspend fun fetchUser(id: String): Result<User> = runCatching { api.user(id).toDomain() }
    .recoverCatching { throw it.toDomainError() }
```

❌ Mistake — leaking the DTO and swallowing errors:

```kotlin
suspend fun fetchUser(id: String): UserDto? = try { api.user(id) } catch (e: Exception) { null }
// WRONG: DTO escapes the data layer; error context lost; null hides the failure cause
```

## Converter

Configure the converter once on the Retrofit instance. `kotlinx.serialization` is idiomatic
for Kotlin (`@Serializable` DTOs, no reflection):

```kotlin
val json = Json { ignoreUnknownKeys = true }
val retrofit = Retrofit.Builder()
    .baseUrl(BASE_URL)
    .client(okHttp)
    .addConverterFactory(json.asConverterFactory("application/json".toMediaType()))
    .build()
```

## Interceptors

```kotlin
OkHttpClient.Builder()
    .addInterceptor { chain -> chain.proceed(chain.request().newBuilder().header("Authorization", "Bearer $token").build()) }
    .addInterceptor(HttpLoggingInterceptor().apply { level = if (DEBUG) BODY else NONE })  // never BODY in release — leaks PII
    .certificatePinner(CertificatePinner.Builder().add(HOST, "sha256/…").build())          // pin production certs
    .build()
```

## Error handling

Map HTTP/IO failures to a domain error type (timeout, unauthorized, server, network-off)
so the ViewModel renders the right state. Never expose raw `HttpException`/`IOException` to
the UI.

## KMP (shared networking)

Retrofit is JVM/Android only. When networking is shared across platforms, use **Ktor**
(`3.5.0` as of 2026-06) in `commonMain` — `HttpClient` + the kotlinx.serialization
content-negotiation plugin reuse the same DTOs as the rest of the data layer. OkHttp 5 is
itself a KMP library (Gradle auto-selects `okhttp-jvm`/`okhttp-android`).

## See also
- [references/api-services.md](references/api-services.md)
- [references/interceptors.md](references/interceptors.md)

## Attribution
Synthesized by Agnidia (Apache-2.0) from `piyushverma0`, `new-silvermoon`. No verbatim copying.
