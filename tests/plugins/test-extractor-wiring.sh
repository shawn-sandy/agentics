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

# This is a ledger, not a suppression: it fails if a NEW site appears (silent
# spread) and it fails if one is FIXED without updating the list (silent rot).
# Either way a human looks. Delete this once the list empties — check 9 needs no
# edit, since it already excludes exactly what is ledgered here.
#
# Tracks `path:count`, not bare filenames. `grep -l` collapses every match in a
# file to one name, so a second broken invocation added to an already-listed
# file — or one of two fixed while the other remained — would leave the list
# identical and the check green. That is the same "asserts the description, not
# the behaviour" failure this whole change is about. Counts, not lines: line
# numbers churn on unrelated edits and would fail noisily for no reason.
#
# 8.3.0 removed the four renderer-pipeline entries by shipping bin/ wrappers
# (checks 11-12). What remains is the GALLERY pipeline, a different defect
# class: these are not bundled-script paths but multi-line snippets whose
# variables are set in the same shell block — `while IFS= read -r f` feeding
# `python3 - "$f"`, `python3 - "$PLANS_DIR/index.html" "$SOURCE_COUNT"`, and the
# `realpath`/`open` fallback chain. Being locally defined does not help: the
# guard is textual and rejects the command string before any shell sees it.
# Repairing them means extracting the two inline heredoc scripts into scripts/
# with real CLIs, which is its own change.
KNOWN_BROKEN="skills/plans-library/SKILL.md:1
skills/plans-open/SKILL.md:1"

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
#
# 8.3.0 widened the scan from the review surface to every MODEL-FACING markdown
# file in the plugin — skills/, agents/, commands/ — minus the files check 10
# still ledgers. The ledger is now the single exclusion list, so emptying it
# needs no edit here: every file that is not ledgered is guarded, including the
# four 8.3.0 repaired, which are therefore protected against a silent regression
# back into `${CLAUDE_PLUGIN_ROOT}`.
#
# README.md is excluded alongside CHANGELOG.md, and the distinction is the whole
# point of this check rather than a convenience. The invariant is "no
# instruction handed to the model names a command the model cannot run". The
# README documents a `node "$EXTRACTOR" …` snippet that is correct *because* it
# is prefaced "Run from your own shell, with a literal path" — a human's shell
# has no expansion guard, and that snippet sets `$EXTRACTOR` itself. Flagging it
# would be a false positive, and a false positive is the thing most likely to
# make the next author loosen the pattern. Every real defect this check exists
# for — all 15 of 8.1.1's, all four of 8.2.1's ledger — was in a model-facing
# file, never in the README.
EXPANSION_RE='(^|[[:space:]`"'"'"'(])(node|python3?|bash|sh|realpath)[[:space:]].*\$[{(]?[A-Za-z_]'
# `.` is escaped before these paths become an alternation: they are literal
# filenames but are consumed as an ERE, so an unescaped `SKILL.md` would also
# match `SKILL-md` or `SKILLxmd`. Harmless today, but this list's only job is to
# say what is NOT guarded — an exclusion that quietly covers more than it names
# is the same "asserts the description, not the behaviour" failure the rest of
# this suite exists to catch.
# Blank lines are dropped before the join, so every way of writing an empty
# ledger collapses to an empty LEDGERED_RE and trips the guard below. Without
# this, `KNOWN_BROKEN=""` spanning two lines yields a lone `|` — non-empty, so
# the guard would pass it through, and `^(|):` has an empty alternative that
# fails the same way `^():` does.
LEDGERED_RE="$(printf '%s\n' "$KNOWN_BROKEN" | sed '/^[[:space:]]*$/d; s/:[0-9]*$//; s/\./\\./g' | paste -sd'|' -)"
# The exclusion filter is applied only when there is something to exclude, and
# that guard is load-bearing on the exact transition this check is designed to
# survive: emptying the ledger. With an empty LEDGERED_RE the filter becomes
# `grep -vE "^():"` — an empty subexpression, which GNU grep reads as `^:`
# (harmless) but ugrep, the default `grep` on some machines including this one,
# rejects outright with "empty (sub)expression" and exit 2. Chained after `||
# true` that error is swallowed, EXPANSION comes back empty, and check 9 passes
# vacuously no matter how many new call sites exist. Splitting the pipeline so
# the filter is conditional removes both readings.
EXPANSION_RAW="$(grep -rnE "$EXPANSION_RE" \
  "$ROOT/kit/plugins/plan-agent/skills" \
  "$ROOT/kit/plugins/plan-agent/agents" \
  "$ROOT/kit/plugins/plan-agent/commands" \
  --include='*.md' 2>/dev/null \
  | sed "s|$ROOT/kit/plugins/plan-agent/||" || true)"
if [ -n "$LEDGERED_RE" ]; then
  EXPANSION="$(printf '%s\n' "$EXPANSION_RAW" | grep -vE "^($LEDGERED_RE):" || true)"
else
  EXPANSION="$EXPANSION_RAW"
fi
EXPANSION="$(printf '%s' "$EXPANSION" | sed '/^$/d')"
if [ -z "$EXPANSION" ]; then
  pass
else
  echo "$EXPANSION"
  fail "Bash invocation(s) above contain shell expansion — they error with 'Contains expansion' and never run. Ship the script in bin/ and invoke it by bare name, or have the caller Read the file instead."
