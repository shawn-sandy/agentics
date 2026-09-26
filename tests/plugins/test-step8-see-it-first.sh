#!/usr/bin/env bash
set -euo pipefail

# Step 8's see-it-first question must offer running both the prototype and the
# design canvas in one pick, stay within AskUserQuestion's 4-option cap, and
# run the two skills in sequence — both write the same spec frontmatter.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/SKILL.md"
FAILURES=0

echo "=== Step 8 See-It-First Question Test ==="

[ -f "$SKILL" ] || { echo "FAIL: $SKILL not found"; exit 1; }

# The option list: from the question line to the next blank line.
OPTIONS=$(awk '/Question: "Want to see it before building\?"/{f=1} f&&/^$/{exit} f' "$SKILL")
# The combined handler: its bold lead-in to the next blank line.
HANDLER=$(awk '/\*\*If the user answered `Prototype and design canvas`:\*\*/{f=1} f&&/^$/{exit} f' "$SKILL")

echo "1. The see-it-first question offers a combined option..."
if printf '%s\n' "$OPTIONS" | grep -q '^ *- `Prototype and design canvas` —'; then
  echo "  PASS"
else
  echo "  FAIL: no 'Prototype and design canvas' option in the see-it-first list"
  FAILURES=$((FAILURES + 1))
fi

echo "2. The question keeps its single-choice options (Prototype, Design canvas, No)..."
missing=""
for opt in 'Prototype' 'Design canvas' 'No'; do
  printf '%s\n' "$OPTIONS" | grep -q "^ *- \`$opt\` —" || missing="$missing '$opt'"
done
if [ -z "$missing" ]; then
  echo "  PASS"
else
  echo "  FAIL: see-it-first list lost option(s):$missing"
  FAILURES=$((FAILURES + 1))
fi

echo "3. The question stays within AskUserQuestion's 4-option cap..."
count=$(printf '%s\n' "$OPTIONS" | grep -c '^ *- `[^`]*` —' || true)
if [ "$count" -ge 1 ] && [ "$count" -le 4 ]; then
  echo "  PASS ($count options)"
else
  echo "  FAIL: see-it-first list has $count options (cap is 4)"
  FAILURES=$((FAILURES + 1))
fi

echo "4. A handler exists for the combined answer..."
if [ -n "$HANDLER" ]; then
  echo "  PASS"
else
  echo "  FAIL: no 'If the user answered \`Prototype and design canvas\`' handler"
  FAILURES=$((FAILURES + 1))
fi

echo "5. The combined handler invokes prototype before design..."
proto_line=$(printf '%s\n' "$HANDLER" | grep -n 'skill: "plan-agent:prototype"' | head -1 | cut -d: -f1 || true)
design_line=$(printf '%s\n' "$HANDLER" | grep -n 'skill: "plan-agent:design"' | head -1 | cut -d: -f1 || true)
if [ -n "$proto_line" ] && [ -n "$design_line" ] && [ "$proto_line" -lt "$design_line" ]; then
  echo "  PASS"
else
  echo "  FAIL: handler must invoke plan-agent:prototype, then plan-agent:design (got prototype=${proto_line:-none}, design=${design_line:-none})"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks PASSED."
  exit 0
else
  echo "$FAILURES check(s) FAILED."
  exit 1
fi
