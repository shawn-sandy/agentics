#!/usr/bin/env bash
# Objective smoke test for the save-artifact skill.
# Asserts the skill's documented copy logic lands a dated artifact under the
# local inbox .claude/artifacts, and that the skill publishes via plan-agent's
# build-artifacts-index.sh (not the old {plansDirectory}/artifacts + plans index).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/social-media-tools/skills/save-artifact/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }

# 1. Skill exists and documents the new inbox destination + publish step.
[ -f "$SKILL" ] || fail "SKILL.md missing at $SKILL"
grep -qF '.claude/artifacts' "$SKILL" || fail "inbox destination not documented"
grep -qF 'build-artifacts-index.sh' "$SKILL" || fail "publish step not documented"
grep -qF '{plansDirectory}/artifacts' "$SKILL" && fail "stale {plansDirectory}/artifacts still documented"

# The resolve+copy logic from SKILL.md Steps 2-3, run relative to cwd; prints
# the bare target path so checks can parse it. Destination is fixed — no
# plansDirectory lookup.
run_save() {
  local src="$1"
  local dest base day target n
  dest=".claude/artifacts"
  mkdir -p "$dest" || { echo "Error: could not create $dest" >&2; return 1; }
  base=$(basename "$src" .html); day=$(date +%F)
  target="$dest/${base}-${day}.html"; n=2
  while [ -e "$target" ]; do target="$dest/${base}-${day}-${n}.html"; n=$((n + 1)); done
  cp "$src" "$target" || { echo "Error: copy failed — nothing saved" >&2; return 1; }
  echo "$target"
}

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
printf '<!DOCTYPE html><title>demo</title>' > "$tmp/src-demo.html"

# 2. Save lands under .claude/artifacts/ with a dated name.
proj="$tmp/proj"
mkdir -p "$proj"
out="$(cd "$proj" && run_save "$tmp/src-demo.html")" || fail "save exited non-zero"
case "$out" in
  .claude/artifacts/src-demo-*.html) : ;;
  *) fail "unexpected inbox path: $out" ;;
esac
[ -f "$proj/$out" ] || fail "no file at reported path: $proj/$out"

# 3. Collision: second save of the same source gets a suffixed name.
out2="$(cd "$proj" && run_save "$tmp/src-demo.html")" || fail "second save exited non-zero"
[ "$out2" != "$out" ] || fail "collision not handled — same path returned twice"
[ -f "$proj/$out2" ] || fail "no file for second save"

# 4. Copy failure: missing source exits non-zero, no false success.
if out3="$(cd "$proj" && run_save "$tmp/does-not-exist.html" 2>/dev/null)"; then
  fail "expected non-zero exit when source is missing (got: $out3)"
fi

echo "PASS: save-artifact smoke test (4 checks)"
