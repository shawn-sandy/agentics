#!/usr/bin/env bash
set -euo pipefail

# CLAUDE.md is loaded into every session in this repo before the user's first
# word is read, so its size is a per-session tax. This test holds it to the
# context budget while proving the plugin catalog is still complete: under 800
# words total, every marketplace plugin named, and no plugin table row long
# enough to be growing back into the paragraph-length notes it replaced.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLAUDE_MD="$ROOT/CLAUDE.md"
MARKETPLACE="$ROOT/.claude-plugin/marketplace.json"
WORD_BUDGET=800
ROW_BUDGET=25
FAILURES=0

echo "=== CLAUDE.md Context Budget Test ==="

if [ ! -f "$CLAUDE_MD" ]; then
  echo "FATAL: $CLAUDE_MD does not exist — every check below would cascade."
  exit 1
fi
if [ ! -f "$MARKETPLACE" ]; then
  echo "FATAL: $MARKETPLACE does not exist — every check below would cascade."
  exit 1
fi

# The plugin table under "## Reference Implementations", minus the header and
# the |---|---| separator. Everything else in the file is prose.
TABLE_ROWS="$(awk '
  /^## Reference Implementations/ { in_section = 1; next }
  /^## / { in_section = 0 }
  in_section && /^\|/ && !/^\|[[:space:]]*-+/ { print }
' "$CLAUDE_MD")"

echo "1. CLAUDE.md is under $WORD_BUDGET words..."
WORDS="$(wc -w < "$CLAUDE_MD" | tr -d ' ')"
if [ "$WORDS" -lt "$WORD_BUDGET" ]; then
  echo "  PASS ($WORDS words)"
else
  echo "  FAIL: $WORDS words, budget is $WORD_BUDGET"
  FAILURES=$((FAILURES + 1))
fi

echo "2. Every plugin in marketplace.json appears in the table..."
PLUGINS="$(node -e '
  const m = require(process.argv[1]);
  console.log(m.plugins.map(p => p.name).join("\n"));
' "$MARKETPLACE")"
if [ -z "$PLUGINS" ]; then
  echo "  FAIL: marketplace.json listed no plugins — the check would pass vacuously"
  FAILURES=$((FAILURES + 1))
fi
MISSING=0
while IFS= read -r plugin; do
  [ -z "$plugin" ] && continue
  if ! printf '%s\n' "$TABLE_ROWS" | grep -qF -- "\`$plugin\`"; then
    echo "  FAIL: $plugin is in the marketplace but not in CLAUDE.md's table"
    MISSING=$((MISSING + 1))
  fi
done <<< "$PLUGINS"
if [ "$MISSING" -eq 0 ]; then
  echo "  PASS ($(printf '%s\n' "$PLUGINS" | grep -c . ) plugins listed)"
else
  FAILURES=$((FAILURES + 1))
fi

echo "3. No plugin table row exceeds $ROW_BUDGET words..."
LONG_ROWS=0
while IFS= read -r row; do
  [ -z "$row" ] && continue
  count="$(printf '%s' "$row" | tr '|' ' ' | wc -w | tr -d ' ')"
  if [ "$count" -gt "$ROW_BUDGET" ]; then
    echo "  FAIL: $count words — ${row:0:70}..."
    LONG_ROWS=$((LONG_ROWS + 1))
  fi
done <<< "$TABLE_ROWS"
if [ "$LONG_ROWS" -eq 0 ]; then
  echo "  PASS ($(printf '%s\n' "$TABLE_ROWS" | grep -c . ) rows, all within budget)"
else
  FAILURES=$((FAILURES + 1))
fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks passed."
  exit 0
fi
echo "$FAILURES check(s) failed."
exit 1
