#!/usr/bin/env bash
# PostToolUse → audit.jsonl writer (android-developer plugin, v1.11.0+).
# Reads CC hook stdin JSON (tool_name, tool_input, tool_use_id, duration_ms,
# effort.level, session_id) and appends one row to .context/logs/audit.jsonl
# with actor "android-developer:hook:audit-tooluse".
#
# ADVISORY ROW: android-developer agents run as subagents under the company-workflow
# orchestrator. When company-workflow's own hooks are active, its rows are authoritative
# and these are advisory — the shared metadata.dedupe_key ("<session_id>:
# <tool_use_id>") lets company-workflow's audit-dedup.sh reconcile the two. When
# android-developer runs standalone (no company-workflow), these rows stand alone.
#
# Self-test: pass --self-test to feed a synthetic fixture and assert schema.
set -eu

SELF_TEST=0
KIND="tool"
while [ $# -gt 0 ]; do
  case "$1" in
    --self-test) SELF_TEST=1 ;;
    --kind) shift; KIND="${1:-tool}"; continue ;;
  esac
  shift
done

read_stdin() {
  if [ "$SELF_TEST" -eq 1 ]; then
    printf '%s' '{"tool_name":"Write","tool_use_id":"toolu_test","duration_ms":42,"session_id":"sess_test","effort":{"level":"medium"}}'
  else
    cat
  fi
}

if ! command -v jq >/dev/null 2>&1; then
  echo "audit-tooluse: jq not found, skipping" >&2
  exit 0
fi

PAYLOAD=$(read_stdin)
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/.context/logs"
mkdir -p "$LOG_DIR"

ROW=$(printf '%s' "$PAYLOAD" | jq -c \
  --arg ts "$(date -u +%FT%TZ)" \
  --arg actor "android-developer:hook:audit-tooluse" \
  --arg kind "$KIND" '
  {
    ts: $ts,
    actor: $actor,
    action: "tool_invoked",
    subject: (.tool_name // "unknown"),
    result: "ok",
    metadata: {
      kind: $kind,
      advisory: true,
      duration_ms: ((.duration_ms // 0) | tonumber? // 0),
      effort: (.effort.level // env.CLAUDE_EFFORT // "unknown"),
      dedupe_key: ((.session_id // "nosession") + ":" + (.tool_use_id // "notoolid"))
    }
  }') || {
    echo "audit-tooluse: jq parse failed" >&2
    exit 0
  }

if [ "$SELF_TEST" -eq 1 ]; then
  printf '%s\n' "$ROW" | jq -e '.metadata.dedupe_key == "sess_test:toolu_test" and .metadata.duration_ms == 42 and .metadata.effort == "medium" and .metadata.advisory == true and .actor == "android-developer:hook:audit-tooluse"' >/dev/null \
    || { echo "audit-tooluse: self-test FAIL"; exit 1; }
  echo "audit-tooluse: self-test OK"
  exit 0
fi

printf '%s\n' "$ROW" >> "$LOG_DIR/audit.jsonl"
exit 0
