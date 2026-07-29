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

# The plugin rows of the table under "## Reference Implementations" — the
# `| Plugin | Type |` header and the |---|---| separator are both dropped, so
# the count below means plugins and the row budget is measured only against
# rows a plugin author actually writes.
TABLE_ROWS="$(awk '
  /^## Reference Implementations/ { in_section = 1; next }
  /^## / { in_section = 0 }
  in_section && /^\|/ && !/^\|[[:space:]]*-+/ && !/^\|[[:space:]]*Plugin[[:space:]]*\|/ { print }
' "$CLAUDE_MD")"

echo "1. CLAUDE.md is under $WORD_BUDGET words..."
# Locale is pinned because GNU wc counts a standalone `—` or `→` as its own
# word under a UTF-8 locale and as nothing under C — a ~20-word swing on this
# file, which made the budget depend on the runner rather than the content
# (CI defaults to C.UTF-8, most dev shells do not). C is POSIX-guaranteed to
# exist. The file is kept under budget in both, so the pin sets which number
# is authoritative, not whether the check can be satisfied.
WORDS="$(LC_ALL=C wc -w < "$CLAUDE_MD" | tr -d ' ')"
WORDS_UTF8="$(LC_ALL=C.UTF-8 wc -w < "$CLAUDE_MD" 2>/dev/null | tr -d ' ' || true)"
if [ "$WORDS" -lt "$WORD_BUDGET" ]; then
  echo "  PASS ($WORDS words)"
else
  echo "  FAIL: $WORDS words, budget is $WORD_BUDGET"
  FAILURES=$((FAILURES + 1))
fi

# Advisory, never fatal: the UTF-8 count is the higher of the two, so a file
# that clears it clears the budget on any runner. Reported so the headroom
# stays visible instead of being discovered by a red CI job.
if [ -n "$WORDS_UTF8" ] && [ "$WORDS_UTF8" -ge "$WORD_BUDGET" ]; then
  echo "  NOTE: $WORDS_UTF8 words under a UTF-8 locale — at or over budget there"
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
  count="$(printf '%s' "$row" | tr '|' ' ' | LC_ALL=C wc -w | tr -d ' ')"
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