fi

echo "10. The known unfixed expansion call sites are exactly the documented set..."
ACTUAL_BROKEN="$(grep -rcE "$EXPANSION_RE" "$ROOT/kit/plugins/plan-agent/skills/" \
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

echo "11. Bundled scripts are reachable by bare name via bin/ on PATH..."
# The positive half of check 9. Claude Code adds every enabled plugin's bin/ to
# the Bash tool's PATH, so a bare `plan-agent-render ...` is the ONLY invocation
# shape a skill can actually run: no ${VAR} for the expansion guard to reject,
# and no dependence on CLAUDE_PLUGIN_ROOT, which is a config-file substitution
# (hooks.json, MCP/LSP, monitors) and is not exported into the Bash tool's env.
#
# Invoked BY BARE NAME with bin/ prefixed onto PATH, not by explicit file path.
# Those are different code paths and only the bare-name one is what ships: it
# exercises the PATH lookup, the exec bit (a non-executable file is skipped by
# lookup, giving 127), and — the subtle part — what `$0` is under a PATH-resolved
# `#!` script. Running it as "$BIN_DIR/plan-agent-render" would prove none of
# that.
#
# On `$0`: for a `#!` script the kernel execs the interpreter with the pathname
# that was passed to execve — the absolute path the PATH lookup resolved — as
# the script argument, so `$0` is that absolute path, NOT the bare word typed.
# (argv[0] as typed is what a *builtin* or a `-c` string would see; a shebang
# script never does.) Verified identical under bash, zsh, and sh. This is why
# `dirname "$0"` in the wrapper correctly yields the plugin's bin/ rather than
# `.`, and running the check by bare name is what keeps that true.
#
# exit 2 is build-plan-html.mjs's documented no-args usage code, reachable only
# once the relative hop out of bin/ into scripts/ has landed. The prototypes
# wrapper shares that hop but rebuilds a gallery as a side effect, so it is
# proven reachable via `command -v` under the same PATH, plus exec bit, clean
# syntax, and an existing target.
#
# plan-agent-plans-index is proven the same way as the prototypes wrapper: both
# rebuild a gallery as a side effect, so neither can be run for a return code.
BIN_DIR="$ROOT/kit/plugins/plan-agent/bin"
RENDER_RC=0
PATH="$BIN_DIR:$PATH" plan-agent-render >/dev/null 2>&1 || RENDER_RC=$?
PROTO_RESOLVED="$(PATH="$BIN_DIR:$PATH" command -v plan-agent-prototypes-index || true)"
PLANS_RESOLVED="$(PATH="$BIN_DIR:$PATH" command -v plan-agent-plans-index || true)"
if [ "$RENDER_RC" -eq 2 ] \
  && [ "$PROTO_RESOLVED" = "$BIN_DIR/plan-agent-prototypes-index" ] \
  && bash -n "$BIN_DIR/plan-agent-prototypes-index" 2>/dev/null \
  && [ -f "$ROOT/kit/plugins/plan-agent/hooks/build-prototypes-index.sh" ] \
  && [ "$PLANS_RESOLVED" = "$BIN_DIR/plan-agent-plans-index" ] \
  && bash -n "$BIN_DIR/plan-agent-plans-index" 2>/dev/null \
  && [ -f "$ROOT/kit/plugins/plan-agent/hooks/build-index.sh" ]; then
  pass
else
  fail "bin/ wrappers are not reachable by bare name on PATH, or cannot reach their target (plan-agent-render rc=$RENDER_RC, want 2; prototypes resolved to '${PROTO_RESOLVED:-nothing}'; plans resolved to '${PLANS_RESOLVED:-nothing}')"
fi

echo "11b. plans-library invokes its bin/ wrapper in command position..."
# The positive half of the plans-library repair, and the one that would have
# caught PR #524: that branch replaced the skill's hand-rolled scan with a
# single delegated command spelled through a plugin-root expansion, so the
# rewritten skill's only action could never run. Anchored to command position —
# prose naming the wrapper opens with a backtick, which is not whitespace, so it
# cannot satisfy this the way a bare `grep -F` would.
if grep -qE '^[[:space:]]*plan-agent-plans-index([[:space:]]|$)' \
     "$ROOT/kit/plugins/plan-agent/skills/plans-library/SKILL.md" 2>/dev/null; then
  pass
else
  fail "plans-library/SKILL.md no longer invokes plan-agent-plans-index in command position — the delegation was removed, renamed, or respelled as a path"
fi

echo "12. bin/ survives the dist build..."
# A wrapper that is not copied into dist/ is a wrapper installed users never
# get — the same shape of defect as 8.1.1, where the extractor shipped its
# library but not itself. build-dist.mjs copies only KEEP-listed top-level
# entries, so bin/ must be on that allowlist.
# `[[:space:]]`, not `\s`: the latter is a GNU extension, honoured by GNU and
# Apple grep but not guaranteed in POSIX ERE, so it would degrade to a literal
# `s` on a stricter grep (busybox) and silently stop matching. Every other
# pattern in this file is POSIX already.
if grep -qE "^[[:space:]]*'bin',[[:space:]]*$" "$ROOT/scripts/build-dist.mjs"; then
  pass
else
  fail "scripts/build-dist.mjs KEEP allowlist is missing 'bin' — the wrappers would be dropped from dist/"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All extractor-wiring checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
