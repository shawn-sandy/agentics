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

echo "6. Body carries the Tier 0/1/2 gate and each of Steps 1-8 exactly once..."
# Each heading must appear exactly once. A bare count of 8 would accept a
# duplicated Step 3 masking a missing Step 5 — the regression this guards.
if python3 - "$SKILL" <<'PY'
import re, sys
txt = open(sys.argv[1]).read()
bad = []
for n in range(1, 9):
    c = len(re.findall(rf'^### Step {n} — ', txt, re.M))
    if c != 1:
        bad.append(f"Step {n} appears {c}x")
for tier in ("0 — Plan-sized", "1 — Focused", "2 — Full"):
    if tier not in txt:
        bad.append(f"missing tier row {tier!r}")
for anchor in ("Step 1 — Frame", "Step 8 — Converge and hand off"):
    if anchor not in txt:
        bad.append(f"missing {anchor!r}")
if bad:
    print("   " + "; ".join(bad))
sys.exit(1 if bad else 0)
PY
then
  echo "  PASS (Steps 1-8 each exactly once)"
else
  echo "  FAIL: Tier gate or step-heading contract broken (details above)"
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
# Each contract is asserted in the section that owns it — a whole-file grep
# would pass on a marker that drifted out of Step 8 into unrelated prose.
RESOLUTION="$(sed -n '/^## Artifact resolution/,/^## Workflow/p' "$SKILL")"
printf '%s' "$STEP8" | grep -qF 'Skill(skill: "plan-agent:prompt"' || MISSING="$MISSING prompt-delegation"
printf '%s' "$STEP8" | grep -qF -- '--out' || MISSING="$MISSING out-path-contract"
printf '%s' "$STEP8" | grep -qF -- '--answers-gathered' || MISSING="$MISSING interview-bypass"
# `--answers-gathered` suppresses prompt's type-confirmation gate, so an unpinned
# type is inferred with nobody to catch a miss. The leading `task` token pins it.
printf '%s' "$STEP8" | grep -qF '"plan-agent:prompt", args: "task ' || MISSING="$MISSING task-type-token"
# The paste-ready command passes the prompt, never the feature doc — feature-wide
# constraints are unrecoverable downstream unless they travel inside the prompt.
printf '%s' "$STEP8" | grep -qF 'UX & accessibility notes' || MISSING="$MISSING shared-constraints"
printf '%s' "$STEP8" | grep -qF 'feature-<slug>-<sub-slug>.md' || MISSING="$MISSING prompt-filename"
# Skill() has no return value, so a silent partial handoff must block convergence.
printf '%s' "$STEP8" | grep -qF 'Verify every prompt file before declaring convergence' || MISSING="$MISSING prompt-verification-gate"
# These two are the resolution table's contract, not Step 8's.
printf '%s' "$RESOLUTION" | grep -q "only at convergence" || MISSING="$MISSING convergence-only"
printf '%s' "$RESOLUTION" | grep -q "docs/features/" || MISSING="$MISSING features-doc-path"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: Step 8 dual-deliverable contract incomplete:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "9. Recommend-only: Tier 0 passes its doc via --from-prompt, and the skill never invokes the planner..."
# Tier 0 writes no prompt, so the doc is the only carrier for its stories, scope
# cuts, and risks. implementation-plan takes the first POSITIONAL .md as a
# conversion source and 1:1-maps it, and the doc has no Steps section — so the
# path must ride behind --from-prompt. Parse the emitted command rather than the
# surrounding prose: a warning sentence saying "never positional" passes happily
# next to a command that is exactly that, which is the regression this guards.
if python3 - "$SKILL" <<'PY'
import re, sys
txt = open(sys.argv[1]).read()
bad = []
rows = [l for l in txt.splitlines() if '0 — Plan-sized' in l]
if not rows:
    print("   tier-0 row missing")
    sys.exit(1)
if not any('/plan-agent:implementation-plan' in c
           for r in rows for c in re.findall(r'`([^`]+)`', r)):
    bad.append("no /plan-agent:implementation-plan handoff in the tier-0 row")
