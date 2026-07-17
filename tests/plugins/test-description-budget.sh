#!/usr/bin/env bash
# Unit test for the skill-description budget rule: <=200 chars total, first
# sentence <=80 chars. Covers measure-description.sh (which enforces the 200
# total) plus measure_description_budget.py (which also measures the first
# sentence), then sweeps every shipped SKILL.md so a regression fails here.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MEASURE="$ROOT/kit/plugins/skill-reviewer/scripts/measure-description.sh"
BUDGET="$(dirname "$0")/measure_description_budget.py"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
pass=0
fail=0

check() {
  if [ "$2" = "1" ]; then echo "PASS: $1"; pass=$((pass + 1))
  else echo "FAIL: $1"; fail=$((fail + 1)); fi
}

# Write a SKILL.md fixture; $1 = name, $2 = description text. Echoes the path.
fixture() {
  mkdir -p "$TMP/$1"
  printf -- '---\nname: %s\ndescription: "%s"\n---\n\nBody.\n' "$1" "$2" > "$TMP/$1/SKILL.md"
  echo "$TMP/$1/SKILL.md"
}

# A description of exactly $1 chars, ending in a period.
desc_of() { python3 -c "print('D' * ($1 - 1) + '.')"; }

warns() { case "$1" in WARNING*) return 0 ;; *) return 1 ;; esac; }
oks() { case "$1" in OK*) return 0 ;; *) return 1 ;; esac; }

# --- measure-description.sh: the 200-char total ---

# The real sync-rules regression was 258 chars.
out=$(sh "$MEASURE" "$(fixture over "$(desc_of 258)")")
warns "$out" && check "258-char description warns" 1 || check "258-char description warns (got: $out)" 0

# 200 is the budget, not over it.
out=$(sh "$MEASURE" "$(fixture boundary "$(desc_of 200)")")
oks "$out" && check "200-char description passes (boundary inclusive)" 1 || check "200-char passes (got: $out)" 0

# 201 warns — proves the boundary sits where it claims.
out=$(sh "$MEASURE" "$(fixture justover "$(desc_of 201)")")
warns "$out" && check "201-char description warns" 1 || check "201-char warns (got: $out)" 0

# The enforced threshold is 200; 160 is advisory only.
out=$(sh "$MEASURE" "$(fixture legacy "$(desc_of 180)")")
oks "$out" && check "180-char description passes (160 is advisory, not enforced)" 1 || check "180-char passes (got: $out)" 0

# --- measure_description_budget.py: the 80-char first sentence ---

# 80 F's + '.' = an 81-char first sentence, one over.
long_first="$(python3 -c "print('F' * 80 + '.')") Trigger."
read -r total first <<< "$(python3 "$BUDGET" "$(fixture firstsentence "$long_first")")"
[ "$first" -eq 81 ] && check "81-char first sentence measured as 81 (over the 80 limit)" 1 \
  || check "81-char first sentence measured (got $first)" 0

# 79 F's + '.' = exactly 80, the inclusive boundary.
ok_first="$(python3 -c "print('F' * 79 + '.')") Trigger."
read -r total first <<< "$(python3 "$BUDGET" "$(fixture firstok "$ok_first")")"
[ "$first" -eq 80 ] && check "80-char first sentence measured as 80 (boundary inclusive)" 1 \
  || check "80-char first sentence measured (got $first)" 0

# The trailing space after a sentence is not part of it.
read -r total first <<< "$(python3 "$BUDGET" "$(fixture spacing "Short. Then more text here.")")"
[ "$first" -eq 6 ] && check "first sentence excludes its trailing space" 1 \
  || check "first sentence excludes trailing space (got $first, want 6)" 0

# --- sweep: every shipped SKILL.md obeys both halves ---
violations=$(python3 "$BUDGET" --sweep "$ROOT" || true)
[ -z "$violations" ] && check "every shipped SKILL.md is within 200 total / 80 first sentence" 1 \
  || { check "shipped SKILL.md budget sweep" 0; echo "$violations"; }

echo "---"
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
