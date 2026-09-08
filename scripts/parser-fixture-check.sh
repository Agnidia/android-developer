#!/usr/bin/env bash
#
# parser-fixture-check.sh — assert the build-test result-reading helpers.
#
# Both helpers are EXTRACTED from commands/build-test.md rather than copied
# here: a fixture that passes against a retyped variant proves nothing about
# the snippet that actually ships. Extraction scans every git-tracked *.md path
# in the repository and requires each helper to be defined in exactly ONE
# ```bash fence across all of them, which is also the by-reference-never-by-copy
# guard. Its reach is that and only that: a copy in a non-markdown file, in an
# untracked file, or outside a ```bash fence is not seen.
#
# Three layers:
#   parser   — sums, executed = tests - skipped, empty/missing dir, decoy attr
#   outcome  — outcome_of against a fixture log, incl. the compile-task anchor
#   table    — every (outcome x result-XML) pair the run can reach resolves to
#              exactly one verdict row, and the verdicts the design turns on are
#              pinned. The domain and the shipped table must agree in BOTH
#              directions: a row naming an unknown token fails, and a domain
#              member no row names fails. Delegation is read out of the prose and
#              cross-checked, not restated. Structural only — the table's PASS/FAIL
#              prose is not executed and has never met a Gradle build.
#
# Usage:
#   scripts/parser-fixture-check.sh
#
# Exit codes: 0 = all branches hold, 1 = an assertion failed,
#             2 = extraction/structure error (the markdown moved, not the logic).
#
# CI / repo-maintenance helper only — never read by agents at runtime.
#
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/.."

extract() { # $1=helper name — prints the sole fenced bash block defining it
	python3 - "$1" <<'PYEOF' || exit 2
import os, re, subprocess, sys
name = sys.argv[1]
files = subprocess.run(
    ['git', 'ls-files', '--', '*.md', 'agents/*.md', 'commands/*.md', 'skills/**/*.md'],
    capture_output=True, text=True, check=True).stdout.split()
hits = []
for f in sorted(set(files)):
    if not os.path.exists(f):        # tracked but absent: cannot hold a copy
        continue
    for b in re.findall(r'```bash\n(.*?)```', open(f, encoding='utf-8').read(), re.S):
        if re.search(rf'^\s*{name}\(\)', b, re.M):
            hits.append((f, b))
if len(hits) != 1:
    where = ', '.join(f for f, _ in hits) or 'nowhere'
    print(f"parser-fixture-check: expected 1 {name}() block tree-wide, found "
          f"{len(hits)} ({where})", file=sys.stderr)
    sys.exit(2)
# strip the markdown list indent the block may sit under; the code is unchanged
print('\n'.join(l[3:] if l.startswith('   ') else l for l in hits[0][1].split('\n')))
PYEOF
}

SUM_ATTR="$(extract sum_attr)"
OUTCOME_OF="$(extract outcome_of)"
echo "--- helpers under test (extracted from the repo's markdown) ---"
printf '%s\n%s\n' "${SUM_ATTR}" "${OUTCOME_OF}"
eval "${SUM_ATTR}"
eval "${OUTCOME_OF}"

TD="$(mktemp -d -t parser-fixture-XXXXXX)"
trap 'rm -rf "${TD}"' EXIT

fail=0
assert() { # $1=label $2=expected $3=actual
	if [ "$2" = "$3" ]; then
		echo "PASS  $1 => $3"
	else
		echo "FAIL  $1: expected $2, got $3"
		fail=1
	fi
}

# ---------------------------------------------------------------- parser layer
mk() { # $1=dir $2=name $3=tests $4=skipped
	mkdir -p "$1"
	printf '<?xml version="1.0" encoding="UTF-8"?>\n<testsuite name="com.foo.tests.BarTest" tests="%s" skipped="%s" failures="0" errors="0" time="0.1">\n<testcase name="a" classname="com.foo.tests.BarTest"/>\n</testsuite>\n' "$3" "$4" >"$1/TEST-$2.xml"
}
executed() { echo $(( $(sum_attr tests "$1") - $(sum_attr skipped "$1") )); }

A="${TD}/two"; mk "${A}" One 9 1; mk "${A}" Two 9 1
assert "two files 9/1 -> executed" 16 "$(executed "${A}")"
assert "  (raw tests sum, decoy name= attr present)" 18 "$(sum_attr tests "${A}")"
assert "  (raw skipped sum)" 2 "$(sum_attr skipped "${A}")"

B="${TD}/allskipped"; mk "${B}" Three 3 3
assert "one file 3/3 -> executed (verdict FAIL)" 0 "$(executed "${B}")"

C="${TD}/empty"; mkdir -p "${C}"
assert "empty dir -> executed (verdict no-results, FAIL)" 0 "$(executed "${C}")"

D="${TD}/does-not-exist"
assert "missing dir -> executed (verdict no-results, FAIL)" 0 "$(executed "${D}")"

