# Repository Pattern

The repository is the single entry point to a data type. It:

- exposes reads as `Flow` sourced from the DB (single source of truth);
- performs writes that update the DB (which re-emits to observers);
- maps DTO/entity ↔ domain at its boundary;
- never exposes Room/Retrofit types to callers.

The interface lives in `domain`; the implementation in `data` (dependency inversion). The
ViewModel depends on the interface, so tests substitute a fake repository.

## Attribution
Synthesized by Agnidia (Apache-2.0) from `piyushverma0`, `new-silvermoon`. No verbatim copying.
