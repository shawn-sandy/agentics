#!/usr/bin/env bash
# Integration test for the memory-tools write guard (plan step 4).
# Extracts the parse check that agentic-memory-doctor and path-rules-advisor
# ship in their SKILL.md and runs it against fixture CLAUDE.md files in a temp
# dir — never a real CLAUDE.md. Covers both directions: valid frontmatter is
# rewritten and diffed, malformed frontmatter is reported and the file is left
# untouched.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DOCTOR="$ROOT/kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md"
ADVISOR="$ROOT/kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md"
FAILURES=0

pass() { echo "  PASS${1:+ ($1)}"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== memory-tools write guard integration test ==="

# --- Structural assertions on the shipped skills ------------------------------

echo "1. Both skills document a post-write verification..."
MISSING=""
[ -f "$DOCTOR" ] || MISSING="$MISSING agentic-memory-doctor/SKILL.md"
[ -f "$ADVISOR" ] || MISSING="$MISSING path-rules-advisor/SKILL.md"
grep -qF 'Verify the write' "$DOCTOR" 2>/dev/null || MISSING="$MISSING doctor:heading"
grep -qF 'Verify the write' "$ADVISOR" 2>/dev/null || MISSING="$MISSING advisor:heading"
grep -qF 'git --no-pager diff -- "$TARGET"' "$DOCTOR" 2>/dev/null || MISSING="$MISSING doctor:diff"
grep -qF 'git --no-pager diff -- "$TARGET"' "$ADVISOR" 2>/dev/null || MISSING="$MISSING advisor:diff"
grep -qF 'REPORT rather than write' "$DOCTOR" 2>/dev/null || MISSING="$MISSING doctor:gate"
grep -qF 'REPORT rather than write' "$ADVISOR" 2>/dev/null || MISSING="$MISSING advisor:gate"
if [ -z "$MISSING" ]; then pass; else fail "missing:$MISSING"; fi

echo "2. Declared Bash patterns actually cover the commands the guard runs..."
# Permission patterns are prefix matches, so declaring Bash(git diff:*) while the
# block runs `git --no-pager diff` leaves the check to stall on a prompt.
MISSING=""
for f in "$DOCTOR" "$ADVISOR"; do
  NAME=$(basename "$(dirname "$f")")
  TOOLS=$(grep -m1 '^allowed-tools:' "$f")
  # Commands are extracted from the shipped bash block, not hardcoded here, so a
  # third command added to the guard is covered automatically.
  CMDS=$(awk '/^```bash$/,/^```$/' "$f" \
    | grep -oE '^[[:space:]]*(git|python3|node|jq|sed|awk)[^|;&]*' \
    | sed 's/^[[:space:]]*//' | sort -u)
  if [ "$(printf '%s' "$CMDS" | grep -c .)" -lt 2 ]; then
    MISSING="$MISSING $NAME:[extracted-no-commands]"
  fi
  while IFS= read -r CMD; do
    [ -n "$CMD" ] || continue
    COVERED=""
    while IFS= read -r PAT; do
      [ -n "$PAT" ] || continue
      case "$CMD" in $PAT) COVERED=yes ;; esac
    done <<EOF
$(echo "$TOOLS" | grep -oE 'Bash\([^)]*\)' | sed -e 's/^Bash(//' -e 's/)$//' -e 's/:\*$/*/')
EOF
    [ -n "$COVERED" ] || MISSING="$MISSING $NAME:[${CMD%% *}]"
  done <<EOF
$CMDS
EOF
done
if [ -z "$MISSING" ]; then pass; else fail "allowed-tools does not cover:$MISSING"; fi

# --- Extract the shipped check so the test exercises the real thing -----------

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

extract_check() {
  awk '/^python3 - "\$TARGET" <<'"'"'EOF'"'"'$/ {grab=1; next} grab && /^EOF$/ {exit} grab {print}' "$1"
}

extract_check "$DOCTOR" > "$TMP/check.py"
extract_check "$ADVISOR" > "$TMP/check-advisor.py"

echo "3. The parse check is extractable from both skills and identical..."
if [ -s "$TMP/check.py" ] && cmp -s "$TMP/check.py" "$TMP/check-advisor.py"; then
  pass "$(wc -l < "$TMP/check.py" | tr -d ' ') lines"
