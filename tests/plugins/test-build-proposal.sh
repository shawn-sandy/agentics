#!/usr/bin/env bash
set -euo pipefail

# Structural smoke test for the build-proposal skill
# (docs/plans/add-build-proposal-skill.html). Asserts the skill is installed,
# structurally complete, and registered in the marketplace above origin/main.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL_DIR="$ROOT/kit/plugins/plan-agent/skills/build-proposal"
SKILL="$SKILL_DIR/SKILL.md"
REFS="$SKILL_DIR/references"
IMPL_SKILL="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/SKILL.md"
MARKETPLACE="$ROOT/.claude-plugin/marketplace.json"
PLUGIN_JSON="$ROOT/kit/plugins/plan-agent/.claude-plugin/plugin.json"
GITKEEP="$ROOT/docs/proposals/.gitkeep"
FAILURES=0

echo "=== build-proposal Skill Smoke Test ==="

echo "1. SKILL.md exists with frontmatter contract (name, model, model-invocable)..."
if [ -f "$SKILL" ] \
  && grep -q "^name: build-proposal$" "$SKILL" \
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

echo "3. description is <=200 chars and three-part (>=2 ' — ' separators)..."
if python3 - "$SKILL" <<'PY'
import re, sys
txt = open(sys.argv[1]).read()
m = re.search(r'^description:\s*"(.*)"\s*$', txt, re.M)
if not m:
    sys.exit(1)
d = m.group(1)
sys.exit(0 if len(d) <= 200 and d.count(" — ") >= 2 else 1)
PY
then
  echo "  PASS"
else
  echo "  FAIL: description >200 chars or not three-part (need >=2 ' — ' separators)"
  FAILURES=$((FAILURES + 1))
fi

echo "4. description shares no trigger phrase with implementation-plan (collision guard)..."
if python3 - "$SKILL" "$IMPL_SKILL" <<'PY'
import re, sys
def desc(p):
    return re.search(r'^description:\s*"?(.*?)"?\s*$', open(p).read(), re.M).group(1).lower()
bp = desc(sys.argv[1])
# implementation-plan's distinctive trigger phrases — none may appear in build-proposal
ip_phrases = [
    "plan document", "html plan", "write a plan file",
    "create a plan", "implementation plan", "markdown plan",
]
sys.exit(1 if any(ph in bp for ph in ip_phrases) else 0)
PY
then
  echo "  PASS"
else
  echo "  FAIL: build-proposal description overlaps implementation-plan trigger phrasing"
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

echo "6. Body carries the Tier 0/1/2 gate and all 8 workflow steps (Frame → Converge & hand off)..."
STEP_COUNT="$(grep -cE '^### Step [1-8] —' "$SKILL" || true)"
if grep -q "0 — Answer" "$SKILL" \
  && grep -q "1 — Lightweight" "$SKILL" \
  && grep -q "2 — Full" "$SKILL" \
  && grep -q "Step 1 — Frame" "$SKILL" \
  && grep -q "Step 8 — Converge and hand off" "$SKILL" \
  && [ "$STEP_COUNT" -eq 8 ]; then
  echo "  PASS (8 numbered steps)"
else
  echo "  FAIL: missing Tier 0/1/2 gate or the 8 numbered steps (found $STEP_COUNT)"
  FAILURES=$((FAILURES + 1))
fi

echo "7. Both references resolve one level deep and are linked from SKILL.md..."
if [ -f "$REFS/artifact-shape.md" ] \
  && [ -f "$REFS/operating-principles.md" ] \
  && grep -q "references/artifact-shape.md" "$SKILL" \
  && grep -q "references/operating-principles.md" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: a reference file is missing or not linked from SKILL.md"
  FAILURES=$((FAILURES + 1))
fi

echo "8. deep-research wired as optional (not a hard dependency) with a fallback..."
if grep -qi "not a hard dependency" "$REFS/operating-principles.md" \
  && grep -qi "fall back to" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: deep-research optional-with-fallback wiring missing"
  FAILURES=$((FAILURES + 1))
fi

echo "9. Both worked exemplars resolve flat with front-matter + source stamp..."
EX1="$REFS/example-design-md-spec-alignment.md"
EX2="$REFS/example-proposal-builder-skill.md"
EX_OK=1
for f in "$EX1" "$EX2"; do
  [ -f "$f" ] || { EX_OK=0; continue; }
  head -1 "$f" | grep -q "^---$" || EX_OK=0          # front-matter at line 1
  grep -q "^status:" "$f" || EX_OK=0
  grep -qi "Trimmed worked exemplar" "$f" || EX_OK=0  # stamp present
  grep -q "@ \`[0-9a-f]\{40\}\`" "$f" || EX_OK=0      # 40-char commit SHA in stamp
done
if [ "$EX_OK" -eq 1 ]; then
  echo "  PASS"
else
  echo "  FAIL: an example-*.md is missing, lacks front-matter, or lacks a SHA-stamped source header"
  FAILURES=$((FAILURES + 1))
