#!/usr/bin/env bash
# Command registration bijection check (android-developer plugin, v1.3.0+).
# Verifies that .claude-plugin/marketplace.json's command list matches the
# Markdown files in commands/ exactly. Only the top level is scanned, so a
# future commands/_shared/ helper directory stays intentionally unregistered
# (as in apple-developer, this script's origin). Exit 0 on match; exit 1 and
# print the delta on any drift. Dependency-free (no jq) — safe for CI.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
manifest="$root/.claude-plugin/marketplace.json"
cmd_dir="$root/commands"

# Registered command basenames (from the ./commands/<name>.md entries).
registered="$(grep -oE '\./commands/[A-Za-z0-9-]+\.md' "$manifest" \
  | sed 's#\./commands/##; s#\.md$##' | sort -u)"

# On-disk command basenames (top level only — see header).
ondisk="$(find "$cmd_dir" -maxdepth 1 -name '*.md' -exec basename {} .md \; | sort -u)"

if [ "$registered" = "$ondisk" ]; then
  count="$(printf '%s\n' "$ondisk" | grep -c .)"
  echo "OK: command registration bijection intact ($count commands)."
  exit 0
fi

echo "DRIFT: marketplace.json command list does not match commands/*.md" >&2
echo "--- registered but missing on disk ---" >&2
comm -23 <(printf '%s\n' "$registered") <(printf '%s\n' "$ondisk") >&2 || true
echo "--- on disk but not registered ---" >&2
comm -13 <(printf '%s\n' "$registered") <(printf '%s\n' "$ondisk") >&2 || true
exit 1
