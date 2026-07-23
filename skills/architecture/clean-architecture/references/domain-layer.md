# Keeping the Domain Layer Pure

The `domain` module is plain Kotlin (a `kotlin("jvm")` module, or a `commonMain` source set
in a Kotlin Multiplatform module — not an Android library). This is enforced structurally:
if `domain` cannot depend on `androidx.*`, framework types cannot leak in. The same
constraint makes the layer KMP-ready: a pure `commonMain` domain is shareable with
iOS/desktop as-is.

✅ Pure domain model:
```kotlin
@JvmInline value class UserId(val value: String)
data class User(val id: UserId, val name: String, val email: String)
```

❌ Leaked framework type:
```kotlin
import android.os.Parcelable   // WRONG in domain — Parcelable is a framework concern
```

If a domain type must be parcelable for navigation, define a separate UI model in `ui`
and map to it — do not annotate the domain model.

## Result modeling

Model expected failures as data, not exceptions, where it aids the caller:

```kotlin
sealed interface CartError { data object Empty : CartError; data class OutOfStock(val sku: String) : CartError }
```

## Attribution
Synthesized by IGRSoft (Apache-2.0) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
