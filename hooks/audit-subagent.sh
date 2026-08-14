#!/usr/bin/env bash
# SubagentStop → audit.jsonl writer (android-developer plugin, v1.11.0+).
# Emits a `subagent_stopped` row with actor "android-developer:hook:audit-subagent".
#
# ADVISORY ROW: android-developer specialists run as subagents under an orchestrating plugin,
# whose SubagentStop hook also fires. To avoid double-counting,
# the orchestrator's rows are authoritative; these carry metadata.advisory=true and a
# matching metadata.dedupe_key ("<session_id>:<agent_id>:stop") so the orchestrator's
# audit-dedup.sh keeps the orchestrator row and drops this one. Standalone,
# these rows stand alone. This hook NEVER touches state.json —
# state.json merge is orchestrator-owned (the orchestrator's state-merge hook).
set -eu

SELF_TEST=0
[ "${1:-}" = "--self-test" ] && SELF_TEST=1

read_stdin() {
  if [ "$SELF_TEST" -eq 1 ]; then
    printf '%s' '{"agent_type":"android-developer:android-phone-developer","agent_id":"agt_test","session_id":"sess_test","duration_ms":12345,"parent_agent_id":"agt_parent"}'
  else
    cat
  fi
}

if ! command -v jq >/dev/null 2>&1; then
  echo "audit-subagent: jq not found, skipping" >&2
  exit 0
fi

PAYLOAD=$(read_stdin)
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.context/logs"
mkdir -p "$LOG_DIR"

ROW=$(printf '%s' "$PAYLOAD" | jq -c \
  --arg ts "$(date -u +%FT%TZ)" '
  {
    ts: $ts,
    actor: "android-developer:hook:audit-subagent",
    action: "subagent_stopped",
    subject: (.agent_type // "unknown"),
    result: (.status // "ok"),
    metadata: {
      advisory: true,
      duration_ms: ((.duration_ms // 0) | tonumber? // 0),
      effort: (.effort.level // env.CLAUDE_EFFORT // "unknown"),
      parent_agent_id: (.parent_agent_id // "none"),
      dedupe_key: ((.session_id // "nosession") + ":" + (.agent_id // "noagent") + ":stop"),
      dedupe_key_extended: ((.parent_agent_id // "none") + ":" + (.session_id // "nosession") + ":" + (.agent_id // "noagent") + ":stop")
    }
  }') || {
    echo "audit-subagent: jq parse failed" >&2
    exit 0
  }

if [ "$SELF_TEST" -eq 1 ]; then
  printf '%s\n' "$ROW" | jq -e '
    .metadata.dedupe_key == "sess_test:agt_test:stop"
    and .subject == "android-developer:android-phone-developer"
    and .metadata.advisory == true
    and .metadata.parent_agent_id == "agt_parent"
    and .metadata.dedupe_key_extended == "agt_parent:sess_test:agt_test:stop"
    and .actor == "android-developer:hook:audit-subagent"
  ' >/dev/null \
    || { echo "audit-subagent: self-test FAIL"; exit 1; }
  echo "audit-subagent: self-test OK"
  exit 0
fi

printf '%s\n' "$ROW" >> "$LOG_DIR/audit.jsonl"
exit 0
