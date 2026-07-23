# By-Feature Modularization

Each user-facing feature is a module that owns its ui/domain/data slice:

```
:feature:checkout
  ├── ui/      (composables, CheckoutViewModel)
  ├── domain/  (PlaceOrder use-case, interfaces)
  └── data/    (CheckoutRepositoryImpl)
```

Benefits: team ownership, parallel builds, and a clear blast radius. A feature depends on
`:core:*` modules and exposes a navigation entry point to `:app` — never a sibling
feature.

## Cross-feature communication
Route through `:app` (navigation) or a shared contract in `:core` — not a direct
`:feature:a → :feature:b` edge.

## Attribution
Synthesized by IGRSoft (Apache-2.0) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
