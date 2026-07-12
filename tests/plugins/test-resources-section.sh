#!/usr/bin/env bash
set -euo pipefail

# Objective smoke test for the opt-in Resources section in plan-agent HTML
# plans.
#
# The Resources section lets a plan embed the images, screenshots, and
# reference links used to create it, so readers can illustrate the work and
# verify the implementation against the same material. These asserts pin the
# section markup, its CSS, the #ic-photo icon, the sidebar nav link, and the
# SKILL.md contract to the skeleton so the fill pipeline cannot silently drop
# it or diverge from the documented shape.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKELETON="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html"
PLAN_SKILL="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/SKILL.md"
FAILURES=0

echo "=== Resources Section Smoke Test ==="

echo "1. SKELETON.html defines the #ic-photo icon symbol..."
if grep -q '<symbol id="ic-photo"' "$SKELETON"; then
  echo "  PASS"
else
  echo "  FAIL: #ic-photo symbol not found in SKELETON.html"
  FAILURES=$((FAILURES + 1))
fi

echo "2. SKELETON.html has the #resources section with the card-resources class..."
if grep -q 'section class="section-card card-resources" id="resources"' "$SKELETON"; then
  echo "  PASS"
else
  echo "  FAIL: #resources section element not found"
  FAILURES=$((FAILURES + 1))
fi

echo "3. Resources section sits between Context and Files..."
if python3 - "$SKELETON" << 'PYEOF'
import re, sys
html = open(sys.argv[1]).read()
ctx = html.find('id="context"')
res = html.find('id="resources"')
files = html.find('id="files"')
sys.exit(0 if -1 < ctx < res < files else 1)
PYEOF
then
  echo "  PASS"
else
  echo "  FAIL: section order is not Context -> Resources -> Files"
  FAILURES=$((FAILURES + 1))
fi

echo "4. Section ships both fill placeholders ({resource-figures} in .resource-grid, {resource-links} in .resource-links)..."
if python3 - "$SKELETON" << 'PYEOF'
import re, sys
html = open(sys.argv[1]).read()
sec = re.search(r'<section class="section-card card-resources".*?</section>', html, re.S)
if not sec:
    sys.exit(1)
s = sec.group(0)
ok = ('resource-grid' in s and '{resource-figures}' in s
      and 'resource-links' in s and '{resource-links}' in s)
sys.exit(0 if ok else 1)
PYEOF
then
  echo "  PASS"
else
  echo "  FAIL: resource-grid/{resource-figures} or resource-links/{resource-links} missing from the section"
  FAILURES=$((FAILURES + 1))
fi

echo "5. Sidebar nav has a #resources link using the photo icon..."
if grep -q 'href="#resources"' "$SKELETON" \
   && grep -A0 'href="#resources"' "$SKELETON" | grep -q 'ic-photo'; then
  echo "  PASS"
else
  echo "  FAIL: sidebar nav link to #resources with #ic-photo not found"
  FAILURES=$((FAILURES + 1))
fi

echo "6. Resources CSS classes are defined (.resource-grid, .resource-figure, .resource-links)..."
if grep -q '^  \.resource-grid {' "$SKELETON" \
   && grep -q '^  \.resource-figure {' "$SKELETON" \
   && grep -q '^  \.resource-links {' "$SKELETON"; then
  echo "  PASS"
else
  echo "  FAIL: one or more .resource-* CSS blocks not found in SKELETON.html"
  FAILURES=$((FAILURES + 1))
fi

echo "7. Filling the placeholders yields a valid, parseable section with an accessible image and a captioned link..."
if python3 - "$SKELETON" << 'PYEOF'
import re, sys
from html.parser import HTMLParser
html = open(sys.argv[1]).read()

figure = (
  '<figure class="resource-figure">'
  '<a href="https://example.com/full.png" target="_blank" rel="noopener noreferrer">'
  '<img src="https://example.com/shot.png" alt="Current settings page before the toggle" loading="lazy">'
  '</a>'
  '<figcaption>Before state &mdash; <a href="https://example.com/src">source</a></figcaption>'
  '</figure>'
)
link = (
  '<li><a href="https://example.com/doc" target="_blank" rel="noopener noreferrer">MDN doc</a> '
  '<span class="resource-note">confirms the API surface</span></li>'
)
filled = html.replace('{resource-figures}', figure).replace('{resource-links}', link)

# The filled document must still parse without raising.
class P(HTMLParser):
    def error(self, m):
        raise ValueError(m)
P().feed(filled)

sec = re.search(r'<section class="section-card card-resources".*?</section>', filled, re.S)
if not sec:
    sys.exit(1)
s = sec.group(0)

# The rendered section must carry the accessible image (non-empty alt), the
# figcaption, and the reference link with its note.
img = re.search(r'<img[^>]*\balt="([^"]+)"', s)
ok = (
    img is not None and img.group(1).strip() != ""
    and '<figcaption>' in s
    and 'resource-note' in s
    and 'MDN doc' in s
)
sys.exit(0 if ok else 1)
PYEOF
then
  echo "  PASS"
else
  echo "  FAIL: filled section did not parse or is missing the image alt / figcaption / link note"
  FAILURES=$((FAILURES + 1))
fi

echo "8. implementation-plan guidelines document Resources capture (markdown-spec pipeline)..."
# Since the markdown-spec pipeline (plan-agent 2.19.0) SKILL.md no longer
# fills skeleton placeholders; the Resources habit lives in the guidelines
# (capture during Explore/Clarify, kept as a markdown-only section) and the
# skeleton's resource markup is exercised by the checks above.
CATALOG="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md"
if grep -qi 'Resources Capture' "$CATALOG" \
   && grep -qi 'Resources' "$PLAN_SKILL" \
   && grep -q 'Resources' "$ROOT/kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.md"; then
  echo "  PASS"
else
  echo "  FAIL: guidelines/section-catalog.md, SKILL.md, or SKELETON.md dropped the Resources guidance"
  FAILURES=$((FAILURES + 1))
fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "All Resources section assertions passed."
else
  echo "$FAILURES assertion(s) failed."
  exit 1
fi