E="${TD}/decoy"; mkdir -p "${E}"
printf '<testsuite name="com.foo.tests.BarTest" tests="4" skipped="0" failures="0" errors="0"/>\n' \
	>"${E}/TEST-Decoy.xml"
assert "decoy name= does not corrupt the tests sum" 4 "$(sum_attr tests "${E}")"

M="${TD}/marker"; touch "${M}"; sleep 1; mk "${TD}/fresh" Fresh 2 0
if find "${TD}/fresh" -name 'TEST-*.xml' -newer "${M}" | grep -q .; then
	echo "PASS  marker: files written after the marker are fresh"
else
	echo "FAIL  marker: fresh files not detected"; fail=1
fi
if find "${A}" -name 'TEST-*.xml' -newer "${M}" | grep -q .; then
	echo "FAIL  marker: pre-marker files reported fresh"; fail=1
else
	echo "PASS  marker: pre-marker files are stale, not fresh"
fi

# --------------------------------------------------------------- outcome layer
# outcome_of closes over $TASK, exactly as Phase 4 binds it.
TASK=":app:testDebugUnitTest"
# The outcome domain, and the ONLY place it is written. Gradle's own closed set is
# org.gradle.testkit.runner.TaskOutcome: SUCCESS, FAILED, UP_TO_DATE, SKIPPED,
# FROM_CACHE, NO_SOURCE — the console prints those five labels hyphenated and prints
# nothing at all for SUCCESS, which is `executed` here. `unresolved` is the one
# synthetic member: no such task line in the log. Check the enum, do not re-derive the
# list; it has been wrong twice. The table layer fails if the shipped table and this
# list disagree in EITHER direction, because a list asserted here and never
# contradicted is exactly how SKIPPED went missing.
OUTCOMES=(executed FAILED UP-TO-DATE FROM-CACHE SKIPPED NO-SOURCE unresolved)
log_with() { printf '> Task :app:compileDebugUnitTestKotlin\n%s\n> Task :app:jacocoTestReport\n' "$1" >"${TD}/log"; echo "${TD}/log"; }

assert "outcome: bare task line" executed "$(outcome_of "$(log_with '> Task :app:testDebugUnitTest')")"
for w in "${OUTCOMES[@]}"; do
	# `executed` and `unresolved` are not printed labels; they have their own cases here.
	case "${w}" in executed | unresolved) continue ;; esac
	assert "outcome: ${w}" "${w}" "$(outcome_of "$(log_with "> Task :app:testDebugUnitTest ${w}")")"
done
: >"${TD}/empty.log"
assert "outcome: empty log" unresolved "$(outcome_of "${TD}/empty.log")"
printf '> Task :app:compileDebugUnitTestKotlin FAILED\n> Task :app:jacocoTestReport\n' >"${TD}/compile.log"
assert "outcome: test-compile failure is NOT a test outcome" unresolved "$(outcome_of "${TD}/compile.log")"
printf '> Task :other:testDebugUnitTest FAILED\n' >"${TD}/other.log"
assert "outcome: another module's task is not ours" unresolved "$(outcome_of "${TD}/other.log")"

# ----------------------------------------------------------------- table layer
# Totality over the PRODUCT of both axes. Keying on `OUTCOME` alone cannot see a
# missing row on the freshness axis, because `fresh` and `stale` share an outcome.
MAP="$(python3 - "${OUTCOMES[@]}" <<'PYEOF' || exit 2
import itertools, re, sys
XML = ['fresh', 'stale only', 'none']
outcomes = sys.argv[1:]
t = open('commands/build-test.md', encoding='utf-8').read()
m = re.search(r'\n### The table\n(.*?)(?=\n#{2,6} )', t, re.S)
if not m:
    print("parser-fixture-check: '### The table' not found", file=sys.stderr)
    sys.exit(2)
def axis(cell, domain, which):
    """Expand a cell into a subset of `domain`, REJECTING any token outside it.

    Intersecting instead of rejecting is what makes a totality check lie: an
    unknown token silently drops, its row goes inert, and the check stays green."""
    toks = [p.strip().strip('`') for p in cell.split('/')]
    if 'any' in toks:
        return set(domain)
    unknown = [x for x in toks if x not in domain]
    if unknown:
        print(f"parser-fixture-check: verdict table names {which} "
              f"{', '.join(unknown)}, which the asserted domain does not contain — "
              f"add it there (and to the fixtures) or fix the row", file=sys.stderr)
        sys.exit(2)
    return set(toks)

rows = []
for ln in m.group(1).split('\n'):
    if not ln.startswith('|') or re.match(r'^\|[\s|:-]+\|$', ln):
        continue
    c = [x.strip() for x in ln.strip('|').split('|')]
    if len(c) < 3 or c[0] == '`OUTCOME`':
        continue
    rows.append((axis(c[0], outcomes, 'outcome'), axis(c[1], XML, 'result-XML state'),
                 c[2].strip('`'), c[0]))
if not rows:
    print("parser-fixture-check: verdict table has no rows", file=sys.stderr)
    sys.exit(2)

