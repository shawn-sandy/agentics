#!/usr/bin/env bash
# Integration test for the memory-tools write guard (plan step 4).
# Runs the shipped bin/memory-verify-write wrapper — the check both
# agentic-memory-management and path-rules-advisor document as their post-write
# gate — against fixture CLAUDE.md files in a temp dir, never a real CLAUDE.md.
# Covers both directions: valid frontmatter is rewritten and diffed, malformed
# frontmatter is reported and the file is left untouched.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DOCTOR="$ROOT/kit/plugins/memory-tools/skills/agentic-memory-management/SKILL.md"
ADVISOR="$ROOT/kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md"
WRAPPER="$ROOT/kit/plugins/memory-tools/bin/memory-verify-write"
# path-rules-advisor is split core-plus-references: the STOP contract and the
# in-core link stay in SKILL.md, the executable check lives under references/.
# Assertions about shipped *code* therefore scan the skill directory, while the
# assertions about the *rule* stay anchored on the core (checks 1 and 1b below).
ADVISOR_DIR="$(dirname "$ADVISOR")"
FAILURES=0

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Concatenate a skill's core with any reference files it ships, so a check that
# asserts on shipped instructions does not go silently green when content moves
# behind a link. Prints to stdout.
skill_bundle() {
  cat "$1"
  local dir
  dir="$(dirname "$1")/references"
  [ -d "$dir" ] || return 0
  for r in "$dir"/*.md; do [ -f "$r" ] && cat "$r"; done
}

# Same bundle, materialised at $BUNDLE. Use this for any consumer that may stop
# reading early — see the SIGPIPE note on extract_check below.
bundle_file() {
  BUNDLE="$TMP/bundle-$(basename "$(dirname "$1")").md"
  skill_bundle "$1" > "$BUNDLE"
}

pass() { echo "  PASS${1:+ ($1)}"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== memory-tools write guard integration test ==="

# --- Structural assertions on the shipped skills ------------------------------

echo "1. Both skills document a post-write verification..."
MISSING=""
[ -f "$DOCTOR" ] || MISSING="$MISSING agentic-memory-management/SKILL.md"
[ -f "$ADVISOR" ] || MISSING="$MISSING path-rules-advisor/SKILL.md"
grep -qF 'Verify the write' "$DOCTOR" 2>/dev/null || MISSING="$MISSING doctor:heading"
grep -qF 'Verify the write' "$ADVISOR" 2>/dev/null || MISSING="$MISSING advisor:heading"
# The runnable check is the bin/ wrapper, invoked by bare name in command
# position — a `${CLAUDE_PLUGIN_ROOT}`-anchored or heredoc form is refused by
# the Bash tool ("Contains expansion") and never runs for anybody.
grep -qE '^[[:space:]]*memory-verify-write([[:space:]]|$)' "$DOCTOR" 2>/dev/null || MISSING="$MISSING doctor:wrapper"
bundle_file "$ADVISOR"
grep -qE '^[[:space:]]*memory-verify-write([[:space:]]|$)' "$BUNDLE" || MISSING="$MISSING advisor:wrapper"
grep -qF 'REPORT rather than write' "$DOCTOR" 2>/dev/null || MISSING="$MISSING doctor:gate"
grep -qF 'REPORT rather than write' "$ADVISOR" 2>/dev/null || MISSING="$MISSING advisor:gate"
if [ -z "$MISSING" ]; then pass; else fail "missing:$MISSING"; fi

echo "1b. The advisor's STOP contract and reference wiring stay in the core..."
# The whole point of leaving the check behind a link is that the *rule* is still
# unconditionally loaded. So the core — not a reference — must carry the
# non-zero-exit STOP, the pre-write gate, and a resolvable pointer at the file
# holding the executable check.
MISSING=""
grep -qF '**STOP**' "$ADVISOR" || MISSING="$MISSING core:stop"
grep -qF 'REPORT rather than write' "$ADVISOR" || MISSING="$MISSING core:gate"
grep -qF 'references/write-verification.md' "$ADVISOR" || MISSING="$MISSING core:pointer"
[ -f "$ADVISOR_DIR/references/write-verification.md" ] || MISSING="$MISSING reference:missing"
if [ -z "$MISSING" ]; then pass; else fail "advisor core lost:$MISSING"; fi

echo "2. Declared Bash patterns actually cover the commands the guard runs..."
# Permission patterns are prefix matches, so declaring Bash(git diff:*) while the
# block runs `git --no-pager diff` leaves the check to stall on a prompt.
MISSING=""
for f in "$DOCTOR" "$ADVISOR"; do
  NAME=$(basename "$(dirname "$f")")
  TOOLS=$(grep -m1 '^allowed-tools:' "$f")
  # Commands are extracted from the shipped bash block, not hardcoded here, so a
  # second command added to the guard is covered automatically. Since the guard
  # moved into bin/memory-verify-write, the documented block carries exactly one
  # command — the wrapper's bare name.
  bundle_file "$f"
  CMDS=$(awk '/^```bash$/,/^```$/' "$BUNDLE" \
    | grep -oE '^[[:space:]]*(git|python3|node|jq|sed|awk|memory-verify-write)[^|;&]*' \
    | sed 's/^[[:space:]]*//' | sort -u)
  if [ "$(printf '%s' "$CMDS" | grep -c .)" -lt 1 ]; then
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

# --- The shipped check is the wrapper; run the real thing ----------------------
# Both skills document one command — bin/memory-verify-write — so every
# behavioral check below runs that wrapper itself. There is no extraction step
# left to drift: mutating verify_write.py fails here directly, in both the
# pass and the fail direction.

echo "3. The shipped wrapper is executable and resolves its python target..."
CHECK_TARGET="$(sed -n 's|.*exec [a-z0-9]* "\$(dirname "\$0")/\([^"]*\)".*|\1|p' "$WRAPPER" 2>/dev/null || true)"
if [ -x "$WRAPPER" ] && [ -n "$CHECK_TARGET" ] && [ -f "$(dirname "$WRAPPER")/$CHECK_TARGET" ]; then
  pass "memory-verify-write -> $CHECK_TARGET"
else
  fail "bin/memory-verify-write is missing, not executable, has no recognizable exec line, or points at a missing target"
fi

# Guard-then-write, modelling the skills' verification gate: the check runs on
# the target before the overwrite, and a non-zero exit means REPORT, not write.
guarded_write() {
  local target="$1" new="$2"
  if [ -f "$target" ] && ! "$WRAPPER" "$target" >/dev/null 2>&1; then
    return 1
  fi
  printf '%s' "$new" > "$target"
  "$WRAPPER" "$target" >/dev/null
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
OUT="$("$WRAPPER" "$TMP/malformed.md" 2>&1 || true)"
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
if "$WRAPPER" "$TMP/badline.md" >/dev/null 2>&1; then
  fail "check passed on a frontmatter line that is not a YAML key/value"
else
  pass
fi

echo "8. An empty body is reported..."
printf -- '---\nname: fixture\n---\n\n' > "$TMP/emptybody.md"
OUT="$("$WRAPPER" "$TMP/emptybody.md" 2>&1 || true)"
if printf '%s' "$OUT" | grep -qF 'EMPTY'; then pass; else fail "expected an EMPTY report, got: $OUT"; fi

echo "9. Block scalars and nested values are not reported as malformed..."
printf -- '---\ndescription: >\n  folded text continuing here\npaths:\n  - "src/**"\n---\n\n# Project\n' > "$TMP/blockscalar.md"
OUT="$("$WRAPPER" "$TMP/blockscalar.md" 2>&1 || true)"
if "$WRAPPER" "$TMP/blockscalar.md" >/dev/null 2>&1; then
  pass "folded scalar + nested list"
else
  fail "valid YAML block scalar reported as malformed: $OUT"
fi

echo "10. A frontmatter-less file with a body still passes..."
printf -- '# Project\n\n- Rule\n' > "$TMP/nofm.md"
if "$WRAPPER" "$TMP/nofm.md" >/dev/null 2>&1; then pass; else fail "check rejected a valid frontmatter-less file"; fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: memory-tools write guard (11 checks)"
else
  echo "FAIL: $FAILURES check(s) failed"
  exit 1
fi