else
  fail "check block missing from a skill or the two copies have drifted"
fi

# Guard-then-write, modelling the skills' verification gate: the check runs on
# the target before the overwrite, and a non-zero exit means REPORT, not write.
guarded_write() {
  local target="$1" new="$2"
  if [ -f "$target" ] && ! python3 "$TMP/check.py" "$target" >/dev/null 2>&1; then
    return 1
  fi
  printf '%s' "$new" > "$target"
  python3 "$TMP/check.py" "$target" >/dev/null
}

# --- Case: valid frontmatter is rewritten and diffed --------------------------

REPO="$TMP/repo"
mkdir -p "$REPO"
git -C "$REPO" init -q
git -C "$REPO" config user.email test@example.com
git -C "$REPO" config user.name test
printf -- '---\nname: fixture\n---\n\n# Project\n\n- Original rule\n' > "$REPO/CLAUDE.md"
git -C "$REPO" add CLAUDE.md
git -C "$REPO" commit -qm fixture

echo "4. Valid frontmatter: guard allows the write and the check passes..."
if guarded_write "$REPO/CLAUDE.md" '---
name: fixture
---

# Project

- Optimized rule
'; then pass; else fail "guarded write rejected a valid fixture"; fi

echo "5. The write produces a non-empty diff..."
DIFF="$(git -C "$REPO" --no-pager diff -- CLAUDE.md)"
if [ -n "$DIFF" ] && printf '%s' "$DIFF" | grep -qF '+- Optimized rule'; then
  pass
else
  fail "no diff for the rewritten file"
fi

# --- Negative cases: the check must FAIL on bad output ------------------------

echo "6. Malformed frontmatter is reported and the file is left untouched..."
printf -- '---\nname: broken\n\n# Project\n\n- Rule\n' > "$TMP/malformed.md"
BEFORE="$(cksum < "$TMP/malformed.md")"
OUT="$(python3 "$TMP/check.py" "$TMP/malformed.md" 2>&1 || true)"
if guarded_write "$TMP/malformed.md" 'REPLACED' 2>/dev/null; then
  fail "guard allowed a write over malformed frontmatter"
elif [ "$(cksum < "$TMP/malformed.md")" != "$BEFORE" ]; then
  fail "file was modified despite the guard rejecting it"
elif ! printf '%s' "$OUT" | grep -qF 'MALFORMED'; then
  fail "expected a MALFORMED report, got: $OUT"
else
  pass "unterminated frontmatter block"
fi

echo "7. A non key/value frontmatter line is reported..."
printf -- '---\nname: fixture\njust a sentence\n---\n\n# Project\n' > "$TMP/badline.md"
if python3 "$TMP/check.py" "$TMP/badline.md" >/dev/null 2>&1; then
  fail "check passed on a frontmatter line that is not a YAML key/value"
else
  pass
fi

echo "8. An empty body is reported..."
printf -- '---\nname: fixture\n---\n\n' > "$TMP/emptybody.md"
OUT="$(python3 "$TMP/check.py" "$TMP/emptybody.md" 2>&1 || true)"
if printf '%s' "$OUT" | grep -qF 'EMPTY'; then pass; else fail "expected an EMPTY report, got: $OUT"; fi

echo "9. Block scalars and nested values are not reported as malformed..."
printf -- '---\ndescription: >\n  folded text continuing here\npaths:\n  - "src/**"\n---\n\n# Project\n' > "$TMP/blockscalar.md"
OUT="$(python3 "$TMP/check.py" "$TMP/blockscalar.md" 2>&1 || true)"
if python3 "$TMP/check.py" "$TMP/blockscalar.md" >/dev/null 2>&1; then
  pass "folded scalar + nested list"
else
  fail "valid YAML block scalar reported as malformed: $OUT"
fi

echo "10. A frontmatter-less file with a body still passes..."
printf -- '# Project\n\n- Rule\n' > "$TMP/nofm.md"
if python3 "$TMP/check.py" "$TMP/nofm.md" >/dev/null 2>&1; then pass; else fail "check rejected a valid frontmatter-less file"; fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: memory-tools write guard (10 checks)"
else
  echo "FAIL: $FAILURES check(s) failed"
  exit 1
fi
