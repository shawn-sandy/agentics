#!/usr/bin/env bash
set -euo pipefail

# Structural smoke test for the setup-sites skill. Asserts the skill and its
# four scaffold templates are installed, structurally complete, and that
# plan-agent is registered in the marketplace above origin/main.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL_DIR="$ROOT/kit/plugins/plan-agent/skills/setup-sites"
SKILL="$SKILL_DIR/SKILL.md"
TPL="$ROOT/kit/plugins/plan-agent/templates/pages"
MARKETPLACE="$ROOT/.claude-plugin/marketplace.json"
PLUGIN_JSON="$ROOT/kit/plugins/plan-agent/.claude-plugin/plugin.json"
FAILURES=0

echo "=== setup-sites Skill Smoke Test ==="

echo "1. SKILL.md exists with frontmatter contract (name: setup-sites)..."
if [ -f "$SKILL" ] && grep -q "^name: setup-sites$" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: missing SKILL.md or name line"
  FAILURES=$((FAILURES + 1))
fi

echo "2. allowed-tools declares Bash, Read, Write, AskUserQuestion, ToolSearch, ExitPlanMode..."
ATLINE="$(grep -m1 '^allowed-tools:' "$SKILL" || true)"
MISSING=""
for t in Bash Read Write AskUserQuestion ToolSearch ExitPlanMode; do
  echo "$ATLINE" | grep -qw "$t" || MISSING="$MISSING $t"
done
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: allowed-tools missing:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "3. description is <=200 chars, three-part (>=2 '. ' sentences), and has 'Use when'..."
if python3 - "$SKILL" <<'PY'
import re, sys
txt = open(sys.argv[1]).read()
m = re.search(r'^description:\s*"(.*)"\s*$', txt, re.M)
if not m:
    sys.exit(1)
d = m.group(1)
sys.exit(0 if len(d) <= 200 and d.count(". ") >= 2 and "Use when" in d else 1)
PY
then
  echo "  PASS"
else
  echo "  FAIL: description >200 chars, not three-part, or missing 'Use when'"
  FAILURES=$((FAILURES + 1))
fi

echo "4. SKILL.md body is under 500 lines..."
LINES="$(wc -l < "$SKILL" | tr -d ' ')"
if [ "$LINES" -lt 500 ]; then
  echo "  PASS ($LINES lines)"
else
  echo "  FAIL: body is $LINES lines (>=500)"
  FAILURES=$((FAILURES + 1))
fi

echo "5. Body carries the Exit-plan-mode bootstrap and all 7 numbered steps..."
STEP_COUNT="$(grep -cE '^## Step [1-7] —' "$SKILL" || true)"
if grep -q "^## Exit plan mode$" "$SKILL" \
  && grep -qF 'call `ExitPlanMode` first — this workflow mutates state.' "$SKILL" \
  && [ "$STEP_COUNT" -eq 7 ]; then
  echo "  PASS (7 numbered steps)"
else
  echo "  FAIL: missing Exit-plan-mode bootstrap or the 7 numbered steps (found $STEP_COUNT)"
  FAILURES=$((FAILURES + 1))
fi

echo "6. All four scaffold templates resolve under templates/pages/..."
if [ -f "$TPL/deploy-pages.yml" ] && [ -f "$TPL/hub.html" ] && [ -f "$TPL/serve-docs.sh" ]; then
  echo "  PASS"
else
  echo "  FAIL: a template (deploy-pages.yml / hub.html / serve-docs.sh) is missing"
  FAILURES=$((FAILURES + 1))
fi

echo "7. deploy-pages.yml template is SHA-pinned, asserts .nojekyll, uploads docs/, triggers on main..."
WF="$TPL/deploy-pages.yml"
if [ -f "$WF" ] \
  && ! grep -Eq 'uses:[^#]*@v[0-9]' "$WF" \
  && grep -q "docs/.nojekyll is missing" "$WF" \
  && grep -q "upload-pages-artifact" "$WF" \
  && grep -qE '^\s*path:\s*docs\s*$' "$WF" \
  && grep -q "branches: \[main\]" "$WF"; then
  echo "  PASS"
else
  echo "  FAIL: workflow not SHA-pinned, or missing .nojekyll assert / docs upload / main trigger"
  FAILURES=$((FAILURES + 1))
fi

echo "8. hub.html template has both prunable card markers, three placeholders, and no absolute-root links..."
HUB="$TPL/hub.html"
if [ -f "$HUB" ] \
  && grep -q "<!-- CARD:plans -->" "$HUB" && grep -q "<!-- /CARD:plans -->" "$HUB" \
  && grep -q "<!-- CARD:social -->" "$HUB" && grep -q "<!-- /CARD:social -->" "$HUB" \
  && grep -q "{{SITE_TITLE}}" "$HUB" && grep -q "{{SITE_TAGLINE}}" "$HUB" && grep -q "{{SITE_FOOTER}}" "$HUB" \
  && ! grep -q 'href="/' "$HUB"; then
  echo "  PASS"
else
  echo "  FAIL: hub template missing card markers/placeholders, or has an absolute-root link"
  FAILURES=$((FAILURES + 1))
fi

echo "9. serve-docs.sh template is a bash script bound to localhost..."
SD="$TPL/serve-docs.sh"
if [ -f "$SD" ] \
  && head -1 "$SD" | grep -q "bash" \
  && grep -q -- "--bind 127.0.0.1" "$SD"; then
  echo "  PASS"
else
  echo "  FAIL: serve-docs.sh missing shebang or 127.0.0.1 bind"
  FAILURES=$((FAILURES + 1))
fi

echo "10. marketplace.json is valid JSON and registers plan-agent at or above origin/main (dynamic)..."
if python3 - "$MARKETPLACE" "$ROOT" <<'PY'
import json, subprocess, sys
cur_doc = json.load(open(sys.argv[1]))
root = sys.argv[2]
def ver(doc):
    return [p for p in doc["plugins"] if p["name"] == "plan-agent"][0]["version"]
def parse(v):
    return tuple(int(x) for x in v.split("."))
cur = ver(cur_doc)
# `>=`, not `>`: demanding a bump belongs to check-plugin-versions.mjs, which asks
# only when the plugin actually changed. This suite runs on every branch, so `>`
# failed on any branch cut after a plan-agent release, where cur == base.
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
ok = ok and "setup-sites" in desc
sys.exit(0 if ok else 1)
PY
then
  echo "  PASS"
else
  echo "  FAIL: invalid JSON, plan-agent regressed below origin/main, or description omits setup-sites"
  FAILURES=$((FAILURES + 1))
fi

echo "11. plugin.json carries no version key and names setup-sites..."
if python3 - "$PLUGIN_JSON" <<'PY'
import json, sys
p = json.load(open(sys.argv[1]))
sys.exit(0 if "version" not in p and "setup-sites" in p.get("description", "") else 1)
PY
then
  echo "  PASS"
else
  echo "  FAIL: plugin.json has a version key or does not name setup-sites"
  FAILURES=$((FAILURES + 1))
fi

echo "12. Step 2 seeds docs/plans/ when plansDirectory is unset (so the first plan deploys)..."
if grep -q 'os.makedirs(os.path.join("docs", "plans")' "$SKILL" \
  && grep -q '"docs", "plans", ".gitkeep"' "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: Step 2 does not seed docs/plans/ for the unset-plansDirectory case"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All setup-sites checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
