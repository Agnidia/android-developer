# Hilt Scope Selection

| Scope | Component | Lifetime | Typical binding |
|-------|-----------|----------|-----------------|
| `@Singleton` | SingletonComponent | App | Retrofit, Room, DataStore, repositories |
| `@ActivityRetainedScoped` | ActivityRetainedComponent | Across config changes | Navigation state holders |
| `@ViewModelScoped` | ViewModelComponent | One ViewModel | Per-ViewModel collaborators |
| `@ActivityScoped` | ActivityComponent | One Activity | Activity-bound services |

Unscoped bindings produce a new instance at each injection point — correct for stateless
helpers, wrong for anything holding state or expensive to create.

Over-scoping (`@Singleton` on per-screen state) is a memory leak and a stale-state bug.
Pick the **narrowest** scope that satisfies the lifetime requirement.

## Attribution
Synthesized by IGRSoft (MIT) from `new-silvermoon`, `piyushverma0`. No verbatim copying.