fi

echo "10. docs/proposals/.gitkeep seeds the default artifact root..."
if [ -f "$GITKEEP" ]; then
  echo "  PASS"
else
  echo "  FAIL: docs/proposals/.gitkeep is missing"
  FAILURES=$((FAILURES + 1))
fi

echo "11. SKILL.md resolves the artifact dir via --dir → planAgent.proposalsDirectory → docs/proposals/..."
if grep -q "\-\-dir" "$SKILL" \
  && grep -q "planAgent.proposalsDirectory" "$SKILL" \
  && grep -q "docs/proposals/" "$SKILL" \
  && grep -q "mkdir -p" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: artifact-dir resolver order or mkdir -p missing from SKILL.md"
  FAILURES=$((FAILURES + 1))
fi

echo "12. marketplace.json is valid JSON and registers plan-agent above origin/main (dynamic)..."
if python3 - "$MARKETPLACE" "$ROOT" <<'PY'
import json, subprocess, sys
cur_doc = json.load(open(sys.argv[1]))
root = sys.argv[2]
def ver(doc):
    return [p for p in doc["plugins"] if p["name"] == "plan-agent"][0]["version"]
cur = ver(cur_doc)
def parse(v):
    return tuple(int(x) for x in v.split("."))
# Dynamic baseline — read origin/main, never hardcode 2.4.1.
try:
    base_raw = subprocess.check_output(
        ["git", "-C", root, "show", "origin/main:.claude-plugin/marketplace.json"],
        stderr=subprocess.DEVNULL,
    )
    base = ver(json.loads(base_raw))
    ok = parse(cur) > parse(base)
    print(f"  (current {cur} > origin/main {base}: {ok})")
except Exception:
    # Remote ref unavailable (shallow clone / detached CI) — still assert a sane semver.
    ok = parse(cur) > (0, 0, 0)
    print(f"  (origin/main unavailable; current {cur} is a valid semver)")
desc = [p for p in cur_doc["plugins"] if p["name"] == "plan-agent"][0]["description"]
ok = ok and "build-proposal" in desc
sys.exit(0 if ok else 1)
PY
then
  echo "  PASS"
else
  echo "  FAIL: invalid JSON, plan-agent not above origin/main, or description omits build-proposal"
  FAILURES=$((FAILURES + 1))
fi

echo "13. plugin.json carries no version key and names build-proposal..."
if python3 - "$PLUGIN_JSON" <<'PY'
import json, sys
p = json.load(open(sys.argv[1]))
sys.exit(0 if "version" not in p and "build-proposal" in p.get("description", "") else 1)
PY
then
  echo "  PASS"
else
  echo "  FAIL: plugin.json has a version key or does not name build-proposal"
  FAILURES=$((FAILURES + 1))
fi

echo "14. Fixture: a canonical-shape proposal matches the documented section list..."
FIXTURE="$(mktemp -t build-proposal-fixture.XXXXXX.md)"
trap 'rm -f "$FIXTURE"' EXIT
cat > "$FIXTURE" <<'MDEOF'
---
status: proposal
type: feature
created: 2026-06-18
repo-name: agentics
---

# Proposal: sample idea

## Context
Why this is on the table.

## Core finding
> The one central insight.

## Locked & resolved decisions
1. **Decided.** consequence

## Open questions (decisions only)
- a genuine decision

## Next step
Convert to an execution plan.
MDEOF
SECT_OK=1
for h in "## Context" "## Core finding" "## Locked & resolved decisions" "## Open questions" "## Next step"; do
  grep -qF "$h" "$FIXTURE" || SECT_OK=0
done
# The canonical section list must also be documented in the artifact-shape reference.
grep -qi "Core finding" "$REFS/artifact-shape.md" || SECT_OK=0
grep -qi "Locked & resolved decisions" "$REFS/artifact-shape.md" || SECT_OK=0
if [ "$SECT_OK" -eq 1 ]; then
  echo "  PASS"
else
  echo "  FAIL: canonical sections not matchable or not documented in artifact-shape.md"
  FAILURES=$((FAILURES + 1))
fi

echo "15. Step 8 handoff leads with an objective, not a bare .md (no conversion-mode hollow plan)..."
# A bare `.md` first token would put implementation-plan into conversion mode,
# which maps Changes/Steps -> step cards; proposals have only Workstreams/Roadmap,
# so the handoff must lead with an objective to keep the full step-drafting pass.
if grep -qE 'implementation-plan +[^ ]+\.md' "$SKILL"; then
  echo "  FAIL: SKILL.md advertises a bare '.md' handoff token (triggers conversion mode)"
  FAILURES=$((FAILURES + 1))
elif grep -q "author an execution plan from the proposal at" "$SKILL" \
  && grep -qi "conversion" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: Step 8 handoff missing the objective-led command or the conversion-mode caveat"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All build-proposal checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
