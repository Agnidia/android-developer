---
description: Select the best Android architecture pattern for a feature or module and produce a concrete package structure
argument-hint: <feature description or module scope> [--pattern clean-arch|mvi|mvvm|modularize]
allowed-tools: Read, Glob, Grep
estimated-cost:
  min-tokens: 3000
  max-tokens: 15000
  model-distribution:
    haiku: 20%
    sonnet: 70%
    opus: 10%
---

# Architecture Selection
<!-- Updated: June 2026 -->

Select the architecture for a new Android feature or module: capture the constraints,
delegate the choice to `kotlin-architector`, and return a concrete package structure with
module boundaries and injection points.

[Extended thinking: The failure mode here is picking a pattern by fashion — full clean-arch
with four modules for one screen, or a single God ViewModel for a state machine. Constraints
first (UI stack, state complexity, DI, module count, team convention), then the smallest
viable pattern. Read-only: this command decides and describes, it does not scaffold.]

## CRITICAL BEHAVIORAL RULES

1. **Read-only.** No `Write`/`Edit` in `allowed-tools`; this command recommends and
   describes structure. Scaffolding is a separate, explicit step.
2. **One agent.** `android-developer:kotlin-architector` makes the selection; the command
   gathers constraints and formats the report.
3. **Smallest viable pattern.** Do not recommend a new module split or a DI framework the
   constraints do not justify.
4. **Detect before recommending.** An existing convention in the repo outweighs a
   theoretically better pattern — flag the mismatch instead of silently switching.
5. **Never enter plan mode.**

## Usage

```bash
/android-developer:arch-select "offline-capable cart with optimistic updates"
/android-developer:arch-select :feature:profile --pattern mvi
/android-developer:arch-select . --pattern modularize
```

## Options

| Option | Default | Effect |
|--------|---------|--------|
| `feature description` \| `module` | required | What is being built, or the scope to structure. |
| `--pattern clean-arch\|mvi\|mvvm\|modularize` | auto | Validate a named pattern instead of choosing one. |

## Step 1: Capture Constraints

| Constraint | How to determine |
|-----------|-----------------|
| **UI stack** | Compose vs XML/Views — scan for `androidx.compose` in the build files |
| **State complexity** | Low (1-2 fields), Medium (5-10), High (explicit state machine) |
| **Event/effect model** | `StateFlow` + one-shot `Channel`, MVI `Intent`/`reduce`, or callbacks |
| **DI** | Hilt, Koin, manual — check for `@HiltAndroidApp` / `hilt` in the catalog. The plugin ships a Hilt playbook only (`skill: hilt-di`); on Koin or manual DI keep the recommendation framework-independent (constructor injection, scope lifetimes, no container access from `domain`) and say the detailed playbook does not cover that framework — never propose a migration to Hilt the constraints do not ask for |
| **Module count** | Single `:app`, layered (`:core:*`), or by-feature (`:feature:*`) |
| **Testing goals** | ViewModel unit tests, Turbine flow assertions, Compose UI/screenshot |
| **Existing convention** | The dominant pattern already in the repo, as a proxy for team familiarity |

If the argument is a description rather than code, ask for any missing critical constraint.

## Step 2: Selection

**Use Task tool with subagent_type="android-developer:kotlin-architector"**
Prompt: "Using `skill: architecture`, select the architecture for: {feature}. Constraints:
{constraints}. Candidates: clean-arch (`skill: clean-architecture`), MVI, MVVM +
`StateFlow` (`skill: viewmodel-stateflow`), modularization (`skill: modularization`), DI
via `skill: hilt-di`. If the user named a pattern, validate fit and report fit/mismatch
instead of substituting your own. Prefer the smallest viable pattern — do not add a module
split or a new DI framework the constraints do not justify. If the best fit combines
patterns, name one primary for the feature boundary and one secondary for the supporting
concern, and state which packages/modules each owns."

## Step 3: Package Structure

**Use Task tool with subagent_type="android-developer:kotlin-architector"**
Prompt: "For {pattern}, produce the concrete Gradle module + package structure for
`{feature}`: directory layout, file names, key interfaces (UseCase/Repository/ViewModel),
`StateFlow`/`Intent` types, Hilt module and binding points, and the `build.gradle.kts`
dependency edges between modules. UI stack: {Compose|Views|mixed}."

## Output Format

```markdown
## Architecture Selection: {feature}

**Pattern:** {name}  **Fit:** {fit|mismatch}  **UI:** {Compose|Views}  **DI:** {Hilt|Koin|manual}

### Reasons
- {1-2 reasons}
- **Alternative:** {closest fit and the trade-off, if mismatch}

### Constraints
| Factor | Value |
|--------|-------|
| State complexity | {low\|medium\|high} |
| Effect model | {StateFlow+Channel\|Intent/reduce\|callbacks} |
| Module strategy | {single\|by-layer\|by-feature} |

### Structure
{module + package tree}

### Boundaries
- **State:** {ViewModel/UiState/Intent types}
- **Dependencies:** {Hilt modules, binding points}
- **Concurrency:** {scopes, dispatchers, cancellation — `skill: coroutines-flow`}

### Testing Strategy
- {what to test, how to fake the repository, Turbine/Compose-test entry points}

### Next Steps
1. {first implementation step}
```

## Error Handling

### Scope too vague to constrain
Report which constraints are missing and ask for them; do not guess a pattern.

## See Also
- `skill: architecture` — pattern catalog and module strategy.
- `/android-developer:arch-review` — check an existing codebase against its pattern.
- `/android-developer:fix-refactor` — move existing code to the selected pattern.