# The other direction: an outcome in the domain that no row names on its own is
# reachable only through an `any` row, which is how a missing case hides.
named = {o for _, _, _, cell in rows for o in
         [p.strip().strip('`') for p in cell.split('/')] if o != 'any'}
for o in outcomes:
    if o not in named:
        print(f"!unnamed|{o}")

# The non-delegating verdicts, read from the prose rather than restated: whichever
# verdicts the sentence that says "without delegating" names.
av = re.search(r'\n### After the verdict\n(.*?)(?=\n#{2,6} |\Z)', t, re.S)
if not av:
    print("parser-fixture-check: '### After the verdict' not found", file=sys.stderr)
    sys.exit(2)
sent = re.search(r'([^.]*?)\*\*without delegating\*\*', av.group(1), re.S)
if not sent:
    print("parser-fixture-check: no 'without delegating' sentence to read the rule from",
          file=sys.stderr)
    sys.exit(2)
for v in re.findall(r'`([^`]+)`', sent.group(1)):
    print(f"!nodelegate|{v}")
for o, x in itertools.product(outcomes, XML):
    hit = next((v for ro, rx, v, _ in rows if o in ro and x in rx), '-')
    print(f"{o}|{x}|{hit}")
PYEOF
)"
NODELEGATE=$(printf '%s\n' "${MAP}" | grep '^!nodelegate|' | cut -d'|' -f2 || true)
MAP=$(printf '%s\n' "${MAP}" | grep -v '^!nodelegate|' || true)
unnamed=$(printf '%s\n' "${MAP}" | grep '^!unnamed|' | cut -d'|' -f2 || true)
MAP=$(printf '%s\n' "${MAP}" | grep -v '^!unnamed|' || true)
if [ -n "${unnamed}" ]; then
	for o in ${unnamed}; do
		echo "FAIL  table: ${o} is in the outcome domain but no row names it"
	done
	fail=1
fi
combos=$(printf '%s\n' "${MAP}" | grep -c .)
missing=$(printf '%s\n' "${MAP}" | grep -c '|-$' || true)
if [ "${missing}" -eq 0 ]; then
	echo "PASS  table: all ${combos} (outcome x result-XML) combinations resolve"
else
	echo "FAIL  table: ${missing} of ${combos} combinations resolve to no row:"
	printf '%s\n' "${MAP}" | grep '|-$' | sed 's/^/        /'
	fail=1
fi

# Pin the verdicts the design turns on, so a row can be neither dropped nor widened
# into another's cases without saying so here.
pin() { # $1=outcome $2=xml state $3=expected verdict
	assert "table: $1 + $2" "$3" "$(printf '%s\n' "${MAP}" | awk -F'|' -v o="$1" -v x="$2" '$1==o && $2==x { print $3 }')"
}
pin executed   'fresh'      fresh
pin FAILED     'fresh'      fresh
pin executed   'stale only' stale
pin FAILED     'stale only' stale
pin executed   'none'       no-results
pin UP-TO-DATE 'stale only' cached
pin FROM-CACHE 'fresh'      cached
pin UP-TO-DATE 'none'       no-results
pin NO-SOURCE  'none'       no-tests
pin SKIPPED    'stale only' no-tests
pin SKIPPED    'none'       no-tests
pin unresolved 'fresh'      unknown
pin FAILED     'none'       aborted

# DR-18: a crashed or OOM-killed test JVM prints FAILED and writes no XML. That cell must
# reach triage, while a no-results cell from any other outcome must not — so the two are
# asserted apart, and a regression that merges them fails here.
verdict_of() { printf '%s\n' "${MAP}" | awk -F'|' -v o="$1" -v x="$2" '$1==o && $2==x { print $3 }'; }
delegates() { # $1=verdict -> yes/no, per the rule read out of `### After the verdict`
	case " $(printf '%s ' ${NODELEGATE}) " in *" $1 "*) echo no ;; *) echo yes ;; esac
}
assert "delegation: aborted (FAILED, no XML) reaches triage" yes "$(delegates "$(verdict_of FAILED none)")"
assert "delegation: no-tests (NO-SOURCE, no XML) does not" no "$(delegates "$(verdict_of NO-SOURCE none)")"
assert "delegation: no-results (UP-TO-DATE, no XML) does not" no "$(delegates "$(verdict_of UP-TO-DATE none)")"
if [ "$(verdict_of FAILED none)" = "$(verdict_of UP-TO-DATE none)" ]; then
	echo "FAIL  delegation: FAILED and UP-TO-DATE with no XML share a verdict, so the"
	echo "        delegating and non-delegating cases can no longer be told apart"
	fail=1
else
	echo "PASS  delegation: FAILED + none is a distinct verdict from the other no-XML cells"
fi

echo
if [ "${fail}" -eq 0 ]; then
	echo "parser-fixture-check: ALL PASS"
else
	echo "parser-fixture-check: FAIL"
	exit 1
fi
