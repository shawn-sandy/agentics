#!/usr/bin/env bash
set -euo pipefail

# Integration test for the compute-on-read plan spec extractor
# (docs/plans/replace-plan-digest-with-extractor.html). Asserts the plan-agent
# tree is wired to scripts/extract-plan-spec.mjs and that the retired
# #plan-digest cache + its awk one-liner are gone from generated output and the
# review path. Spec-extraction behavior itself is covered by the node test
# tests/plugins/test-extract-plan-spec.mjs.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKELETON="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html"
PLAN_SKILL="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/SKILL.md"
REVIEW_SKILL="$ROOT/kit/plugins/plan-agent/skills/review-plan/SKILL.md"
ROLE_PROMPTS="$ROOT/kit/plugins/plan-agent/skills/review-plan/references/role-prompts.md"
AGENTS_DIR="$ROOT/kit/plugins/plan-agent/agents"
PLUGIN_EXTRACTOR="$ROOT/kit/plugins/plan-agent/scripts/extract-plan-spec.mjs"
BACKFILL_TEST="$ROOT/tests/plugins/test-backfill-digest.mjs"
AWK_ONELINER="awk '!f && /<script[^>]*id=\"plan-digest\""
FAILURES=0

pass() { echo "  PASS"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== Extractor Wiring Test ==="

echo "1. SKELETON.html embeds no #plan-digest block..."
if ! grep -q 'id="plan-digest"' "$SKELETON" && ! grep -q 'text/markdown' "$SKELETON"; then
  pass
else
  fail "skeleton still contains a #plan-digest / text/markdown block"
fi

echo "2. Skeleton buildImplementPrompt() is self-contained (reads the spec by path, no repo-local script)..."
if grep -qF "Read the plan spec at ' + specPath" "$SKELETON" \
  && ! grep -q 'extract-plan-spec.mjs' "$SKELETON" \
  && ! grep -qF "$AWK_ONELINER" "$SKELETON"; then
  pass
else
  fail "Copy-button JS is not self-contained (references a repo-local script or still uses awk)"
fi

echo "3. implementation-plan SKILL.md: generated prompts are self-contained, digest section gone..."
if grep -q 'Read and implement all steps in the plan at <filepath>' "$PLAN_SKILL" \
  && grep -q 'Brief subagents with the plan file at <filepath>' "$PLAN_SKILL" \
  && ! grep -q 'extract-plan-spec.mjs' "$PLAN_SKILL" \
  && ! grep -q 'Machine-Readable Digest' "$PLAN_SKILL" \
  && ! grep -q '{plan-digest}' "$PLAN_SKILL" \
  && ! grep -qF "$AWK_ONELINER" "$PLAN_SKILL"; then
  pass
else
  fail "SKILL.md generated prompts still reference a repo-local script, or the digest section/awk remains"
fi

echo "4. review-plan SKILL.md: no digest-refresh pass, reads via the extractor..."
if ! grep -q 'Refresh the digest' "$REVIEW_SKILL" \
  && ! grep -q 'Pass 1b' "$REVIEW_SKILL" \
  && grep -q 'extract-plan-spec.mjs' "$REVIEW_SKILL"; then
  pass
else
  fail "review-plan SKILL.md still has a digest-refresh pass or lacks the extractor reference"
fi

echo "5. No reviewer brief instructs an extractor invocation the reviewer cannot run..."
# Reviewers are scoped to `Bash(git *)`, so `node ...` is denied outright. A
# brief that documents an extractor invocation sends every reviewer down the
# silent full-HTML fallback on every cycle, which is the exact degradation
# 8.1.1 set out to fix. Briefs must therefore instruct a plain `Read` of the
# plan HTML instead.
if ! grep -qF 'extract-plan-spec.mjs' "$ROLE_PROMPTS" \
  && ! grep -qF "$AWK_ONELINER" "$ROLE_PROMPTS"; then
  pass
else
  fail "role-prompts.md still instructs reviewers to run the extractor (or uses awk) — reviewers cannot execute it"
fi

echo "6. No reviewer agent def instructs an extractor invocation it cannot run..."
AGENT_FAIL=0
AGENT_COUNT=0
for agent in "$AGENTS_DIR"/plan-reviewer-*.md; do
  AGENT_COUNT=$((AGENT_COUNT + 1))
  if grep -qF 'extract-plan-spec.mjs' "$agent" || grep -qF "$AWK_ONELINER" "$agent"; then
    echo "  FAIL: $(basename "$agent") instructs an extractor/awk invocation it cannot execute"
    AGENT_FAIL=1
  fi
done
if [ "$AGENT_FAIL" -eq 0 ] && [ "$AGENT_COUNT" -eq 10 ]; then
  pass
else
  fail "expected 10 clean agent defs, found $AGENT_COUNT with failures=$AGENT_FAIL"
fi

echo "7. test-backfill-digest.mjs corpus assertion scoped to legacy embedded plans..."
if grep -q 'stays idempotent on legacy embedded plans' "$BACKFILL_TEST" \
  && grep -q 'Compute-on-read plans ship without a digest' "$BACKFILL_TEST"; then
  pass
else
  fail "backfill corpus assertion is not scoped so digest-free plans pass"
fi

echo "8. The extractor actually ships with the plugin and runs from there..."
# Checks 4-6 only prove the docs *mention* the extractor. This proves an
# installed user can run it: the plugin copy must exist and load (exit 2 =
# documented "misuse", which is only reachable once its ./lib/plan-spec.mjs
# import has resolved inside the plugin tree).
EXTRACTOR_RC=-1
if [ -f "$PLUGIN_EXTRACTOR" ]; then
  EXTRACTOR_RC=0
  node "$PLUGIN_EXTRACTOR" >/dev/null 2>&1 || EXTRACTOR_RC=$?
fi
if [ "$EXTRACTOR_RC" -eq 2 ]; then
  pass
else
  fail "kit/plugins/plan-agent/scripts/extract-plan-spec.mjs is missing or does not load — installed users cannot run the extractor"
fi

# Checks 9-10 (the shell-expansion ledger) were retired with the bin/ wrapper
# architecture: Claude Code now substitutes ${CLAUDE_PLUGIN_ROOT} and
# ${CLAUDE_SKILL_DIR} into skill/command/agent markdown at load time, so a
# placeholder-anchored command is the sanctioned invocation shape, and claude.ai
# refuses to install any plugin shipping a top-level bin/. The repo-wide guard
# for the new invariant — no bin/, placeholder paths resolve, reference files
# carry the substitution note — is tests/plugins/test-plugin-script-invocations.sh.

echo "9. Documented placeholder paths resolve inside the plugin..."
# A placeholder path that names a missing file is the modern "documented but
# unrunnable" defect — the 8.1.1 failure shape, one layer up. Every
# ${CLAUDE_PLUGIN_ROOT}/<path> in the plugin's markdown must resolve against
# the plugin root, and every ${CLAUDE_SKILL_DIR}/<path> against the skill
# folder containing the file.
PLUGIN_DIR="$ROOT/kit/plugins/plan-agent"
BROKEN_PATHS=""
while IFS= read -r line; do
  [ -n "$line" ] || continue
  file="${line%%:*}"
  match="${line#*:}"
  rel="${match#*\}/}"
  case "$match" in
    "\${CLAUDE_PLUGIN_ROOT}/"*)
      [ -e "$PLUGIN_DIR/$rel" ] || BROKEN_PATHS="$BROKEN_PATHS\n    ${file#"$PLUGIN_DIR/"} -> $match" ;;
    "\${CLAUDE_SKILL_DIR}/"*)
      skilldir="$(printf '%s' "$file" | sed -n 's|\(.*/skills/[^/]*\)/.*|\1|p')"
      if [ -z "$skilldir" ] || [ ! -e "$skilldir/$rel" ]; then
        BROKEN_PATHS="$BROKEN_PATHS\n    ${file#"$PLUGIN_DIR/"} -> $match"
      fi ;;
  esac
