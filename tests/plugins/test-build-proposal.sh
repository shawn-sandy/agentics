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

echo "3. description is three-part: <=200 total, first sentence <=80, has a 'Use when' trigger..."
# Three-part per .claude/rules/plugin-patterns.md and optimizing-skill-frontmatter:
# "[Short description (<=80 chars).] [Capability statement.] Use when ...".
# The parts are sentences, not em-dash clauses — an em-dash-separated run-on has
# no short first sentence and gets truncated to nothing useful at ~100 skills.
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

echo "10. Step 6 dual-writes: prompt authors the authoritative prompt, legacy copy is bannered..."
# The 6.0.0 contract: the saved prompt is the deliverable and prompt writes
# it (never hand-authored here), while the legacy docs/proposals/ copy survives
# one deprecation release carrying a banner that names the prompt as canonical.
STEP6="$(sed -n '/^### Step 6 —/,/^### Step 7 —/p' "$SKILL")"
MISSING=""
[ -f "$GITKEEP" ] || MISSING="$MISSING proposals-gitkeep"
printf '%s' "$STEP6" | grep -qF 'Skill(skill: "plan-agent:prompt"' || MISSING="$MISSING prompt-delegation"
printf '%s' "$STEP6" | grep -qF -- '--out' || MISSING="$MISSING out-path-contract"
printf '%s' "$STEP6" | grep -qF -- '--answers-gathered' || MISSING="$MISSING interview-bypass"
printf '%s' "$STEP6" | grep -qF 'proposal-<slug>.md' || MISSING="$MISSING date-free-prompt-name"
printf '%s' "$STEP6" | grep -qi 'deprecated' || MISSING="$MISSING legacy-deprecation-banner"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: Step 6 dual-write contract incomplete:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "11. SKILL.md resolves the prompts dir via --dir → promptsDirectory → docs/prompts/, legacy dir separately..."
# --dir follows the authoritative artifact, so since 6.0.0 it names the prompts
# directory; the deprecated proposals root still resolves, but never from --dir.
MISSING=""
grep -q "\-\-dir" "$SKILL" || MISSING="$MISSING dir-flag"
grep -q "promptsDirectory" "$SKILL" || MISSING="$MISSING promptsDirectory-setting"
grep -q "docs/prompts/" "$SKILL" || MISSING="$MISSING docs-prompts-default"
grep -q "planAgent.proposalsDirectory" "$SKILL" || MISSING="$MISSING legacy-proposals-setting"
grep -q "docs/proposals/" "$SKILL" || MISSING="$MISSING legacy-proposals-default"
grep -q "mkdir -p" "$SKILL" || MISSING="$MISSING mkdir"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: artifact resolver incomplete in SKILL.md:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "12. marketplace.json is valid JSON and registers plan-agent at or above origin/main (dynamic)..."
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
  echo "  FAIL: invalid JSON, plan-agent regressed below origin/main, or description omits build-proposal"
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
# Every canonical section must map onto exactly one prompt slot, or the refactor
# silently drops content on the way into the authoritative artifact.
grep -qi "Section-to-slot mapping" "$REFS/artifact-shape.md" || SECT_OK=0
for slot in "{{CONTEXT}}" "{{CORE_FINDING}}" "{{APPENDICES}}" "{{CORE_INSTRUCTION}}"; do
  grep -qF "$slot" "$REFS/artifact-shape.md" || SECT_OK=0
done
if [ "$SECT_OK" -eq 1 ]; then
  echo "  PASS"
else
  echo "  FAIL: canonical sections not matchable, or the section-to-slot mapping is missing from artifact-shape.md"
  FAILURES=$((FAILURES + 1))
fi

echo "15. No file under the skill advertises a bare .md handoff; Step 8 hands off the prompt path..."
# A positional `.md` token would put implementation-plan into conversion mode,
# which maps Changes/Steps -> step cards; proposals have only Workstreams/Roadmap,
# so the handoff must keep the full step-drafting pass.
# Scoped to the whole skill dir, not just SKILL.md: references/artifact-shape.md
# taught the trap for months because the old check only scanned SKILL.md.
#
# Until 8.5.0 the defence was "lead with objective text". That was never real:
# implementation-plan takes the first `.md`-suffixed POSITIONAL token ANYWHERE in
# the string, so prose in front of the path changed nothing. Since 8.5.0 the path
# rides behind `--from-prompt`, and a flag value is not a positional token. The
# regex below therefore excludes a `-`-led token — that is the flag form, and it
# is the only shape allowed to be followed by a path.
if grep -rqE 'implementation-plan +[^-][^ ]*\.md' "$SKILL_DIR"; then
  echo "  FAIL: a build-proposal file advertises a bare '.md' handoff token (triggers conversion mode)"
  grep -rnE 'implementation-plan +[^-][^ ]*\.md' "$SKILL_DIR" | sed 's/^/    /'
  FAILURES=$((FAILURES + 1))
elif grep -q "author an execution plan from the proposal prompt at" "$SKILL"; then
  echo "  FAIL: Step 8 still uses the pre-8.5.0 prose handoff, which lands in conversion mode"
  FAILURES=$((FAILURES + 1))
elif grep -qF -- "--from-prompt <prompts-dir>/proposal-<slug>.md" "$SKILL" \
  && grep -q "prompts-dir>/proposal-<slug>.md" "$SKILL" \
  && grep -qi "conversion" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: Step 8 handoff missing the objective-led command, the prompt path, or the conversion-mode caveat"
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
