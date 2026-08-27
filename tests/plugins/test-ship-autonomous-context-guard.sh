#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
S="$ROOT/kit/plugins/git-agent/skills/ship-autonomous"
SKILL="$S/SKILL.md"
REF="$S/references/context-guard.md"
README="$ROOT/kit/plugins/git-agent/README.md"
FAILURES=0

pass() { echo "  PASS${1:+ ($1)}"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== ship-autonomous Context Guard Smoke Test ==="

echo "1. SKILL.md and its reference exist..."
[ -f "$SKILL" ] || { echo "  FAIL: $SKILL not found"; exit 1; }
[ -f "$REF" ] && pass || fail "$REF not found — Step 0 points at it"

echo "2. Step 0 is the context guard..."
grep -q "^## Step 0: Context Guard" "$SKILL" && pass || fail "'## Step 0: Context Guard' heading missing"

echo "3. Guard runs before plan-mode exit and before the first mutation..."
# `|| true` matters: `pipefail` is on, so a heading grep that matches nothing
# would abort the whole run here and hide every later check plus the summary.
S0=$(grep -n "^## Step 0: Context Guard"  "$SKILL" | cut -d: -f1 || true)
S05=$(grep -n "^## Step 0.5: Exit Plan Mode" "$SKILL" | cut -d: -f1 || true)
S1=$(grep -n "^## Step 1: Pre-flight Guards" "$SKILL" | cut -d: -f1 || true)
if [ -n "$S0" ] && [ -n "$S05" ] && [ -n "$S1" ] && [ "$S0" -lt "$S05" ] && [ "$S05" -lt "$S1" ]; then
  pass
else
  fail "expected Step 0 < Step 0.5 < Step 1, got $S0 / $S05 / $S1"
fi

# Only sliceable once both bounds are known; otherwise leave it empty so the
# checks below report their own failures instead of erroring on bad arithmetic.
if [ -n "$S0" ] && [ -n "$S05" ]; then
  GUARD="$(sed -n "${S0},$((S05 - 1))p" "$SKILL")"
else
  GUARD=""
fi
# Prose in these files is hard-wrapped, so any assertion spanning more than a
# few words must run against the unwrapped text or it fails on a line break.
GUARD1="$(tr '\n' ' ' <<<"$GUARD")"

# The claim the whole guard rests on. If a future step starts reading the
# transcript and this sentence is edited away, clearing stops being safe.
echo "4. States that no step reads the conversation..."
grep -q "No step below reads the conversation" <<<"$GUARD" && pass || fail "guard must state that no step reads the conversation"

echo "5. Step 0 delegates detail to the reference file..."
grep -q "references/context-guard.md" <<<"$GUARD" && pass || fail "Step 0 must point at references/context-guard.md"

echo "6. Skip condition is stated (no prompt on every run)..."
grep -qi "Skip this step on a short session" <<<"$GUARD1" && pass || fail "guard must state its skip condition"

echo "7. The hard-STOP invariant is in Guardrails with the other hard stops..."
sed -n '/^## Guardrails/,/^## Step 0:/p' "$SKILL" | grep -q "hard STOP" && pass || fail "Guardrails must carry the Step 0 clear=STOP invariant"

echo "8. allowed-tools includes AskUserQuestion (the guard prompts)..."
grep -m1 "^allowed-tools:" "$SKILL" | grep -q "AskUserQuestion" && pass || fail "'AskUserQuestion' missing from allowed-tools"

echo "9. Reference explains the per-event re-send cost..."
grep -q "per event, not per run" "$REF" && pass || fail "reference must explain the cost is per event"

echo "10. All three routes are documented..."
for opt in '`clear`' '`background`' '`continue`'; do
  grep -qF "$opt" "$REF" && pass "$opt" || fail "route $opt missing from $REF"
done

# Without this the model would try to /clear itself, silently no-op, and run the
# pipeline in the same bloated session the user asked to escape.
echo "11. 'clear' is a hard STOP, with the reason..."
if grep -q "hard STOP" "$REF" && grep -q "cannot clear your own context" "$REF"; then
  pass
else
  fail "reference must make 'clear' a hard STOP and say why it cannot self-clear"
fi

echo "12. Background route names both background commands..."
if grep -q "/git-agent:ship-bg" "$REF" && grep -q "/git-agent:ship-ci-bg" "$REF"; then
  pass
else
  fail "background route must dispatch ship-bg then ship-ci-bg"
fi

echo "13. Merge approval is not delegated to a subagent..."
grep -q "no user to ask" "$REF" && pass || fail "reference must state the background route returns for merge approval"

echo "14. README documents the guard as Step 0..."
if grep -q "Context guard (Step 0)" "$README" && grep -q "Exit plan mode (Step 0.5)" "$README"; then
  pass
else
  fail "README ship-autonomous walkthrough is out of sync with the skill"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks PASSED."
else
  echo "$FAILURES check(s) FAILED."
  exit 1
fi
