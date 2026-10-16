# By-Layer Modularization

Shared infrastructure split by technical concern, consumed by features:

```
:core:domain   (pure Kotlin)
:core:data     → :core:domain, :core:network, :core:database
:core:ui       (theme, design-system composables)
:core:network  (Retrofit/OkHttp setup)
:core:database (Room setup)
```

Use by-layer for cross-cutting infrastructure; combine with by-feature for the
feature slices. Avoid a single god `:core` — split until each module has one reason to
change.

## Attribution
Synthesized by Agnidia (Apache-2.0) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
