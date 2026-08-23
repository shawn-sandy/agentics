#!/usr/bin/env bash
set -euo pipefail

# Objective-verification test for docs/plans/add-local-merge-gate.md.
#
# Objective: scripts/verify.sh skips what a project does not have, fails fast
# on what breaks, and detects everything relative to the directory it was
# invoked from.
#
# All three matter, and each fails for a different mistake:
#
#   1. SKIP lines, in printed order — a gate that hardcodes typecheck/lint/
#      unit/e2e reports four green no-ops in a repo that has none of them,
#      which is worse than no gate. Order is asserted because "fails fast"
#      is a claim about sequence; without it the assertion degrades to
#      "eventually exits non-zero".
#   2. Fail-fast — the failing fixture must stop the run, not merely colour
#      the summary red at the end.
#   3. No re-entry — every other script in this repo resolves its root from
#      $0 (tests/run-all.sh line 1). A gate doing the same would, from inside
#      tests/fixtures/verify-gate-bare/, still find agentics'
#      .claude-plugin/marketplace.json, re-enter tests/run-all.sh, re-run this
#      file, and re-invoke the gate: unbounded recursion on the objective test.
#
# The gate is always invoked from inside the fixture, not from the repo root,
# so detection is exercised against the fixture's working directory — the thing
# check 2 is about. `env -u VERIFY_GATE_ACTIVE` clears the gate's re-entry
# marker, because this file itself runs UNDER the gate when agentics' unit
# stage is tests/run-all.sh: the marker would otherwise refuse the very
# invocation the test exists to make. This is the one site allowed to clear it,
# and check 2 asserts the marker still works everywhere else.

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GATE="$ROOT/scripts/verify.sh"
BARE="$ROOT/tests/fixtures/verify-gate-bare"
FAILING="$ROOT/tests/fixtures/verify-gate-failing"
FAILURES=0

pass() { echo "  PASS${1:+ — $1}"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== verify.sh merge gate (objective test) ==="

# Canary. Every check below reads the gate's output, and an absent gate would
# make them fail with a shell error rather than with the reason.
if [ ! -f "$GATE" ]; then
  echo "FATAL: $GATE does not exist — every check below would cascade."
  exit 1
fi
for f in "$BARE" "$FAILING"; do
  if [ ! -d "$f" ]; then
    echo "FATAL: fixture $f does not exist."
    exit 1
  fi
done

# --- Check 1: bare project skips every stage and exits 0 --------------------
echo
echo "-- Check 1: a project with no toolchain skips all four stages --"
BARE_OUT=""
BARE_RC=0
BARE_OUT="$( (cd "$BARE" && env -u VERIFY_GATE_ACTIVE bash "$GATE") 2>&1 )" || BARE_RC=$?

if [ "$BARE_RC" -eq 0 ]; then
  pass "exit 0"
else
  printf '%s\n' "$BARE_OUT" | sed 's/^/    /'
  fail "the gate exited $BARE_RC in a project with nothing to check; absent tooling is a SKIP, not a failure"
fi

# The stage names on the SKIP lines, in the order they were printed. Reading
# the printed order rather than grepping for each name independently is what
# makes this an ordering assertion.
SKIP_ORDER="$(printf '%s\n' "$BARE_OUT" \
  | grep -F 'SKIP (not configured)' \
  | awk '{print $1}' \
  | tr '\n' ' ' \
  | sed 's/ *$//')"
if [ "$SKIP_ORDER" = "typecheck lint unit e2e" ]; then
  pass "typecheck lint unit e2e"
else
  echo "    expected: typecheck lint unit e2e"
  echo "    actual:   ${SKIP_ORDER:-<no SKIP (not configured) lines at all>}"
  fail "the four stages did not all report 'SKIP (not configured)' in that order"
fi

# --- Check 2: detection is relative to $PWD, so the gate cannot re-enter -----
echo
echo "-- Check 2: detection is relative to the invocation directory --"
# agentics' marketplace stages must not appear when the gate runs inside a
# fixture. If they do, detection resolved against the script's own location
# and the gate is one edit away from recursing through tests/run-all.sh.
LEAKED="$(printf '%s\n' "$BARE_OUT" | grep -inE 'marketplace|check-plugin-versions|readme|run-all' || true)"
if [ -z "$LEAKED" ]; then
  pass "no agentics stage leaked into the fixture run"
else
  printf '%s\n' "$LEAKED" | sed 's/^/    /'
  fail "the gate found agentics' own stages while running inside a fixture — detection is not relative to \$PWD"
fi

# The belt-and-braces marker, asserted directly rather than inferred. A gate
# that lost this guard still passes the check above right up until the day
# someone reintroduces \$0-relative detection.
REENTRY_OUT=""
REENTRY_RC=0
REENTRY_OUT="$( (cd "$ROOT" && VERIFY_GATE_ACTIVE=1 bash "$GATE") 2>&1 )" || REENTRY_RC=$?
if [ "$REENTRY_RC" -ne 0 ] && printf '%s\n' "$REENTRY_OUT" | grep -qi 're-entry'; then
  pass "re-entry marker refuses a nested run"
else
  printf '%s\n' "$REENTRY_OUT" | sed 's/^/    /'
  fail "VERIFY_GATE_ACTIVE=1 should make the gate exit non-zero with a named re-entry error (got exit $REENTRY_RC)"
fi

# --- Check 3: a failing stage stops the run ---------------------------------
echo
echo "-- Check 3: a broken stage fails the gate and stops it --"
FAIL_OUT=""
FAIL_RC=0
FAIL_OUT="$( (cd "$FAILING" && env -u VERIFY_GATE_ACTIVE bash "$GATE") 2>&1 )" || FAIL_RC=$?

if [ "$FAIL_RC" -ne 0 ]; then
  pass "exit $FAIL_RC"
else
  printf '%s\n' "$FAIL_OUT" | sed 's/^/    /'
  fail "the gate exited 0 in a project whose unit stage exits 1 — it is not a gate"
fi

if printf '%s\n' "$FAIL_OUT" | grep -qE '^(FAIL|verify: FAIL).*unit|^unit[[:space:]]+FAIL'; then
  pass "names the failed stage"
else
  printf '%s\n' "$FAIL_OUT" | sed 's/^/    /'
  fail "the failure output never names 'unit' as the stage that failed"
fi

# Fail-fast: e2e comes after unit, so it must not have been reached. Matched in
# stage-column position so a mention of e2e in a summary line cannot satisfy or
# break it by accident.
if printf '%s\n' "$FAIL_OUT" | grep -qE '^e2e[[:space:]]'; then
  printf '%s\n' "$FAIL_OUT" | sed 's/^/    /'
  fail "the e2e stage ran after unit failed — the gate does not stop at the first failure"
else
  pass "no stage ran after the failure"
fi

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "=== FAILED ($FAILURES check(s)) ==="
  exit 1
fi
echo "=== PASSED ==="