# Scan EVERY handoff in the file, not just the tier row: the guidance is restated
# elsewhere, and a later edit that reintroduces a positional .md anywhere must fail.
cmds = [c for c in re.findall(r'`([^`]+)`', txt) if '/plan-agent:implementation-plan' in c]
for cmd in cmds:
    toks = cmd.split()
    md = [i for i, t in enumerate(toks) if t.endswith('.md')]
    if not md:
        bad.append(f"handoff names no doc at all: {cmd!r}")
    for i in md:
        # Positional means: not a recognized flag's value. Only --from-prompt qualifies.
        if i == 0 or toks[i - 1] != '--from-prompt':
            bad.append(f"positional .md would trip conversion mode: {toks[i]!r} in {cmd!r}")
# Recommend-only: it routes to the planner, it never runs it.
if 'Skill(skill: "plan-agent:implementation-plan"' in txt:
    bad.append("the skill invokes implementation-plan itself")
if bad:
    print("   " + "; ".join(bad))
sys.exit(1 if bad else 0)
PY
then
  echo "  PASS"
else
  echo "  FAIL: Tier 0 handoff contract broken (details above)"
  FAILURES=$((FAILURES + 1))
fi

echo "10. SKILL.md resolves the features dir via --dir → featuresDirectory → docs/features/, prompts dir separately..."
# Presence alone is not the contract — precedence ORDER is what the resolver
# promises, so assert the three fall-through tiers appear in that order.
if python3 - "$SKILL" <<'PY'
import sys
txt = open(sys.argv[1]).read()
block = txt[txt.index("## Artifact resolution"):txt.index("## Workflow")]
bad = []
order = ["--dir", "planAgent.featuresDirectory", "${PWD}/docs/features/"]
idx = [block.find(t) for t in order]
if any(i < 0 for i in idx):
    bad.append("features resolver missing: " + ", ".join(t for t, i in zip(order, idx) if i < 0))
elif idx != sorted(idx):
    bad.append("features precedence out of order (--dir -> featuresDirectory -> docs/features/)")
# The prompts resolver is independent and must NOT be driven by --dir.
if "promptsDirectory" not in block or "${PWD}/docs/prompts/" not in block:
    bad.append("prompts resolver missing promptsDirectory or docs/prompts/ default")
if "Never overridden by `--dir`" not in block:
    bad.append("prompts resolver does not state it is independent of --dir")
if "mkdir -p" not in block:
    bad.append("no mkdir -p before first write")
if bad:
    print("   " + "; ".join(bad))
sys.exit(1 if bad else 0)
PY
then
  echo "  PASS"
else
  echo "  FAIL: artifact resolver contract broken (details above)"
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

echo "13. Step 9 publishes consent-gated in render -> publish -> verify -> record order..."
# Token presence is not the contract; ORDER is. Presence-only assertions pass on
# a Step 9 that publishes the .md before rendering, or records artifact-url:
# before WebFetch confirms the page exists — both of which ship a dead link.
# Prose here wraps at 80 columns, so sentence matches run against a flattened copy.
if python3 - "$SKILL" <<'PY'
import re, sys
txt = open(sys.argv[1]).read()
m = re.search(r'^### Step 9 —.*?(?=^## Writing Style)', txt, re.M | re.S)
if not m:
    print("   step-9 section missing")
    sys.exit(1)
step9 = m.group(0)
flat = " ".join(step9.split())
bad = []

# Anchor on the four numbered moves, then assert each carries its own mechanism.
# Do NOT scan the whole section for a token: artifact-url: legitimately appears in
# the Publish move too (the republish path passes it as Artifact's url), so a
# first-occurrence search would read the wrong position and mis-order the check.
MOVES = [
    ('1. **Render.**',  'plan-agent:markdown-to-html', 'render via markdown-to-html'),
    ('2. **Publish.**', 'Artifact(file_path:',         'the Artifact call'),
    ('3. **Verify.**',  'WebFetch',                    'WebFetch verification'),
    ('4. **Record.**',  'artifact-url:',               'recording artifact-url:'),
]
idx = []
for marker, _, _ in MOVES:
    i = step9.find(marker)
    if i < 0:
        bad.append(f"missing move {marker!r}")
    idx.append(i)

