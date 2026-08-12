#!/usr/bin/env bash
set -euo pipefail

# Structural smoke test for the build-feature skill
# (docs/plans/create-build-feature-skill.html). Asserts the skill is installed,
# structurally complete, dual-deliverable, recommend-only, and registered in
# the marketplace at or above origin/main.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL_DIR="$ROOT/kit/plugins/plan-agent/skills/build-feature"
SKILL="$SKILL_DIR/SKILL.md"
REFS="$SKILL_DIR/references"
IMPL_SKILL="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/SKILL.md"
BP_SKILL="$ROOT/kit/plugins/plan-agent/skills/build-proposal/SKILL.md"
MARKETPLACE="$ROOT/.claude-plugin/marketplace.json"
PLUGIN_JSON="$ROOT/kit/plugins/plan-agent/.claude-plugin/plugin.json"
FAILURES=0

echo "=== build-feature Skill Smoke Test ==="

echo "1. SKILL.md exists with frontmatter contract (name, model, model-invocable)..."
if [ -f "$SKILL" ] \
  && grep -q "^name: build-feature$" "$SKILL" \
  && grep -q "^model: claude-fable-5$" "$SKILL" \
  && ! grep -q "disable-model-invocation" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: missing SKILL.md, name/model line, or carries disable-model-invocation"
  FAILURES=$((FAILURES + 1))
fi

echo "2. allowed-tools declares Skill, Agent, WebSearch, WebFetch, ToolSearch, ExitPlanMode..."
ATLINE="$(grep -m1 '^allowed-tools:' "$SKILL" || true)"
MISSING=""
for t in Skill Agent WebSearch WebFetch ToolSearch ExitPlanMode; do
  echo "$ATLINE" | grep -qw "$t" || MISSING="$MISSING $t"
done
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: allowed-tools missing:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "3. description is three-part: <=200 total, first sentence <=80, has a 'Use when' trigger..."
if python3 - "$SKILL" <<'PY'
import re, sys
txt = open(sys.argv[1]).read()
m = re.search(r'^description:\s*"(.*)"\s*$', txt, re.M)
if not m:
    sys.exit(1)
d = m.group(1)
s = re.search(r"(?<=[.!?])\s", d)
first = len(d[: s.start()] if s else d)
sys.exit(0 if len(d) <= 200 and first <= 80 and "use when" in d.lower() else 1)
PY
then
  echo "  PASS"
else
  echo "  FAIL: description must be <=200 total, first sentence <=80, and contain a 'Use when' trigger"
  FAILURES=$((FAILURES + 1))
fi

echo "4. description shares no trigger phrase with implementation-plan or build-proposal..."
if python3 - "$SKILL" "$IMPL_SKILL" "$BP_SKILL" <<'PY'
import re, sys
def desc(p):
    return re.search(r'^description:\s*"?(.*?)"?\s*$', open(p).read(), re.M).group(1).lower()
bf = desc(sys.argv[1])
# distinctive trigger phrases of the two siblings — none may appear here
sibling_phrases = [
    "plan document", "html plan", "write a plan file",
    "create a plan", "implementation plan", "markdown plan",
    "should-we", "floats an idea", "proposal",
]
sys.exit(1 if any(ph in bf for ph in sibling_phrases) else 0)
PY
then
  echo "  PASS"
else
  echo "  FAIL: build-feature description overlaps a sibling's trigger phrasing"
  FAILURES=$((FAILURES + 1))
fi

echo "5. SKILL.md body is under 500 lines..."
LINES="$(wc -l < "$SKILL" | tr -d ' ')"
if [ "$LINES" -lt 500 ]; then
  echo "  PASS ($LINES lines)"
else
  echo "  FAIL: body is $LINES lines (>=500)"
  FAILURES=$((FAILURES + 1))
fi

echo "6. Body carries the Tier 0/1/2 gate and all 8 workflow steps (Frame → Converge and hand off)..."
STEP_COUNT="$(grep -cE '^### Step [1-8] —' "$SKILL" || true)"
if grep -q "0 — Plan-sized" "$SKILL" \
  && grep -q "1 — Focused" "$SKILL" \
  && grep -q "2 — Full" "$SKILL" \
  && grep -q "Step 1 — Frame" "$SKILL" \
  && grep -q "Step 8 — Converge and hand off" "$SKILL" \
  && [ "$STEP_COUNT" -eq 8 ]; then
  echo "  PASS (8 numbered steps)"
else
  echo "  FAIL: missing Tier 0/1/2 gate or the 8 numbered steps (found $STEP_COUNT)"
  FAILURES=$((FAILURES + 1))
