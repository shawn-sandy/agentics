#!/usr/bin/env bash
set -euo pipefail

# Objective test for docs/plans/remove-skill-process-imperatives.md.
#
# The plan removes process-reminder imperatives from five SKILL.md files. This
# is the single command a reviewer runs to decide whether that prune was safe,
# so it must fail for a dropped guard, a changed description, and a missing
# baseline alike:
#
#   1. every keep-phrases.txt entry is literally present in its named file
#   2. every target's `description:` line matches descriptions.expected
#   3. all five recorded .expected manifests exist and are non-empty
#   4. the behavioral harness runs and passes whenever the `claude` CLI exists
#
# Assertion 2 exists because a prune can silently rewrite a frontmatter
# description — breaking skill activation without breaking any other test.
#
# The five skills under test are named by the two fixture files rather than by a
# list here, so the scope of the gate lives with the data it is asserting.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURES="$ROOT/tests/fixtures/imperative-baselines"
KEEP="$FIXTURES/keep-phrases.txt"
HARNESS="$ROOT/tests/plugins/test-skill-behavior-baselines.sh"
GOLDEN="$FIXTURES/descriptions.expected"
FAILURES=0

echo "=== Imperative Pruning Objective Test ==="

if [ ! -f "$KEEP" ]; then
  echo "FATAL: $KEEP does not exist — the KEEP contract is the thing under test."
  exit 1
fi

# --- 1. Every KEEP-classified guard is still literally present ---------------
# The discriminator the plan prunes by is "keep it only if violating it fails
# silently and expensively". These phrases are that KEEP set, copied verbatim
# from the source. grep -F, not a regex: the phrases contain backticks,
# asterisks, and backslashes that a regex would reinterpret.
echo "1. Every KEEP-classified guard phrase survives in its skill..."
MISSING_GUARDS=0
ENTRIES=0
while IFS=$'\t' read -r f p; do
  [ -z "${f:-}" ] && continue
  case "$f" in \#*) continue ;; esac
  ENTRIES=$((ENTRIES + 1))
  if [ ! -f "$ROOT/$f" ]; then
    echo "  MISSING FILE: $f"
    MISSING_GUARDS=$((MISSING_GUARDS + 1))
    continue
  fi
  if ! grep -qF "$p" "$ROOT/$f"; then
    echo "  DROPPED GUARD: [$p]"
    echo "                 expected in $f"
    MISSING_GUARDS=$((MISSING_GUARDS + 1))
  fi
done <"$KEEP"

PATHS_LISTED="$(cut -f1 "$KEEP" | grep -v '^#' | grep -v '^$' | sort -u | wc -l | tr -d ' ')"
if [ "$MISSING_GUARDS" -eq 0 ] && [ "$PATHS_LISTED" -eq 5 ]; then
  echo "  PASS ($ENTRIES guards across $PATHS_LISTED skills)"
else
  [ "$PATHS_LISTED" -ne 5 ] && echo "  FAIL: keep-phrases.txt must cover exactly 5 skills, covers $PATHS_LISTED"
  [ "$MISSING_GUARDS" -ne 0 ] && echo "  FAIL: $MISSING_GUARDS KEEP-classified guard(s) no longer present"
  FAILURES=$((FAILURES + 1))
fi

# --- 2. No accidental description drift -------------------------------------
# A skill's `description:` is its activation trigger. Rewording it during a body
# prune breaks discovery while every body-level test stays green.
#
# Compared against a committed golden file rather than against origin/<base>.
# The base-branch comparison was correct for the pruning PR itself but wrong as
# a permanent gate: it would block every future legitimate description update to
# these five skills with no way to pass. The golden file is the deliberate-update
# path — changing a description means updating the matching line here in the same
# commit, which surfaces in review as an explicit act instead of an incidental
# diff buried in a body rewrite.
echo "2. Every target description: line matches the recorded golden copy..."
if [ ! -s "$GOLDEN" ]; then
  echo "  FAIL: missing golden description file at $GOLDEN"
  FAILURES=$((FAILURES + 1))
else
  DRIFTED=0
  CHECKED=0
  while IFS=$'\t' read -r f line; do
    case "${f:-}" in ''|\#*) continue ;; esac
    CHECKED=$((CHECKED + 1))
    NOW="$(grep -m1 '^description:' "$ROOT/$f" 2>/dev/null || true)"
    if [ "$NOW" != "$line" ]; then
      echo "  DRIFT: $f"
      echo "    recorded:     $line"
      echo "    working tree: $NOW"
      DRIFTED=$((DRIFTED + 1))
    fi
  done <"$GOLDEN"

  # Guard the guard: a golden file that lost entries would pass vacuously.
  if [ "$CHECKED" -ne 5 ]; then
    echo "  FAIL: golden file covers $CHECKED skills, expected 5"
    FAILURES=$((FAILURES + 1))
  elif [ "$DRIFTED" -eq 0 ]; then
    echo "  PASS ($CHECKED descriptions)"
  else
    echo "  FAIL: $DRIFTED description line(s) differ from the recorded copy."
    echo "        If the change is intentional, update $(basename "$GOLDEN") in the same commit."
    FAILURES=$((FAILURES + 1))
  fi
fi

# --- 3. The recorded baselines exist ----------------------------------------
# A prune whose baseline was never recorded is an unverified prune. The manifest
# files are the evidence; their absence is a failure, not a skip.
echo "3. All five recorded baseline manifests exist and are non-empty..."
MANIFESTS_OK=0
for name in build implementation-plan ship-autonomous branch-agent optimizing-skill-frontmatter; do
  m="$FIXTURES/${name}.expected"
  if [ -s "$m" ]; then
    echo "  $name: $(wc -l <"$m" | tr -d ' ') recorded facts"
    MANIFESTS_OK=$((MANIFESTS_OK + 1))
  else
    echo "  $name: MISSING or EMPTY ($m)"
  fi
done
echo "baselines: ${MANIFESTS_OK}/5 match"
if [ "$MANIFESTS_OK" -eq 5 ]; then
  echo "  PASS"
else
  echo "  FAIL: $((5 - MANIFESTS_OK)) baseline manifest(s) missing or empty"
  FAILURES=$((FAILURES + 1))
fi

# --- 4. Run the behavioral harness when the CLI is available ----------------
# CI has no `claude` CLI, so this assertion is a no-op there by design — the
# harness itself refuses to skip when it *is* invoked, which is what keeps the
# local gate honest. SKIP_BEHAVIOR_BASELINES exists for the tautology check in
# the plan's Verification section, which breaks a guard on purpose and only
# needs assertion 1 to fire.
echo "4. Behavioral baselines..."
if [ -n "${SKIP_BEHAVIOR_BASELINES:-}" ]; then
  echo "  SKIPPED by SKIP_BEHAVIOR_BASELINES (structural assertions only)"
elif command -v claude >/dev/null 2>&1; then
  if bash "$HARNESS"; then
    echo "  PASS"
  else
    echo "  FAIL: a pruned skill diverged from its recorded behavioral baseline"
    FAILURES=$((FAILURES + 1))
  fi
else
  echo "  claude CLI not present — structural assertions only (this is the CI path)"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All imperative-pruning checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
