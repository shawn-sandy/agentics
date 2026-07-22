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

# 5. URL source branch is documented and permitted.
# Patterns match on the facts the branch depends on, not on prose wording — a
# copy-edit should not fail these, but dropping the behavior must.
grep -qF 'claude.ai/code/artifact/' "$SKILL" || fail "artifact URL source not documented"
grep -qE '^allowed-tools:.*\bWebFetch\b' "$SKILL" || fail "WebFetch missing from allowed-tools"
grep -qi 'curl' "$SKILL" || fail "shell fetch (curl) is not addressed for the URL branch"
grep -qiE '403|SPA shell' "$SKILL" || fail "reason a shell fetch fails is not stated"

# 6. The URL branch documents each transform the saved file depends on.
# Asserted against SKILL.md — the skill IS the shipped artifact, so a check that
# only exercised a local shell helper would pass even after the skill lost the
# instruction it is meant to guard.
grep -qF '[Artifact' "$SKILL" || fail "response header format not documented"
grep -qiE 'discard|strip|drop' "$SKILL" || fail "header/runtime removal not documented"
grep -qF 'frame-runtime' "$SKILL" || fail "claude.ai frame-runtime block is not stripped — saved page would not be self-contained"
grep -qiF '<!doctype' "$SKILL" || fail "missing-<!doctype failure signal not documented"

# 7. Publishing is gated on a secrets scrub — docs/artifacts/ is served publicly.
grep -qF 'security-scrub' "$SKILL" || fail "no security-scrub gate before publishing to a public tree"

echo "PASS: save-artifact smoke test (7 checks)"
