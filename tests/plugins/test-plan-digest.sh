#!/usr/bin/env bash
set -euo pipefail

# Objective smoke + review-path integration test for the machine-readable
# plan digest (docs/plans/embed-markdown-digest-in-html-plans.html).

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKELETON="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html"
PLAN_SKILL="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/SKILL.md"
REVIEW_SKILL="$ROOT/kit/plugins/plan-agent/skills/review-plan/SKILL.md"
ROLE_PROMPTS="$ROOT/kit/plugins/plan-agent/skills/review-plan/references/role-prompts.md"
AGENTS_DIR="$ROOT/kit/plugins/plan-agent/agents"
FAILURES=0

# The canonical extractor under test (must match the contract in SKILL.md).
extract_digest() {
  awk '!f && /<script[^>]*id="plan-digest"/{f=1;next} f && /<\/script>/{exit} f' "$1"
}

echo "=== Plan Digest Smoke Test ==="

echo "1. SKELETON.html has the digest as the first element child of <body>..."
if python3 - "$SKELETON" << 'PYEOF'
import re, sys
html = open(sys.argv[1]).read()
# Anchor on </head> — a CSS comment earlier in the file mentions <body>.
body = re.split(r'</head>\s*<body[^>]*>', html, maxsplit=1)[1]
nocomment = re.sub(r'<!--.*?-->', '', body, flags=re.S)
m = re.search(r'<[a-zA-Z][^>]*>', nocomment)
sys.exit(0 if m and m.group(0) == '<script type="text/markdown" id="plan-digest">' else 1)
PYEOF
then
  echo "  PASS"
else
  echo "  FAIL: digest script is not the first element child of <body> in SKELETON.html"
  FAILURES=$((FAILURES + 1))
fi

echo "2. Canonical awk extraction returns the skeleton's digest placeholder..."
if [ "$(extract_digest "$SKELETON")" = "{plan-digest}" ]; then
  echo "  PASS"
else
  echo "  FAIL: extraction did not return exactly '{plan-digest}'"
  FAILURES=$((FAILURES + 1))
fi

echo "3. Extraction on a fixture survives self-quoting and guarded close..."
FIXTURE="$(mktemp -t plan-digest-fixture.XXXXXX.html)"
trap 'rm -f "$FIXTURE"' EXIT
cat > "$FIXTURE" << 'HTMLEOF'
<!DOCTYPE html>
<html><head><title>Plan: Fixture</title></head>
<body>
<script type="text/markdown" id="plan-digest">
# Plan: Fixture

## Objective
Embed a `<script type="text/markdown" id="plan-digest">` block in every plan.

## Steps
1. Guard the closing sequence as <\/script> in content. Why: safety. Verify: extraction stops at the real close.
</script>
<main>POST-CLOSE CONTENT MUST NOT APPEAR</main>
</body></html>
HTMLEOF
EXTRACTED="$(extract_digest "$FIXTURE")"
if echo "$EXTRACTED" | grep -q 'Embed a `<script type="text/markdown" id="plan-digest">` block' \
  && echo "$EXTRACTED" | grep -q 'Guard the closing sequence' \
  && ! echo "$EXTRACTED" | grep -q 'POST-CLOSE CONTENT'; then
  echo "  PASS"
else
  echo "  FAIL: self-quoting line swallowed, guard broke the block, or extraction overran the close"
  echo "  --- extracted ---"
  echo "$EXTRACTED"
  FAILURES=$((FAILURES + 1))
fi

echo "4. implementation-plan SKILL.md defines the digest contract..."
if grep -q "Machine-Readable Digest" "$PLAN_SKILL" \
  && grep -q '<\\/script' "$PLAN_SKILL" \
  && grep -qF "awk '!f && /<script[^>]*id=\"plan-digest\"/{f=1;next} f && /<\\/script>/{exit} f'" "$PLAN_SKILL" \
  && grep -q "Excluded — never in the digest" "$PLAN_SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: contract section, guard, canonical extractor, or exclusion list missing"
  FAILURES=$((FAILURES + 1))
fi

echo "5. Implement & workflow prompt formats carry the extraction one-liner..."
if grep -q 'Start from the embedded digest: <digest-extract>' "$PLAN_SKILL" \
  && grep -q 'Brief subagents with the embedded digest: <digest-extract>' "$PLAN_SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: implement or workflow prompt format lacks the digest-extract clause"
  FAILURES=$((FAILURES + 1))
fi

echo "6. Skeleton buildImplementPrompt() reads the digest first..."
if grep -q 'Read the spec from the embedded digest' "$SKELETON" \
  && grep -q 'digestCmd' "$SKELETON"; then
  echo "  PASS"
else
  echo "  FAIL: buildImplementPrompt() lacks the digest-first instruction"
  FAILURES=$((FAILURES + 1))
fi

echo "7. All 7 reviewer briefs read the digest with a full-HTML fallback..."
BRIEF_DIGEST_COUNT="$(grep -c 'plan-digest' "$ROLE_PROMPTS" || true)"
BRIEF_FALLBACK_COUNT="$(grep -c 'fall back to reading the full HTML' "$ROLE_PROMPTS" || true)"
if [ "$BRIEF_DIGEST_COUNT" -ge 8 ] && [ "$BRIEF_FALLBACK_COUNT" -ge 7 ]; then
  echo "  PASS (digest refs: $BRIEF_DIGEST_COUNT, fallbacks: $BRIEF_FALLBACK_COUNT)"
else
  echo "  FAIL: role-prompts.md digest refs=$BRIEF_DIGEST_COUNT (need >=8), fallbacks=$BRIEF_FALLBACK_COUNT (need >=7)"
  FAILURES=$((FAILURES + 1))
fi

echo "8. All 7 reviewer agent defs read the digest with a full-HTML fallback..."
AGENT_FAIL=0
for agent in "$AGENTS_DIR"/plan-reviewer-*.md; do
  if ! grep -q 'plan-digest' "$agent" || ! grep -q 'fall back to reading the full HTML' "$agent"; then
    echo "  FAIL: $(basename "$agent") missing digest read or fallback"
    AGENT_FAIL=1
  fi
done
if [ "$AGENT_FAIL" -eq 0 ]; then
  echo "  PASS"
else
  FAILURES=$((FAILURES + 1))
fi

echo "9. review-plan SKILL.md states the lead-vs-reviewer read split..."
if grep -q "Lead-vs-reviewer read split" "$REVIEW_SKILL" \
  && grep -q "full HTML" "$REVIEW_SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: Step 4 lead-vs-reviewer split missing"
  FAILURES=$((FAILURES + 1))
fi

echo "10. review-plan Step 7 refreshes the digest in update-in-place mode only..."
if grep -q "Pass 1b — Refresh the digest" "$REVIEW_SKILL" \
  && grep -A2 "Pass 1b — Refresh the digest" "$REVIEW_SKILL" | grep -q "update-in-place mode" \
  && grep -A2 "Pass 1b — Refresh the digest" "$REVIEW_SKILL" | grep -q "review-only"; then
  echo "  PASS"
else
  echo "  FAIL: Step 7 digest-refresh pass missing or not scoped to update-in-place mode"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All plan-digest checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
