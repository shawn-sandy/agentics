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
if ! grep -q 'extract-plan-spec.mjs' "$ROLE_PROMPTS" \
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
  if grep -q 'extract-plan-spec.mjs' "$agent" || grep -qF "$AWK_ONELINER" "$agent"; then
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

echo "9. No documented Bash invocation contains shell expansion..."
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
# Matches a command *invocation* (`node ${...`), not prose that names the
# variable. Excluded: CHANGELOG (history, not a call site) and the extractor's
# own usage text (byte-identical to the repo-root source; see the parity check
# in test-build-plan-html.mjs).
EXPANSION="$(grep -rnE '(node|python3?|bash|sh) +"?\$\{?[A-Z_]+' \
  "$AGENTS_DIR" "$ROLE_PROMPTS" "$REVIEW_SKILL" \
  --include='*.md' 2>/dev/null || true)"
if [ -z "$EXPANSION" ]; then
  pass
else
  echo "$EXPANSION"
  fail "Bash invocation(s) above contain shell expansion — they error with 'Contains expansion' and never run. Use a literal path, or have the caller Read the file instead."
fi

echo "10. The known unfixed expansion call sites are exactly the documented set..."
# Check 9 is scoped to the review surface repaired in 8.2.1. The SAME defect
# exists elsewhere in this plugin and is NOT fixed here — the renderer pipeline
# is a separate change with its own design call, so it was deliberately left
# out of scope rather than quietly swept in.
#
# This is a ledger, not a suppression: it fails if a NEW site appears (silent
# spread) and it fails if one is FIXED without updating the list (silent rot).
# Either way a human looks. Widen check 9 and delete this once the list empties.
#
# Tracks `path:count`, not bare filenames. `grep -l` collapses every match in a
# file to one name, so a second broken invocation added to an already-listed
# file — or one of two fixed while the other remained — would leave the list
# identical and the check green. That is the same "asserts the description, not
# the behaviour" failure this whole change is about. Counts, not lines: line
# numbers churn on unrelated edits and would fail noisily for no reason.
KNOWN_BROKEN="skills/build/SKILL.md:1
skills/finalize-plan/references/write-completions.md:1
skills/implementation-plan/SKILL.md:1
skills/prototype/SKILL.md:1"
ACTUAL_BROKEN="$(grep -rcE '(node|python3?|bash|sh) +"?\$\{?[A-Z_]+' "$ROOT/kit/plugins/plan-agent/skills/" \
  --include='*.md' 2>/dev/null \
  | grep -v ':0$' \
  | sed "s|$ROOT/kit/plugins/plan-agent/||" | sort || true)"
if [ "$ACTUAL_BROKEN" = "$KNOWN_BROKEN" ]; then
  pass
else
  echo "  expected:"; echo "$KNOWN_BROKEN" | sed 's/^/    /'
  echo "  actual:";   echo "$ACTUAL_BROKEN" | sed 's/^/    /'
  fail "the shell-expansion ledger drifted — a site was added or fixed; update this list"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All extractor-wiring checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
