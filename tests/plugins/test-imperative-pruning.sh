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
#   2. every target's `description:` line is byte-identical to origin/<base>
#   3. all five recorded .expected manifests exist and are non-empty
#   4. the behavioral harness runs and passes whenever the `claude` CLI exists
#
# Assertion 2 exists because a prune can silently rewrite a frontmatter
# description — breaking skill activation without breaking any other test.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURES="$ROOT/tests/fixtures/imperative-baselines"
KEEP="$FIXTURES/keep-phrases.txt"
HARNESS="$ROOT/tests/plugins/test-skill-behavior-baselines.sh"
BASE_REF="${BASE_REF:-main}"
FAILURES=0

TARGETS="
kit/plugins/plan-agent/skills/build/SKILL.md
kit/plugins/plan-agent/skills/implementation-plan/SKILL.md
kit/plugins/git-agent/skills/ship-autonomous/SKILL.md
kit/plugins/git-agent/skills/branch-agent/SKILL.md
kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md
"

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

# --- 2. No description drift ------------------------------------------------
# A skill's `description:` is its activation trigger. Rewording it during a body
# prune breaks discovery while every body-level test stays green, so it is
# compared byte-for-byte against the base branch.
echo "2. Every target description: line is byte-identical to origin/$BASE_REF..."
if ! git -C "$ROOT" rev-parse --verify --quiet "origin/$BASE_REF" >/dev/null; then
  git -C "$ROOT" fetch --quiet origin "$BASE_REF" 2>/dev/null || true
fi
if ! git -C "$ROOT" rev-parse --verify --quiet "origin/$BASE_REF" >/dev/null; then
  echo "  FAIL: cannot resolve origin/$BASE_REF — the drift assertion cannot be evaluated."
  echo "        Set BASE_REF or run: git fetch origin $BASE_REF"
  FAILURES=$((FAILURES + 1))
else
  DRIFTED=0
  for t in $TARGETS; do
    NOW="$(grep -m1 '^description:' "$ROOT/$t" || true)"
    WAS="$(git -C "$ROOT" show "origin/$BASE_REF:$t" 2>/dev/null | grep -m1 '^description:' || true)"
    if [ -z "$WAS" ]; then
      # New file on this branch: nothing to drift from, but say so out loud.
      echo "  NOTE: $t has no description: on origin/$BASE_REF (new file)"
      continue
    fi
    if [ "$NOW" != "$WAS" ]; then
      echo "  DRIFT: $t"
      echo "    origin/$BASE_REF: $WAS"
      echo "    working tree:  $NOW"
      DRIFTED=$((DRIFTED + 1))
    fi
  done
  if [ "$DRIFTED" -eq 0 ]; then
    echo "  PASS"
  else
    echo "  FAIL: $DRIFTED description line(s) changed during the prune"
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
