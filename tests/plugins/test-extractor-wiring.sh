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
# Reviewers are scoped to `Bash(git *)`, so `node ...` is denied outright. Worse,
# Claude Code's Bash tool rejects ANY command containing `${...}` expansion
# ("Contains expansion") before permission rules are consulted — so a
# plugin-root-anchored invocation is unrunnable by every agent at every
# permission level, and no `tools:` grant can rescue it. A brief that documents
# one sends every reviewer down the silent full-HTML fallback on every cycle,
# which is the exact degradation 8.1.1 set out to fix. Briefs must therefore
# instruct a plain `Read` of the plan HTML instead.
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

echo "9. No documented interpreter invocation contains shell expansion..."
# The generalized invariant, and the one that would have caught 8.1.1's
# regression at the source. Claude Code's Bash tool refuses any command whose
# text contains `${VAR}` or `$VAR` — it cannot statically resolve the expansion,
# so it errors with "Contains expansion" BEFORE consulting permission rules.
# Verified empirically on 2.1.220: the refusal fires for an agent holding
# unrestricted `Bash`, and holds even with a matching `--allowedTools` rule.
#
# So `node "${CLAUDE_PLUGIN_ROOT}/scripts/foo.mjs"` never runs for anybody. That
# spelling is correct for a `Read` tool path (no shell involved) and fatal for a
# Bash command — 8.1.1 "fixed" 15 call sites into it and made the feature dead
# for every caller, including the lead and `prototype`.
#
# Matches a command *invocation* carrying an expansion anywhere in its
# arguments, not prose that merely names the variable. Scanning only the token
# straight after the command name would miss
# `node scripts/extract-plan-spec.mjs "$PLAN_PATH"`, which is just as dead —
# the guard reads the whole command string, so the position of `$` is
# irrelevant. Shared with check 10 so the two cannot drift apart.
# Excluded: CHANGELOG (history, not a call site) and the extractor's own usage
# text (byte-identical to the repo-root source; see the parity check in
# test-build-plan-html.mjs).
# Scope, stated honestly: this matches invocations of the commands named below,
# not every conceivable Bash snippet. The guard itself rejects expansion in ANY
# command, so a grep this shape is necessarily a subset — the check name says
# "interpreter invocation" rather than "Bash invocation" so it does not claim
# more than it enforces. `git`/`gh` are deliberately absent: prose in this tree
# says things like "not a git repo — fall back to `docs/prompts` relative to
# `$PWD`", which a `git` alternative matches as a command. A false positive on
# prose would train the next author to loosen the check.
#
# Scans to end of line rather than stopping at `|`/`;`/`&`: the guard is
# textual over the whole command string, so `node x.mjs | sed "$VAR"` is just
# as dead as an expansion in the first argument. Bounding at a pipe would have
# contradicted the position-independence argument this check rests on.
# Verified to change no result in the current tree.
EXPANSION_RE='(^|[[:space:]`"'"'"'(])(node|python3?|bash|sh|realpath)[[:space:]].*\$[{(]?[A-Za-z_]'
EXPANSION="$(grep -rnE "$EXPANSION_RE" \
  "$AGENTS_DIR" "$ROLE_PROMPTS" "$REVIEW_SKILL" \
  --include='*.md' 2>/dev/null || true)"
if [ -z "$EXPANSION" ]; then
  pass
else
  echo "$EXPANSION"
  fail "Bash invocation(s) above contain shell expansion — they error with 'Contains expansion' and never run. Use a literal path, or have the caller Read the file instead."
fi

# The plan-agent-scoped ledger that used to live here as check 10 has moved to
# tests/plugins/test-no-shell-expansion.sh, which tracks the same defect across
# every plugin. Two ledgers for one invariant guarantee drift; check 9 above
# stays because it is a *stricter* rule than the ledger — zero tolerance on the
# review surface, where a grandfathered entry would silently resurrect the 8.1.1
# regression.

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All extractor-wiring checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
