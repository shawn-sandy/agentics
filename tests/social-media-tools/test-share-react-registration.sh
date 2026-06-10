#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MARKETPLACE="$ROOT/.claude-plugin/marketplace.json"
PLUGIN="$ROOT/kit/plugins/social-media-tools"
ROUTER="$PLUGIN/skills/social-share/SKILL.md"
SKILL="$PLUGIN/skills/share-react/SKILL.md"
README="$PLUGIN/README.md"
VARIABLES="$PLUGIN/references/variables.md"
FAILURES=0

echo "=== share-react Registration Test ==="

echo "1. marketplace.json: social-media-tools version == 2.11.0..."
VERSION=$(python3 - "$MARKETPLACE" <<'PYEOF'
import json
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    data = json.load(f)
for plugin in data.get("plugins", []):
    if plugin.get("name") == "social-media-tools":
        print(plugin.get("version", ""))
        break
PYEOF
)
if [ "$VERSION" = "2.11.0" ]; then
  echo "  PASS"
else
  echo "  FAIL: expected 2.11.0, got '$VERSION'"
  FAILURES=$((FAILURES + 1))
fi

echo "2. social-share Phase 1 table has a share-react rule..."
if [ -f "$ROUTER" ] && awk '/^## Phase 1/{flag=1; next} /^## Phase 2/{flag=0} flag' "$ROUTER" \
    | grep -F '| `share-react` |' | grep -q '^|'; then
  echo "  PASS"
else
  echo "  FAIL: no share-react routing row in the Phase 1 table"
  FAILURES=$((FAILURES + 1))
fi

echo "3. share-react rule appears before the share-selection rule..."
REACT_LINE=$(grep -n -F '| `share-react` |' "$ROUTER" | head -1 | cut -d: -f1 || true)
SELECTION_LINE=$(grep -n -F '| `share-selection` |' "$ROUTER" | head -1 | cut -d: -f1 || true)
if [ -n "$REACT_LINE" ] && [ -n "$SELECTION_LINE" ] && [ "$REACT_LINE" -lt "$SELECTION_LINE" ]; then
  echo "  PASS (share-react line $REACT_LINE < share-selection line $SELECTION_LINE)"
else
  echo "  FAIL: share-react row (line ${REACT_LINE:-missing}) is not before share-selection row (line ${SELECTION_LINE:-missing})"
  FAILURES=$((FAILURES + 1))
fi

echo "4. share-react SKILL.md frontmatter has name: share-react..."
FRONTMATTER=$(awk 'NR==1 && /^---$/{flag=1; next} flag && /^---$/{exit} flag' "$SKILL")
if printf '%s\n' "$FRONTMATTER" | grep -q '^name: share-react$'; then
  echo "  PASS"
else
  echo "  FAIL: 'name: share-react' not found in frontmatter"
  FAILURES=$((FAILURES + 1))
fi

echo "5. share-react SKILL.md frontmatter has a description: line..."
if printf '%s\n' "$FRONTMATTER" | grep -q '^description:'; then
  echo "  PASS"
else
  echo "  FAIL: no description: line in frontmatter"
  FAILURES=$((FAILURES + 1))
fi

echo "6. share-react SKILL.md frontmatter has an allowed-tools: line..."
if printf '%s\n' "$FRONTMATTER" | grep -q '^allowed-tools:'; then
  echo "  PASS"
else
  echo "  FAIL: no allowed-tools: line in frontmatter"
  FAILURES=$((FAILURES + 1))
fi

echo "7. description value length <= 200 chars..."
DESC_LEN=$(python3 - "$SKILL" <<'PYEOF'
import re
import sys

with open(sys.argv[1], encoding="utf-8") as f:
    text = f.read()
match = re.search(r'^description:\s*"(.*)"\s*$', text, re.M)
print(len(match.group(1)) if match else -1)
PYEOF
)
if [ "$DESC_LEN" -ge 0 ] && [ "$DESC_LEN" -le 200 ]; then
  echo "  PASS ($DESC_LEN chars)"
else
  echo "  FAIL: description length is $DESC_LEN (must be 0-200; -1 means no quoted value found)"
  FAILURES=$((FAILURES + 1))
fi

echo "8. README.md mentions share-react..."
if grep -q 'share-react' "$README"; then
  echo "  PASS"
else
  echo "  FAIL: share-react not mentioned in README.md"
  FAILURES=$((FAILURES + 1))
fi

echo "9. README.md mentions react-card.html..."
if grep -q 'react-card\.html' "$README"; then
  echo "  PASS"
else
  echo "  FAIL: react-card.html not mentioned in README.md"
  FAILURES=$((FAILURES + 1))
fi

echo "10. references/variables.md has a react-card.html section..."
if grep -qE '^##+ react-card\.html' "$VARIABLES"; then
  echo "  PASS"
else
  echo "  FAIL: no react-card.html heading in references/variables.md"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "ALL PASSED"
  exit 0
else
  echo "FAILED ($FAILURES failures)"
  exit 1
fi
