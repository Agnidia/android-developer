#!/usr/bin/env bash
# PreCompact → state checkpoint (android-developer plugin, v1.11.0+).
# Copies .context/state.json to .context/state.checkpoint-<ts>.json before
# auto-compaction so long android-developer sessions survive context summarization.
# Pairs with the PostCompact recovery prose in
# skills/_shared/workflow-integration/references/stage-details.md.
#
# When igrsoft is the orchestrator it owns state.json and runs its own
# precompact hook; this checkpoint is harmless and idempotent (timestamped
# copy). Exit code is always 0 — never blocks compaction.
set -eu

SELF_TEST=0
[ "${1:-}" = "--self-test" ] && SELF_TEST=1

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
CONTEXT_DIR="$PROJECT_DIR/.context"
LOG_DIR="$CONTEXT_DIR/logs"
STATE_FILE="$CONTEXT_DIR/state.json"

mkdir -p "$LOG_DIR"

TS=$(date -u +%Y%m%d-%H%M%S)
CHECKPOINT="$CONTEXT_DIR/state.checkpoint-$TS.json"

if [ "$SELF_TEST" -eq 1 ]; then
  TMP=$(mktemp -d)
  echo '{"run_index":0,"stages":{}}' > "$TMP/state.json"
  cp "$TMP/state.json" "$TMP/state.checkpoint-test.json"
  [ -f "$TMP/state.checkpoint-test.json" ] || { echo "precompact-checkpoint: self-test FAIL"; rm -rf "$TMP"; exit 1; }
  rm -rf "$TMP"
  echo "precompact-checkpoint: self-test OK"
  exit 0
fi

if [ ! -f "$STATE_FILE" ]; then
  if command -v jq >/dev/null 2>&1; then
    jq -cn --arg ts "$(date -u +%FT%TZ)" '{
      ts: $ts,
      actor: "android-developer:hook:precompact",
      action: "precompact_checkpoint",
      result: "skipped",
      metadata: { advisory: true, reason: "no state.json" }
    }' >> "$LOG_DIR/audit.jsonl" || true
  fi
  exit 0
fi

cp -p "$STATE_FILE" "$CHECKPOINT"

ARTIFACTS=$(find "$CONTEXT_DIR" -maxdepth 1 -type f \( \
  -name 'planning-*.md' -o -name 'coordination-*.md' -o -name 'development-*.md' \
\) 2>/dev/null | sort | jq -R . | jq -s . || echo '[]')

RUN_INDEX="unknown"
if command -v jq >/dev/null 2>&1; then
  RUN_INDEX=$(jq -r '.run_index // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")
fi

if command -v jq >/dev/null 2>&1; then
  jq -cn \
    --arg ts "$(date -u +%FT%TZ)" \
    --arg state_file "${CHECKPOINT#"$PROJECT_DIR"/}" \
    --arg run_index "$RUN_INDEX" \
    --argjson artifacts "$ARTIFACTS" '{
      ts: $ts,
      actor: "android-developer:hook:precompact",
      action: "precompact_checkpoint",
      result: "ok",
      metadata: {
        advisory: true,
        state_file: $state_file,
        run_index: $run_index,
        artifacts: $artifacts
      }
    }' >> "$LOG_DIR/audit.jsonl" || true
fi

exit 0
