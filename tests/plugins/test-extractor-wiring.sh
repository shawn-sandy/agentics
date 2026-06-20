#!/usr/bin/env bash
set -euo pipefail

# Integration test for the compute-on-read plan spec extractor
# (docs/plans/replace-plan-digest-with-extractor.html). Asserts the plan-agent
# tree is wired to scripts/extract-plan-spec.mjs and that the retired
# #plan-digest cache + its awk one-liner are gone from generated output and the
# review path. Spec-extraction behavior itself is covered by the node test
# tests/plugins/test-extract-plan-spec.mjs.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKELETON="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html"
PLAN_SKILL="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/SKILL.md"
REVIEW_SKILL="$ROOT/kit/plugins/plan-agent/skills/review-plan/SKILL.md"
ROLE_PROMPTS="$ROOT/kit/plugins/plan-agent/skills/review-plan/references/role-prompts.md"
AGENTS_DIR="$ROOT/kit/plugins/plan-agent/agents"
BACKFILL_TEST="$ROOT/tests/plugins/test-backfill-digest.mjs"
AWK_ONELINER="awk '!f && /<script[^>]*id=\"plan-digest\""
FAILURES=0

pass() { echo "  PASS"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== Extractor Wiring Test ==="

echo "1. SKELETON.html embeds no #plan-digest block..."
if ! grep -q 'id="plan-digest"' "$SKELETON" && ! grep -q 'text/markdown' "$SKELETON"; then
  pass
else
  fail "skeleton still contains a #plan-digest / text/markdown block"
fi

echo "2. Skeleton buildImplementPrompt() is self-contained (reads the plan by path, no repo-local script)..."
if grep -qF "Read the plan at ' + planPath" "$SKELETON" \
  && ! grep -q 'extract-plan-spec.mjs' "$SKELETON" \
  && ! grep -qF "$AWK_ONELINER" "$SKELETON"; then
  pass
else
  fail "Copy-button JS is not self-contained (references a repo-local script or still uses awk)"
fi

echo "3. implementation-plan SKILL.md: generated prompts are self-contained, digest section gone..."
if grep -q 'Read and implement all steps in the plan at <filepath>' "$PLAN_SKILL" \
  && grep -q 'Brief subagents with the plan file at <filepath>' "$PLAN_SKILL" \
  && ! grep -q 'extract-plan-spec.mjs' "$PLAN_SKILL" \
  && ! grep -q 'Machine-Readable Digest' "$PLAN_SKILL" \
  && ! grep -q '{plan-digest}' "$PLAN_SKILL" \
  && ! grep -qF "$AWK_ONELINER" "$PLAN_SKILL"; then
  pass
else
  fail "SKILL.md generated prompts still reference a repo-local script, or the digest section/awk remains"
fi

echo "4. review-plan SKILL.md: no digest-refresh pass, reads via the extractor..."
if ! grep -q 'Refresh the digest' "$REVIEW_SKILL" \
  && ! grep -q 'Pass 1b' "$REVIEW_SKILL" \
  && grep -q 'extract-plan-spec.mjs' "$REVIEW_SKILL"; then
  pass
else
  fail "review-plan SKILL.md still has a digest-refresh pass or lacks the extractor reference"
fi

echo "5. All 7 reviewer briefs run the extractor with a full-HTML fallback..."
BRIEF_EXTRACTOR_COUNT="$(grep -c 'extract-plan-spec.mjs' "$ROLE_PROMPTS" || true)"
BRIEF_FALLBACK_COUNT="$(grep -c 'fall back to reading the full HTML' "$ROLE_PROMPTS" || true)"
if [ "$BRIEF_EXTRACTOR_COUNT" -ge 7 ] && [ "$BRIEF_FALLBACK_COUNT" -ge 7 ] \
  && ! grep -qF "$AWK_ONELINER" "$ROLE_PROMPTS"; then
  pass
else
  fail "role-prompts.md extractor refs=$BRIEF_EXTRACTOR_COUNT (need >=7), fallbacks=$BRIEF_FALLBACK_COUNT (need >=7), or awk remains"
fi

echo "6. All 7 reviewer agent defs run the extractor with a full-HTML fallback..."
AGENT_FAIL=0
AGENT_COUNT=0
for agent in "$AGENTS_DIR"/plan-reviewer-*.md; do
  AGENT_COUNT=$((AGENT_COUNT + 1))
  if ! grep -q 'extract-plan-spec.mjs' "$agent" \
    || ! grep -q 'fall back to reading the full HTML' "$agent" \
    || grep -qF "$AWK_ONELINER" "$agent"; then
    echo "  FAIL: $(basename "$agent") missing extractor/fallback or still uses awk"
    AGENT_FAIL=1
  fi
done
if [ "$AGENT_FAIL" -eq 0 ] && [ "$AGENT_COUNT" -eq 7 ]; then
  pass
else
  fail "expected 7 wired agent defs, found $AGENT_COUNT with failures=$AGENT_FAIL"
fi

echo "7. test-backfill-digest.mjs corpus assertion scoped to legacy embedded plans..."
if grep -q 'stays idempotent on legacy embedded plans' "$BACKFILL_TEST" \
  && grep -q 'Compute-on-read plans ship without a digest' "$BACKFILL_TEST"; then
  pass
else
  fail "backfill corpus assertion is not scoped so digest-free plans pass"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All extractor-wiring checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
