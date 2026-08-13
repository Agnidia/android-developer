# android-developer hooks

Plugin-scoped hook scripts (added v1.11.0). They give android-developer agents
their own audit trail and pre-compaction checkpoint when the plugin runs
**standalone** — and degrade cleanly to *advisory* rows when android-developer
agents run as subagents under the **corpflow** orchestrator.

| Script | Event | Purpose |
|--------|-------|---------|
| `audit-tooluse.sh` | `PostToolUse` (Write\|Edit\|TaskUpdate\|TaskCreate) | Append a `tool_invoked` row to `.context/logs/audit.jsonl`. |
| `audit-subagent.sh` | `SubagentStop` | Append a `subagent_stopped` row. |
| `precompact-checkpoint.sh` | `PreCompact` | Copy `.context/state.json` to a timestamped checkpoint. |

## Advisory / dedup contract (CRITICAL)

android-developer specialists are spawned **as subagents under corpflow's
orchestrator**, whose own hooks (`hooks/audit-tooluse.sh`,
`hooks/audit-subagent.sh`) fire for the same events. To avoid double-counting:

- Every row written here carries `metadata.advisory: true`.
- Rows share the **same `metadata.dedupe_key`** shape as corpflow
  (`<session_id>:<tool_use_id>` for tools, `<session_id>:<agent_id>:stop` for
  subagents) plus `dedupe_key_extended` (parent_agent_id-prefixed).
- corpflow's `hooks/audit-dedup.sh` keeps the **orchestrator** row authoritative
  and drops the advisory duplicate. Readers prefer `actor: "hook:*"` over
  `actor: "android-developer:hook:*"` when `dedupe_key` collides.

`audit-subagent.sh` **never** touches `state.json` — the three-layer state
merge (`state-merge.sh`) stays orchestrator-owned. android-developer only reads
and checkpoints state, never merges it.

## Self-test

Each script accepts `--self-test`: feeds a synthetic stdin fixture, asserts the
emitted JSON schema, prints `… self-test OK`, and exits 0.

```bash
for h in hooks/*.sh; do bash "$h" --self-test || echo "FAIL: $h"; done
```

Wiring lives in `.claude-plugin/plugin.json` under the `hooks` key, referenced
as `${CLAUDE_PLUGIN_ROOT}/hooks/<script>.sh`. All hooks require `jq`; if absent
they skip silently (exit 0) and never block the tool call or compaction.
