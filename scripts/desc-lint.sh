#!/usr/bin/env bash
#
# desc-lint.sh — frontmatter description-length lint (three-tier caps).
#
# Frontmatter descriptions are AMBIENT: Claude Code injects them into every
# session's startup context in every project with the plugin enabled.
# Multi-line YAML scalars (`description: |` / `>`) hide overruns from
# single-line greps — this lint joins continuation lines before measuring.
# A file with NO frontmatter (e.g. agents/_base/platform-agent.md) has nothing
# to lint and is skipped silently — absence is not a violation.
#
# All three caps are REGRESSION BRAKES set just above this repo's current
# reality, NOT targets. They freeze the status quo so descriptions cannot grow
# unnoticed; tightening toward the ~250 ideal is an eval-gated follow-up (does
# a shorter description still route/fire correctly?), never a blind edit here.
#
#   agents/**          → 500  — ALL SEVEN agents already exceed 250 (max ~465,
#                               security-auditor), so the sibling plugins' 250
#                               cap would fail this repo today; the 250-target
#                               diet is deferred, do not tighten here.
#   commands/**        → 250  — current max ~233, green; this tier holds the
#                               CC ~250 guidance since commands fit under it.
#   skills/**/SKILL.md → 500  — covers EVERY SKILL.md, the top-level
#                               skills/SKILL.md index INCLUDED (family
#                               consistency with the sibling plugins). The
#                               index is a plugin router blurb (~456 chars) and
#                               the brake sits just above it; the domain skill
#                               descriptions are trigger-engineered and all sit
#                               ≤320 (max material3-expressive), comfortably
#                               under — a diet pending measured trigger evals.
#
# Usage:
#   scripts/desc-lint.sh              # lint agents/**, commands/**, skills/**/SKILL.md
#   scripts/desc-lint.sh <file> [...] # lint specific files
#   scripts/desc-lint.sh --self-test  # verify the parser against inline fixtures
#
# Exit codes: 0 = all within cap, 1 = at least one over cap, 2 = usage/parser error.
#
# CI / repo-maintenance helper only — never read by agents at runtime.
#
set -Eeuo pipefail

lint() {
	python3 - "$@" <<'PYEOF'
import re, sys

def cap_for(path):
    # Segment-anchored so both repo-relative (agents/..) and self-test
    # temp paths (/tmp/x/agents/..) classify identically. Order matters:
    # skills first, then commands, else the agent default.
    if re.search(r'(^|/)skills/', path):
        return 500
    if re.search(r'(^|/)commands/', path):
        return 250
    return 500  # agents/, agents/_base/, and any unclassified path

def desc_len(path):
    try:
        t = open(path, encoding='utf-8').read()
    except OSError as e:
        print(f"desc-lint: cannot read {path}: {e}", file=sys.stderr)
        return None
    m = re.match(r'^---\r?\n(.*?)\r?\n---', t, re.S)
    if not m:
        return None  # no frontmatter — nothing to lint (skipped silently)
    out, cap = [], False
    for ln in m.group(1).split('\n'):
        if re.match(r'^description:', ln):
            cap = True
            v = ln.split(':', 1)[1].strip()
            if v and v not in ('|', '>', '|-', '>-'):
                out.append(v)
            continue
        if cap:
            if re.match(r'^\S', ln):
                break  # next top-level key
            out.append(ln.strip())
    return len(' '.join(' '.join(out).split())) if out else 0

fail = 0
for path in sys.argv[1:]:
    n = desc_len(path)
    if n is None:
        continue
    cap = cap_for(path)
    if n > cap:
        fail = 1
        print(f"desc-lint: {path}: {n} chars (cap {cap}) — OVER")
    else:
        print(f"desc-lint: {path}: {n} chars (cap {cap}) ok")
sys.exit(fail)
PYEOF
}

self_test() {
	td=$(mktemp -d -t desc-lint-XXXXXX)
	trap 'rm -rf "${td}"' EXIT
	mkdir -p "${td}/agents" "${td}/commands" "${td}/skills"

	# --- agents tier (cap 500) ---
	# pass: >250 (would fail the command tier) but <500
	ag_ok=$(printf 'a%.0s' {1..400})
	printf -- '---\nname: a\ndescription: %s\n---\nbody\n' "${ag_ok}" >"${td}/agents/ok.md"
	# fail: over 500
	ag_bad=$(printf 'a%.0s' {1..550})
	printf -- '---\nname: a\ndescription: %s\n---\nbody\n' "${ag_bad}" >"${td}/agents/bad.md"

	# --- commands tier (cap 250) ---
	# pass: within 250
	printf -- '---\nname: c\ndescription: short and sweet command blurb\n---\nbody\n' >"${td}/commands/ok.md"
	# fail: over 250 (multi-line block scalar — exercises continuation joining)
	cm_bad=$(printf 'c%.0s' {1..140})
	printf -- '---\nname: c\ndescription: |\n  %s\n  %s\n---\nbody\n' "${cm_bad}" "${cm_bad}" >"${td}/commands/bad.md"

	# --- skills tier (cap 500) ---
	# pass: >400 (would fail the agent tier's neighbour) but <500 — brake sits
	# above the ~456 root index this tier now covers
	sk_ok=$(printf 's%.0s' {1..470})
	printf -- '---\nname: s\ndescription: %s\n---\nbody\n' "${sk_ok}" >"${td}/skills/SKILL.md"
	# fail: over 500
	sk_bad=$(printf 's%.0s' {1..550})
	printf -- '---\nname: s\ndescription: %s\n---\nbody\n' "${sk_bad}" >"${td}/skills/bad.md"

	# no frontmatter — must be skipped silently, not an error (platform-agent.md)
	printf -- '# plain markdown\nbody\n' >"${td}/nofm.md"

	if ! lint "${td}/agents/ok.md" "${td}/commands/ok.md" "${td}/skills/SKILL.md" "${td}/nofm.md" >/dev/null; then
		echo "desc-lint self-test: FAIL (within-cap or no-frontmatter fixture flagged)" >&2; exit 2
	fi
	if [ -n "$(lint "${td}/nofm.md")" ]; then
		echo "desc-lint self-test: FAIL (no-frontmatter file produced output)" >&2; exit 2
	fi
	if lint "${td}/agents/bad.md" >/dev/null; then
		echo "desc-lint self-test: FAIL (agents-tier over fixture passed)" >&2; exit 2
	fi
	if lint "${td}/commands/bad.md" >/dev/null; then
		echo "desc-lint self-test: FAIL (commands-tier over fixture passed)" >&2; exit 2
	fi
	if lint "${td}/skills/bad.md" >/dev/null; then
		echo "desc-lint self-test: FAIL (skills-tier over fixture passed)" >&2; exit 2
	fi
	echo "desc-lint self-test: ALL PASS"
}

repo_files() {
	# skills tier covers EVERY SKILL.md, the top-level skills/SKILL.md index
	# INCLUDED (family consistency with the sibling plugins) — see header.
	git ls-files -- 'agents/*.md' 'agents/_base/*.md' 'commands/*.md' \
		'skills/SKILL.md' 'skills/**/SKILL.md' \
		| sort -u
}

case "${1:-}" in
	--self-test) self_test ;;
	"")
		cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
		# shellcheck disable=SC2046 # repo_files emits one clean path per line
		lint $(repo_files) | { grep -v ' ok$' || true; }
		;;
	*) lint "$@" ;;
esac
