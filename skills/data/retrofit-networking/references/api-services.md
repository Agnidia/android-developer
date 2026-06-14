# API Services

- One `interface` per resource group; `suspend fun` methods returning DTOs.
- Use `@Query`/`@Path`/`@Body`; never build URLs by string concatenation.
- Configure the converter (kotlinx.serialization recommended) once on the Retrofit
  instance.
- For paged endpoints, return a DTO with the page metadata and integrate with Paging 3 at
  the repository layer.

```kotlin
interface FeedApi {
    @GET("feed") suspend fun feed(@Query("page") page: Int): FeedPageDto
}
```

## Attribution
Synthesized by IGRSoft (MIT) from `piyushverma0`, `new-silvermoon`. No verbatim copying.