if all(i >= 0 for i in idx):
    order = [m[0] for m in MOVES]
    if idx != sorted(idx):
        bad.append("Step 9 moves are out of order; required: " + " -> ".join(order))
    # Each move must actually contain its mechanism, not merely be named.
    bounds = idx + [len(step9)]
    for n, (marker, needle, label) in enumerate(MOVES):
        block = step9[bounds[n]:bounds[n + 1]]
        if needle not in block:
            bad.append(f"{marker} does not carry {label}")
        # Publishing the .md directly is the documented bug — Artifact gets the .html.
        if needle == 'Artifact(file_path:':
            for path in re.findall(r'Artifact\(file_path:\s*"([^"]+)"', block):
                if not path.endswith('.html'):
                    bad.append(f"Artifact receives {path!r}, not the rendered .html")
            # Artifact is deferred; calling it without ToolSearch fails at runtime.
            if 'select:Artifact' not in block:
                bad.append("Publish move omits ToolSearch select:Artifact")

# Publishing is the one irreversible act here; a blanket "stop asking" must not reach it.
if 'Never publish without an explicit yes' not in flat:
    bad.append("missing consent-gate")
# Artifact is absent in some sessions; the file deliverable must survive that.
if 'A failed publish does not cost the handoff' not in flat:
    bad.append("missing publish-fallback")

if bad:
    print("   " + "; ".join(bad))
sys.exit(1 if bad else 0)
PY
then
  echo "  PASS"
else
  echo "  FAIL: Step 9 publish contract incomplete (details above)"
  FAILURES=$((FAILURES + 1))
fi

echo "14. The shape reference carries the product-feature sections, not just the split..."
SHAPE="$REFS/feature-doc-shape.md"
if python3 - "$SHAPE" <<'PYEOF'
import sys
txt = open(sys.argv[1]).read()
bad = []
# The sections that make this a product feature doc rather than a plan splitter.
for h in ("## User stories & acceptance criteria", "## Release & rollout"):
    if h not in txt:
        bad.append(f"missing {h!r}")
# Traceability runs both ways: a story names its deliverer, an entry names what it satisfies.
for token in ("Delivered by:", "**Satisfies**"):
    if token not in txt:
        bad.append(f"missing traceability token {token!r}")
# An entry without rationale, size, and dependency order is a list of names, not a
# split: rationale is what distinguishes a real seam from an arbitrary slice, and
# without size and order nobody can sequence the plans the breakdown exists to hand off.
for field in ("**Rationale**", "**Size**", "**Depends on**"):
    if field not in txt:
        bad.append(f"breakdown entry format drops {field!r}")
# The skeleton is the part authors copy, so it has to carry size and order inline.
if "(S|M|L) — depends on:" not in txt:
    bad.append("entry skeleton lacks the inline '(S|M|L) — depends on:' shape")
# An L entry is a smell worth flagging rather than a size worth accepting quietly.
if "**S** — one surface" not in txt or "**L** — crosses domains" not in txt:
    bad.append("sizing guide does not define the S/M/L bands")
# A metric without a baseline is a wish; `unmeasured` is the honest escape hatch.
if "Baseline" not in txt or "unmeasured" not in txt:
    bad.append("metrics table lacks Baseline or the `unmeasured` escape hatch")
# Rollback is the row that earns the rollout section.
if "Rollback" not in txt:
    bad.append("rollout table lacks Rollback")
# Three handoffs, and the rule that keeps the extra two off non-UI entries.
for cmd in ("/plan-agent:implementation-plan", "/plan-agent:prototype", "/impeccable:impeccable"):
    if cmd not in txt:
        bad.append(f"missing handoff {cmd!r}")
if "only for entries with UI surface" not in txt:
    bad.append("no rule limiting prototype/design handoffs to UI-bearing entries")
# Tier 0 now writes the product content and drops only the split.
if "Tier 0 still writes a doc" not in txt:
    bad.append("Tier 0 does not state that it writes a doc")
if bad:
    print("   " + "; ".join(bad))
sys.exit(1 if bad else 0)
PYEOF
then
  echo "  PASS"
else
  echo "  FAIL: product-feature shape contract broken (details above)"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "=== ALL CHECKS PASSED ==="
else
  echo "=== $FAILURES CHECK(S) FAILED ==="
  exit 1
fi
