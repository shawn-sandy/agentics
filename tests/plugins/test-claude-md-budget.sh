#!/usr/bin/env bash
set -euo pipefail

# CLAUDE.md is loaded into every session in this repo before the user's first
# word is read, so its size is a per-session tax. This test holds it to the
# context budget.
#
# It used to also assert that every marketplace plugin appeared in a catalog
# table inside CLAUDE.md. That table was removed deliberately: the per-plugin
# catalog is generated into README.md's Plugin Reference Table, and duplicating
# it here paid the tax in every session to restate what the filesystem and that
# table already say. The two checks that policed the table went with it.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CLAUDE_MD="$ROOT/CLAUDE.md"
WORD_BUDGET=800
FAILURES=0

echo "=== CLAUDE.md Context Budget Test ==="

if [ ! -f "$CLAUDE_MD" ]; then
  echo "FATAL: $CLAUDE_MD does not exist — every check below would cascade."
  exit 1
fi

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

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks passed."
  exit 0
fi
echo "$FAILURES check(s) failed."
exit 1
