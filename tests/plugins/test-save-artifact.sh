#!/usr/bin/env bash
# Objective smoke test for the save-artifact skill.
# Asserts the skill's documented copy logic lands a dated artifact under
# <plansDirectory>/artifacts, resolving plansDirectory from the project's
# .claude/settings.json with a docs/plans fallback.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/social-media-tools/skills/save-artifact/SKILL.md"
fail() { echo "FAIL: $1" >&2; exit 1; }

# 1. Skill exists and documents the plans-directory destination.
[ -f "$SKILL" ] || fail "SKILL.md missing at $SKILL"
grep -qF '{plansDirectory}/artifacts' "$SKILL" || fail "destination not documented"
grep -q 'plansDirectory' "$SKILL" || fail "plansDirectory resolution not documented"

# The resolve+copy logic from SKILL.md Steps 2-3, run relative to cwd; prints
# the bare target path so checks can parse it.
run_save() {
  local src="$1"
  local plans dest base day target n
  plans=$(node -e 'try{process.stdout.write((require("./.claude/settings.json").plansDirectory||"").trim())}catch(e){}' 2>/dev/null)
  plans="${plans:-docs/plans}"
  dest="$plans/artifacts"
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

# 2. Configured plansDirectory: file lands under <plansDirectory>/artifacts/.
proj="$tmp/proj-configured"
mkdir -p "$proj/.claude"
printf '{ "plansDirectory": "content/plans" }' > "$proj/.claude/settings.json"
out="$(cd "$proj" && run_save "$tmp/src-demo.html")" || fail "save exited non-zero"
case "$out" in
  content/plans/artifacts/src-demo-*.html) : ;;
  *) fail "unexpected path for configured plansDirectory: $out" ;;
esac
[ -f "$proj/$out" ] || fail "no file at reported path: $proj/$out"

# 3. Fallback: no settings.json → docs/plans/artifacts/.
projf="$tmp/proj-fallback"
mkdir -p "$projf"
outf="$(cd "$projf" && run_save "$tmp/src-demo.html")" || fail "fallback save exited non-zero"
case "$outf" in
  docs/plans/artifacts/src-demo-*.html) : ;;
  *) fail "fallback did not resolve to docs/plans/artifacts: $outf" ;;
esac
[ -f "$projf/$outf" ] || fail "no file for fallback save: $projf/$outf"

# 4. Collision: second save of the same source gets a suffixed name.
out2="$(cd "$projf" && run_save "$tmp/src-demo.html")" || fail "second save exited non-zero"
[ "$out2" != "$outf" ] || fail "collision not handled — same path returned twice"
[ -f "$projf/$out2" ] || fail "no file for second save"

# 5. Copy failure: missing source exits non-zero, no false success.
if out3="$(cd "$projf" && run_save "$tmp/does-not-exist.html" 2>/dev/null)"; then
  fail "expected non-zero exit when source is missing (got: $out3)"
fi

echo "PASS: save-artifact smoke test (5 checks)"
