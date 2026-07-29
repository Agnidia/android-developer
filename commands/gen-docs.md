---
description: Generate or update KDoc comments and Dokka/README API documentation for Kotlin and Compose code
argument-hint: [path or module (default .)] [--scope public|all] [--dokka]
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
estimated-cost:
  min-tokens: 3000
  max-tokens: 15000
  model-distribution:
    haiku: 20%
    sonnet: 70%
    opus: 10%
---

# Generate Documentation
<!-- Updated: June 2026 -->

Generate or update KDoc for Kotlin and Compose declarations, and refresh the module's
Dokka/README API reference. Delegates authoring to `android-developer`, then verifies the
result still compiles.

[Extended thinking: The value of generated docs is entirely in whether they say something
the signature does not. A KDoc that restates the parameter name is worse than none — it
looks maintained and isn't. So the rule below is explicit: document contracts, threading,
and lifecycle, never the obvious. Compose functions have their own contract surface (state
hoisting, modifier placement, recomposition cost) that is worth writing down.]

## CRITICAL BEHAVIORAL RULES

1. **Never restate the signature.** Document the contract — units, nullability meaning,
   threading/dispatcher expectations, lifecycle, failure modes. Drop any line a reader
   could derive from the declaration.
2. **Public surface first.** `public`/`open` declarations before `internal`; skip `private`
   unless `--scope all`.
3. **Delegate authoring to `android-developer:android-developer`** — one agent.
4. **Verify compilation** via `/android-developer:build-test` after edits; KDoc lives in
   source and a malformed block or import can break the build.
5. **Single-command Bash invocations** (`./gradlew dokkaHtml`).
6. **Never enter plan mode.**

## Usage

```bash
/android-developer:gen-docs :core:network
/android-developer:gen-docs app/src/main/java/com/x/CartRepository.kt
/android-developer:gen-docs :core:ui --dokka
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `path` | `.` | Module, package, or file to document. |
| `--scope public\|all` | `public` | `all` also documents `internal`/`private` declarations. |
| `--dokka` | off | Run `./gradlew dokkaHtml` afterwards and report the output path. |

## KDoc Conventions

```kotlin
/**
 * Loads the cart for [userId], preferring the local cache.
 *
 * Emits the cached cart immediately when one exists, then the network result.
 * Safe to collect from any dispatcher; the underlying I/O is confined to
 * [Dispatchers.IO].
 *
 * @param userId the authenticated user; an unauthenticated id yields [Result.failure].
 * @return a cold flow that re-emits on every local write.
 * @throws IllegalStateException if the database has not been migrated.
 * @see CartRepository.refresh
 */
```

| Element | Requirement |
|---------|-------------|
| Summary | One sentence, imperative, ends with a period. |
| `@param` | Only where the meaning is not in the name — constraints, units, ownership. |
| `@return` | Cold vs hot, emission timing, what an empty/failed result means. |
| `@throws` | Every checked failure mode a caller must handle. |
| Links | `[Symbol]` for cross-references so Dokka resolves them. |
| Threading | State the dispatcher/main-thread contract for anything doing I/O. |

**Composables** additionally document: which state is hoisted vs internal, where the
`modifier` parameter is applied, whether the function is expected to recompose frequently,
and any `@Preview` that demonstrates it (`skill: compose-best-practices`).

## Workflow

1. Enumerate the target's declarations and their current KDoc coverage
   (`git ls-files '*.kt'`, read the files).
2. **Delegate:**
   **Use Task tool with subagent_type="android-developer:android-developer"**
   Prompt: "Add or update KDoc for {scope} declarations in `{path}`. Follow the KDoc
   conventions above: document the contract (units, nullability meaning, dispatcher and
   main-thread expectations, lifecycle, failure modes), never restate the signature. For
   composables, document hoisted vs internal state, modifier placement, and recomposition
   cost per `skill: compose-best-practices`. Use `[Symbol]` links so Dokka resolves them.
   Leave a declaration undocumented rather than writing a placeholder."
3. If the module has a `README.md` with an API section, update it to match the new public
   surface — keep the existing structure.
4. **Verify:** run `/android-developer:build-test {module} --no-test` to confirm the source
   still compiles.
5. **`--dokka`:** `./gradlew :{module}:dokkaHtml 2>&1 | tee -a "$LOG"`; report the output
   directory.

## Output Format

```markdown
## Documentation
**Target:** {path}  **Scope:** {public|all}

| File | Declarations | Documented | Skipped |
|------|-------------:|-----------:|---------|
| CartRepository.kt | 8 | 8 | — |

**Build:** ✅ / ❌   **Dokka:** {output path | not run}

### Needs Manual Review
- {symbol} — {why: undocumented invariant, unclear ownership, ambiguous failure mode}
```

## Error Handling

### Dokka plugin absent
Report that `org.jetbrains.dokka` is not applied, skip `--dokka`, and keep the KDoc edits.

### Build breaks after edits
Report the compiler error with the file and line; do not attempt a second doc pass over
broken source.

## See Also
- `/android-developer:build-test` — the compile gate this command uses.
- `skill: compose-best-practices` — the composable contract surface worth documenting.
