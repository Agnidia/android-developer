#!/usr/bin/env bash
#
# run-checks.sh — repo lint aggregator (runs from any cwd via BASH_SOURCE).
#
# This repo has no validate.sh / test.sh / CI harness — its only pre-existing
# verification is the hooks' --self-test modes. This is the single entry point
# that ties those together with the prose linters. Every check runs to
# completion so one FATAL failure never masks the state of the others; the
# verdict and exit code reflect only the fatal checks. section-lint is advisory.
#
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${ROOT}"

status=OK
which=""
note_fail() { status=FAIL; if [ -z "${which}" ]; then which="$1"; else which="${which},$1"; fi; }

# (a) hook self-tests — FATAL. The repo's only existing checks; each hook feeds
#     itself a synthetic stdin fixture and asserts its JSON schema. They need
#     jq, so a missing jq is a hard failure with a clear message (not a skip).
echo "== hook self-tests =="
if ! command -v jq >/dev/null 2>&1; then
	echo "run-checks: FATAL hook self-tests require jq — install it (brew install jq)" >&2
	note_fail hooks-jq-missing
else
	for h in hooks/*.sh; do
		if bash "${h}" --self-test; then :; else note_fail "hook:$(basename "${h}" .sh)"; fi
	done
fi

# (b) description-length lint — FATAL. Self-test guards the parser, then real run.
echo "== desc-lint =="
if scripts/desc-lint.sh --self-test && scripts/desc-lint.sh; then :; else note_fail desc-lint; fi

# (c) command-registration bijection — FATAL. A command file that is not in
#     marketplace.json never loads, and a manifest entry with no file breaks
#     plugin install; both fail silently at runtime, so they fail loudly here.
echo "== command-registration =="
if scripts/check-command-registration.sh; then :; else note_fail command-registration; fi

# (d) parser fixture — FATAL. The counting helper in commands/build-test.md is a
#     shipped procedure with no other harness; the check extracts and exercises it,
#     and its single-block assertion is the by-reference-never-by-copy guard.
#     Exit 2 means the markdown moved, not that the helper broke — reporting a
#     fence-shape change as a helper regression sends the reader to the wrong file.
echo "== parser-fixture-check =="
if scripts/parser-fixture-check.sh >/dev/null; then
	echo "parser-fixture-check: ALL PASS"
elif [ $? -eq 2 ]; then
	echo "run-checks: FATAL parser-fixture-check could not extract a helper (markdown shape changed)" >&2
	note_fail parser-fixture-extraction
else
	note_fail parser-fixture
fi

# (e) section-length lint — WARN-ONLY: pre-existing prose-debt baseline. Never
#     fails the aggregate; surface the count so the burn-down stays visible.
echo "== section-lint (warn-only) =="
scripts/section-lint.sh --self-test || echo "run-checks: WARN section-lint self-test failed (parser regression?)"
sec_summary="$(scripts/section-lint.sh 2>/dev/null | tail -n1 || true)"
printf 'run-checks: WARN section-lint (warn-only): %s\n' "${sec_summary:-no summary}"

echo
if [ "${status}" = OK ]; then
	echo "run-checks: OK"
else
	echo "run-checks: FAIL (${which})"
	exit 1
fi
