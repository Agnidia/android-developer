# Color Roles

Material 3 defines semantic roles, each with an `on` pair for content contrast:

| Role | Use for | Content role |
|------|---------|--------------|
| `primary` | Key actions, FAB | `onPrimary` |
| `secondary`/`tertiary` | Less-prominent accents | `onSecondary`/`onTertiary` |
| `surface` / `surfaceVariant` | Backgrounds, cards | `onSurface` / `onSurfaceVariant` |
| `error` | Errors, validation | `onError` |
| `outline` | Borders, dividers | — |

Pairing `xxx`/`onXxx` guarantees WCAG contrast across light/dark/dynamic schemes. Avoid
mixing roles (e.g. `onPrimary` text on a `surface` background) — contrast is only
guaranteed within a pair.

## Attribution
Synthesized by Agnidia (Apache-2.0) from `new-silvermoon`, `ayush016`. No verbatim copying.
