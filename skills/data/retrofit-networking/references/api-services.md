# API Services

- One `interface` per resource group; native `suspend fun` methods returning DTOs
  (Retrofit 3 — no RxJava `CallAdapter` or `Call.enqueue()` needed).
- Use `@Query`/`@Path`/`@Body`; never build URLs by string concatenation.
- Configure the **`converter-kotlinx-serialization`** converter
  (`Json.asConverterFactory(...)`) once on the Retrofit instance — the idiomatic Kotlin
  converter; do not default to Gson.
- Build the service with the reified extension: `val api: FeedApi = retrofit.create()`.
- For paged endpoints, return a DTO with the page metadata and integrate with Paging 3 at
  the repository layer.

```kotlin
interface FeedApi {
    @GET("feed") suspend fun feed(@Query("page") page: Int): FeedPageDto
}
```

## Attribution
Synthesized by IGRSoft (MIT) from `piyushverma0`, `new-silvermoon`. No verbatim copying.