done <<EOF
$(grep -roE '\$\{CLAUDE_(PLUGIN_ROOT|SKILL_DIR)\}/[A-Za-z0-9_./-]+' "$PLUGIN_DIR" --include='*.md' 2>/dev/null | grep -v '/CHANGELOG\.md:' | sort -u)
EOF
if [ -z "$BROKEN_PATHS" ]; then
  pass
else
  printf "%b\n" "$BROKEN_PATHS"
  fail "placeholder path(s) above do not resolve to a shipped file"
fi

echo "11. The documented renderer and gallery scripts run from the plugin tree..."
# The positive half of check 9: the files the placeholders point at must
# actually load. exit 2 is build-plan-html.mjs's documented no-args usage code,
# reachable only once its ./lib imports have resolved inside the plugin tree.
# The gallery hooks rebuild galleries as a side effect, so they are proven with
# a syntax check rather than a run.
RENDER_RC=0
node "$PLUGIN_DIR/scripts/build-plan-html.mjs" >/dev/null 2>&1 || RENDER_RC=$?
if [ "$RENDER_RC" -eq 2 ] \
  && bash -n "$PLUGIN_DIR/hooks/build-prototypes-index.sh" 2>/dev/null \
  && bash -n "$PLUGIN_DIR/hooks/build-index.sh" 2>/dev/null \
  && bash -n "$PLUGIN_DIR/hooks/build-designs-index.sh" 2>/dev/null; then
  pass