fi

echo "7. The reference resolves one level deep and is linked from SKILL.md..."
if [ -f "$REFS/feature-doc-shape.md" ] \
  && grep -q "references/feature-doc-shape.md" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: references/feature-doc-shape.md is missing or not linked from SKILL.md"
  FAILURES=$((FAILURES + 1))
fi

echo "8. Step 8 dual-delivers: prompt authors the sub-feature prompts, at convergence only..."
STEP8="$(sed -n '/^### Step 8 —/,/^## Writing Style/p' "$SKILL")"
MISSING=""
printf '%s' "$STEP8" | grep -qF 'Skill(skill: "plan-agent:prompt"' || MISSING="$MISSING prompt-delegation"
printf '%s' "$STEP8" | grep -qF -- '--out' || MISSING="$MISSING out-path-contract"
printf '%s' "$STEP8" | grep -qF -- '--answers-gathered' || MISSING="$MISSING interview-bypass"
grep -qF 'feature-<slug>-<sub-slug>.md' "$SKILL" || MISSING="$MISSING prompt-filename"
grep -q "only at convergence" "$SKILL" || MISSING="$MISSING convergence-only"
grep -q "docs/features/" "$SKILL" || MISSING="$MISSING features-doc-path"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: Step 8 dual-deliverable contract incomplete:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "9. Recommend-only: Tier 0 routes to implementation-plan, and the skill never invokes it..."
if grep -q "implementation-plan <idea>" "$SKILL" \
  && ! grep -qF 'Skill(skill: "plan-agent:implementation-plan"' "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: Tier 0 routing line missing, or the body invokes implementation-plan itself"
  FAILURES=$((FAILURES + 1))
fi

echo "10. SKILL.md resolves the features dir via --dir → featuresDirectory → docs/features/, prompts dir separately..."
MISSING=""
grep -q "\-\-dir" "$SKILL" || MISSING="$MISSING dir-flag"
grep -q "planAgent.featuresDirectory" "$SKILL" || MISSING="$MISSING featuresDirectory-setting"
grep -q "docs/features/" "$SKILL" || MISSING="$MISSING docs-features-default"
grep -q "promptsDirectory" "$SKILL" || MISSING="$MISSING promptsDirectory-setting"
grep -q "docs/prompts/" "$SKILL" || MISSING="$MISSING docs-prompts-default"
grep -q "mkdir -p" "$SKILL" || MISSING="$MISSING mkdir"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: artifact resolver incomplete in SKILL.md:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "11. marketplace.json is valid JSON and registers plan-agent at or above origin/main (dynamic)..."
if python3 - "$MARKETPLACE" "$ROOT" <<'PY'
import json, subprocess, sys
cur_doc = json.load(open(sys.argv[1]))
root = sys.argv[2]
def ver(doc):
    return [p for p in doc["plugins"] if p["name"] == "plan-agent"][0]["version"]
cur = ver(cur_doc)
def parse(v):
    return tuple(int(x) for x in v.split("."))
# Dynamic baseline — read origin/main, never hardcode a version.
# `>=`, not `>`: demanding a bump belongs to check-plugin-versions.mjs.
try:
    base_raw = subprocess.check_output(
        ["git", "-C", root, "show", "origin/main:.claude-plugin/marketplace.json"],
        stderr=subprocess.DEVNULL,
    )
    base = ver(json.loads(base_raw))
    ok = parse(cur) >= parse(base)
    print(f"  (current {cur} >= origin/main {base}: {ok})")
except Exception:
    ok = parse(cur) > (0, 0, 0)
    print(f"  (origin/main unavailable; current {cur} is a valid semver)")
desc = [p for p in cur_doc["plugins"] if p["name"] == "plan-agent"][0]["description"]
ok = ok and "build-feature" in desc
sys.exit(0 if ok else 1)
PY
then
  echo "  PASS"
else
  echo "  FAIL: invalid JSON, plan-agent regressed below origin/main, or description omits build-feature"
  FAILURES=$((FAILURES + 1))
fi

echo "12. plugin.json carries no version key and names build-feature..."
if python3 - "$PLUGIN_JSON" <<'PY'
import json, sys
p = json.load(open(sys.argv[1]))
sys.exit(0 if "version" not in p and "build-feature" in p.get("description", "") else 1)
PY
then
  echo "  PASS"
else
  echo "  FAIL: plugin.json has a version key or does not name build-feature"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== $FAILURES CHECK(S) FAILED ==="
  exit 1
fi
