#!/usr/bin/env bash
# PostToolUse → audit.jsonl writer (android-developer plugin, v1.11.0+).
# Reads CC hook stdin JSON (tool_name, tool_input, tool_use_id, duration_ms,
# effort.level, session_id) and appends one row to .context/logs/audit.jsonl
# with actor "android-developer:hook:audit-tooluse".
#
# ADVISORY ROW: android-developer agents run as subagents under an orchestrating plugin.
# When the orchestrator's own hooks are active, its rows are authoritative
# and these are advisory — the shared metadata.dedupe_key ("<session_id>:
# <tool_use_id>") lets the orchestrator's audit-dedup hook reconcile the two. When
# android-developer runs standalone, these rows stand alone.
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

# ---------- Advisory de-duplication ----------
# Every installed dev plugin registers its own copy of this hook, and all of them
# fire on the same event, so a single tool call landed in audit.jsonl six times
# (twelve for subagent-stop, which fires twice per stop). In one five-hour run
# that was 2,265 of 2,837 rows — 80% of the audit trail — and every reader
# (refine-branch-target.sh, publish-pl-issue.sh, the retrospective) paid to parse
# all of it.
#
# metadata.dedupe_key was already present and already identical across all
# copies; nothing consulted it. The header above promises "the orchestrator's
# audit-dedup hook" will reconcile these rows, but no such hook exists. Reconcile
# here instead: if this key is already on record, this row adds nothing.
#
# A tail window, not a full scan: the duplicate copies fire within milliseconds
# of each other, so the key is always near the end, and a whole-file grep would
# grow linearly with a log that reaches thousands of rows in a single run.
#
# The canonical (orchestrator) row is never suppressed by this — it is written by
# a different hook that carries no advisory flag and performs no such check.
DEDUPE_KEY=$(printf '%s' "$ROW" | jq -r '.metadata.dedupe_key // empty' 2>/dev/null || printf '')
if [ -n "$DEDUPE_KEY" ] && [ -f "$LOG_DIR/audit.jsonl" ] \
  && tail -n 400 "$LOG_DIR/audit.jsonl" 2>/dev/null \
     | grep -Fq "\"dedupe_key\":\"$DEDUPE_KEY\""; then
  exit 0
fi

printf '%s\n' "$ROW" >> "$LOG_DIR/audit.jsonl"
exit 0