else
  fail "renderer no-args rc=$RENDER_RC (want 2), or a gallery hook script fails bash -n"
fi

echo "11b. plans-library invokes the gallery builder in command position..."
# The positive half of the plans-library repair, and the one that would have
# caught PR #524: that branch replaced the skill's hand-rolled scan with a
# single delegated command that could never run. Anchored to command position —
# prose naming the script opens with a backtick, which is not whitespace, so it
# cannot satisfy this the way a bare `grep -F` would.
if grep -qE '^[[:space:]]*bash "\$\{CLAUDE_PLUGIN_ROOT\}/hooks/build-index\.sh"([[:space:]]|$)' \
     "$PLUGIN_DIR/skills/plans-library/SKILL.md" 2>/dev/null; then
  pass
else
  fail "plans-library/SKILL.md no longer invokes hooks/build-index.sh via \${CLAUDE_PLUGIN_ROOT} in command position — the delegation was removed, renamed, or respelled"
fi

echo "12. No top-level bin/ ships, in the tree or through the dist KEEP list..."
# claude.ai and Cowork refuse to install any plugin carrying a top-level bin/
# directory, so shipping one makes the whole plugin uninstallable there. The
# KEEP list half guards the dist build from re-growing one.
#
# The KEEP membership is parsed with node, not grepped as a formatted line: a
# re-added `"bin",`, a quote-style change, or a one-line array would all slip
# past a `grep "'bin',"` while 'bin' was back in KEEP — the same vacuous-guard
# shape the retired test-no-shell-expansion.sh check 4 documented. Three
# outcomes, deliberately distinct: 1 = absent (good), 0 = present (fail),
# 3 = the KEEP block could not be located, which must not read as success.
KEEP_STATUS=0
node -e '
  const fs = require("fs");
  let src;
  try { src = fs.readFileSync(process.argv[1], "utf8"); } catch { process.exit(3); }
  const m = src.match(/const\s+KEEP\s*=\s*new\s+Set\(\s*\[([\s\S]*?)\]\s*\)/);
  if (!m) process.exit(3);
  const items = [...m[1].matchAll(/["'"'"'`]([^"'"'"'`]+)["'"'"'`]/g)].map((x) => x[1]);
  process.exit(items.includes("bin") ? 0 : 1);
' "$ROOT/scripts/build-dist.mjs" || KEEP_STATUS=$?
if [ "$KEEP_STATUS" -eq 3 ]; then
  fail "could not locate the KEEP allowlist in scripts/build-dist.mjs — this check is no longer measuring anything; update the parser"
elif [ "$KEEP_STATUS" -eq 1 ] && [ ! -d "$PLUGIN_DIR/bin" ]; then
  pass
else
  fail "plan-agent ships a top-level bin/ or scripts/build-dist.mjs KEEP lists 'bin' — claude.ai refuses to install plugins with a top-level bin/"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All extractor-wiring checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
