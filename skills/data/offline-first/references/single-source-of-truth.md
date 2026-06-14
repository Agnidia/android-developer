# Single Source of Truth

Exactly one place holds the canonical data — normally the local DB. Everything else (UI,
network responses) is a view of, or an update to, that source.

```
network ──refresh──▶ DB (SSOT) ──Flow──▶ repository ──▶ ViewModel ──▶ UI
```

Benefits: the UI shows cached data instantly and offline; a single write path means no two
screens disagree; reactivity is automatic (the DB re-emits on change). Never let the UI
read the network directly in parallel with the DB — that reintroduces divergence.

## Attribution
Synthesized by IGRSoft (MIT) from `piyushverma0`, `new-silvermoon`. No verbatim copying.
