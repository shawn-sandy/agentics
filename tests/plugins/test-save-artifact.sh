#!/usr/bin/env bash
# Objective smoke test for the save-artifact skill.
# Asserts the skill's documented copy logic lands a dated artifact under
# ${CLAUDE_PLUGIN_ROOT}/artifacts and refuses to write when the var is unset.
set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/social-media-tools/skills/save-artifact/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }

# 1. Skill exists and documents the destination + guard.
[ -f "$SKILL" ] || fail "SKILL.md missing at $SKILL"
grep -q 'CLAUDE_PLUGIN_ROOT}/artifacts' "$SKILL" || fail "destination not documented"
grep -q 'CLAUDE_PLUGIN_ROOT is not set' "$SKILL" || fail "unset-var guard not documented"

# The copy recipe under test, mirroring SKILL.md Steps 2-3.
run_save() {
  local src="$1"
  [ -n "${CLAUDE_PLUGIN_ROOT:-}" ] || { echo "Error: CLAUDE_PLUGIN_ROOT is not set" >&2; return 1; }
  local dest="${CLAUDE_PLUGIN_ROOT}/artifacts"
  mkdir -p "$dest" || { echo "Error: could not create $dest" >&2; return 1; }
  local base day target n
  base=$(basename "$src" .html); day=$(date +%F)
  target="$dest/${base}-${day}.html"; n=2
  while [ -e "$target" ]; do target="$dest/${base}-${day}-${n}.html"; n=$((n + 1)); done
  cp "$src" "$target" || { echo "Error: copy failed — nothing saved" >&2; return 1; }
  echo "$target"
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
printf '<!DOCTYPE html><title>demo</title>' > "$tmp/demo.html"

# 2. Happy path: file lands under artifacts/ with a dated name, path printed.
export CLAUDE_PLUGIN_ROOT="$tmp/plugin"
out="$(run_save "$tmp/demo.html")" || fail "save exited non-zero"
[ -f "$out" ] || fail "no file at reported path: $out"
case "$out" in
  "$tmp/plugin/artifacts/demo-"*.html) : ;;
  *) fail "unexpected path: $out" ;;
esac

# 3. Collision: second save of the same source gets a suffixed name.
out2="$(run_save "$tmp/demo.html")" || fail "second save exited non-zero"
[ "$out2" != "$out" ] || fail "collision not handled — same path returned twice"
[ -f "$out2" ] || fail "no file for second save"

# 4. Copy failure: missing source exits non-zero, no false success.
if out3="$(run_save "$tmp/does-not-exist.html" 2>/dev/null)"; then
  fail "expected non-zero exit when source is missing (got: $out3)"
fi

# 5. Unset guard: refuses to write, exits non-zero.
unset CLAUDE_PLUGIN_ROOT
if run_save "$tmp/demo.html" >/dev/null 2>&1; then
  fail "expected non-zero exit when CLAUDE_PLUGIN_ROOT is unset"
fi

echo "PASS: save-artifact smoke test (5 checks)"
