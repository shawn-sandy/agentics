#!/usr/bin/env bash
set -euo pipefail

# Objective smoke test for the humanized plan skeleton
# (docs/plans/humanize-plan-output.html). Asserts BOTH sides of the change:
#
#   Human layer   — plain-language headings ("Definition of done", "Final
#                   check"), the .plan-glance at-a-glance block above the
#                   Implement row, a p.section-intro opening every
#                   .section-card, and the collapsed .plan-more-ways drawer
#                   so exactly one prompt row is visible on first paint.
#   Machine layer — every id, class, meta name, and frozen string that the
#                   plans gallery, finalize-plan, hooks, and the extractor
#                   grep out of plan files is still present, byte-for-byte.
#   Extractor     — scripts/extract-plan-spec.mjs output stays pure: no
#                   at-a-glance or section-intro copy leaks into the
#                   extracted objective/context/verification spec.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKELETON="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html"
EXTRACTOR="$ROOT/scripts/extract-plan-spec.mjs"
FAILURES=0

pass() { echo "  PASS"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== Humanized Skeleton Smoke Test ==="

# ── Human layer ────────────────────────────────────────────────────────

echo "1. Humanized heading strings present (\"Definition of done\", \"Final check\")..."
if grep -qF 'Definition of done' "$SKELETON" \
  && grep -qF 'Final check' "$SKELETON"; then
  pass
else
  fail "skeleton is missing a humanized heading string"
fi

echo "2. .plan-glance sits between div#objective and the Implement row..."
if python3 - "$SKELETON" << 'PYEOF'
import sys
html = open(sys.argv[1]).read()
body = html[html.find('<main id="main">'):]
o = body.find('id="objective"')
g = body.find('class="plan-glance"')
i = body.find('class="plan-implement"')
sys.exit(0 if -1 not in (o, g, i) and o < g < i else 1)
PYEOF
then
  pass
else
  fail ".plan-glance is missing or not ordered objective -> glance -> implement"
fi

echo "3. Every .section-card opens with a p.section-intro..."
if python3 - "$SKELETON" << 'PYEOF'
import sys, re
html = open(sys.argv[1]).read()
cards = html.split('<section class="section-card')[1:]
if not cards:
    sys.exit(1)
for card in cards:
    h2_end = card.find('</h2>')
    if h2_end == -1:
        sys.exit(1)
    after = card[h2_end:]
    m = re.search(r'<p\b[^>]*>', after)
    if not m or 'class="section-intro"' not in m.group(0):
        sys.exit(1)
sys.exit(0)
PYEOF
then
  pass
else
  fail "a .section-card does not open with a p.section-intro after its heading"
fi

echo "4. Drawer is a single flat details.plan-more-ways (no open attr, no nested <details>)..."
if python3 - "$SKELETON" << 'PYEOF'
import sys
html = open(sys.argv[1]).read()
start = html.find('<details class="plan-more-ways"')
if start == -1:
    sys.exit(1)
open_tag = html[start:html.find('>', start) + 1]
if ' open' in open_tag:
    sys.exit(1)
end = html.find('</details>', start)
body = html[html.find('>', start) + 1:end]
sys.exit(1 if '<details' in body else 0)
PYEOF
then
  pass
else
  fail "details.plan-more-ways missing, ships the open attribute, or nests a <details>"
fi

echo "5. Exactly one prompt row on first paint (implement outside drawer; goal + workflow inside)..."
if python3 - "$SKELETON" << 'PYEOF'
import sys
html = open(sys.argv[1]).read()
body = html[html.find('<main id="main">'):]
imp = body.find('class="plan-implement"')
start = body.find('<details class="plan-more-ways"')
end = body.find('</details>', start)
goal = body.find('class="plan-goal"')
wf = body.find('class="plan-workflow"')
src = body.find('class="plan-source"')
ok = (-1 not in (imp, start, end, goal, wf, src)
      and imp < start                 # implement row is the visible CTA
      and start < goal < end          # goal row inside the drawer
      and start < wf < end            # workflow row inside the drawer
      and start < src < end)          # plan-source rows inside the drawer
sys.exit(0 if ok else 1)
PYEOF
then
  pass
else
  fail "prompt rows are not implement-outside / goal+workflow+source-inside the drawer"
fi

echo "6. Uppercase removed from .section-card h2 but kept on .step-chip..."
H2_RULE="$(awk '/^  \.section-card h2 \{/{f=1} f{print} f && /^  \}/{exit}' "$SKELETON")"
CHIP_RULE="$(awk '/^  \.step-chip \{/{f=1} f{print} f && /^  \}/{exit}' "$SKELETON")"
if [ -n "$H2_RULE" ] && [ -n "$CHIP_RULE" ] \
  && ! echo "$H2_RULE" | grep -q 'text-transform: uppercase' \
  && echo "$CHIP_RULE" | grep -q 'text-transform: uppercase'; then
  pass
else
  fail ".section-card h2 still uppercases, or .step-chip lost its uppercase rule"
fi

# ── Machine contract ───────────────────────────────────────────────────

echo "7. All plan-* meta tags present and unrenamed..."
META_OK=1
for meta in plan-status plan-effort plan-type plan-created plan-repo \
            plan-file plan-path plan-implement plan-goal plan-workflow; do
  if ! grep -q "<meta name=\"$meta\"" "$SKELETON"; then
    echo "  missing: <meta name=\"$meta\">"
    META_OK=0
  fi
done
if [ "$META_OK" -eq 1 ]; then
  pass
else
  fail "one or more plan-* meta tags are missing"
fi

echo "8. Machine ids, classes, and data-status present and unrenamed..."
ID_OK=1
for marker in 'id="implement-cmd"' 'id="goal-cmd"' 'id="workflow-cmd"' \
              'id="plan-file"' 'id="plan-path"' 'id="criteria-list"' \
              'id="completion-list"' 'class="step-card"' 'data-status='; do
  if ! grep -qF "$marker" "$SKELETON"; then
    echo "  missing: $marker"
    ID_OK=0
  fi
done
if [ "$ID_OK" -eq 1 ]; then
  pass
else
  fail "one or more machine ids/classes/attributes are missing"
fi

echo "9. Frozen strings survive byte-for-byte..."
if grep -qF 'Pursue as goal' "$SKELETON" \
  && grep -qF '<span class="step-chip">todo</span>' "$SKELETON" \
  && grep -qF 'No items to report — all requirements met.' "$SKELETON"; then
  pass
else
  fail "a frozen string (Pursue as goal / step-chip todo / report-empty sentence) was reworded"
fi

# ── Extractor purity ───────────────────────────────────────────────────

echo "10. extract-plan-spec.mjs output carries no glance or section-intro copy..."
SPEC="$(node "$EXTRACTOR" "$SKELETON")"
if [ -n "$SPEC" ] \
  && echo "$SPEC" | grep -qF '{objective}' \
  && echo "$SPEC" | grep -qF '{context}' \
  && echo "$SPEC" | grep -qF '{end-to-end-verification}' \
  && ! echo "$SPEC" | grep -qF 'At a glance' \
  && ! echo "$SPEC" | grep -qF '{at-a-glance}' \
  && ! echo "$SPEC" | grep -qF 'The story behind this plan' \
  && ! echo "$SPEC" | grep -qF 'One last pass to confirm'; then
  pass
else
  fail "extractor output is missing spec fields or leaks at-a-glance/section-intro copy"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All humanized-skeleton checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
