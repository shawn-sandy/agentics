#!/usr/bin/env bash
set -euo pipefail

# Structure and copy-parity test for the verified-change skill.
#
# The skill ships as three copies of the same bytes, on purpose:
#
#   kit/plugins/code-testing-agent/skills/verified-change/  — the source of truth
#   .claude/skills/verified-change/                         — the project-local copy
#   scripts/verify.sh                                       — agentics' dogfood gate
#
# The duplication is not an accident to be cleaned up. Worktrees pin an older
# plugin version and Desktop loads frozen claude.ai snapshots, so a plugin-only
# skill is invisible in exactly the environments that need it, and a gate that
# lives only under the plugin root cannot be run by a documented Bash command
# (see tests/plugins/test-no-shell-expansion.sh for why ${...} paths are dead).
#
# What this test buys is that the duplication stays a duplicate. Without the
# parity checks the three copies silently fork, and the fork is invisible until
# someone runs the stale one. The frontmatter checks are a fast local signal
# only — tests/plugins/test-description-budget.sh already sweeps every shipped
# SKILL.md — so do not read them as this file's reason to exist.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN_SKILL="$ROOT/kit/plugins/code-testing-agent/skills/verified-change"
LOCAL_SKILL="$ROOT/.claude/skills/verified-change"
PLUGIN_GATE="$PLUGIN_SKILL/assets/verify.sh"
REPO_GATE="$ROOT/scripts/verify.sh"
INSTALLER="$ROOT/kit/plugins/code-testing-agent/bin/install-verify-gate"
CLAUDE_MD="$ROOT/CLAUDE.md"
GUARD_TEST="$ROOT/tests/plugins/test-exitplanmode-guard.sh"
GUARD='**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.'
FAILURES=0

pass() { echo "  PASS${1:+ — $1}"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== verified-change skill structure and copy parity ==="

# --- Check 1: every file the skill is made of exists ------------------------
# Reported as one list rather than as a cascade of shell errors: a missing file
# should name itself, not surface as `diff: No such file or directory`.
echo
echo "-- Check 1: all files present --"
MISSING=""
for f in \
  "$PLUGIN_SKILL/SKILL.md" \
  "$PLUGIN_SKILL/references/mutation-check.md" \
  "$PLUGIN_SKILL/references/verification-section.md" \
  "$PLUGIN_GATE" \
  "$LOCAL_SKILL/SKILL.md" \
  "$REPO_GATE" \
  "$INSTALLER" \
  "$CLAUDE_MD"; do
  [ -f "$f" ] || MISSING="$MISSING\n    ${f#"$ROOT/"}"
done
if [ -z "$MISSING" ]; then
  pass
else
  printf "%b\n" "$MISSING"
  fail "the file(s) above do not exist"
fi

# Everything below reads these files. Stop here rather than reporting a dozen
# derived failures that all have the same one cause.
if [ -n "$MISSING" ]; then
  echo
  echo "=== FAILED ($FAILURES check(s)) ==="
  exit 1
fi

# --- Check 2: frontmatter ---------------------------------------------------
echo
echo "-- Check 2: frontmatter name and description budget --"
if grep -qE '^name: verified-change$' "$PLUGIN_SKILL/SKILL.md"; then
  pass "name: verified-change"
else
  fail "SKILL.md frontmatter has no 'name: verified-change' line"
fi

# Measured in Python so the count does not move with the ambient locale, the
# same reason tests/plugins/test-progressive-disclosure.sh avoids wc.
BUDGET_REPORT="$(python3 - "$PLUGIN_SKILL/SKILL.md" <<'PY'
import re, sys

text = open(sys.argv[1], encoding="utf-8").read()
m = re.search(r'^description:\s*(.+?)\s*$', text, re.M)
if not m:
    print("MISSING")
    raise SystemExit
desc = m.group(1).strip()
if len(desc) >= 2 and desc[0] == desc[-1] and desc[0] in "\"'":
    desc = desc[1:-1]
first = re.split(r'(?<=\.)\s', desc, maxsplit=1)[0]
print(f"{len(desc)} {len(first)}")
PY
)"
if [ "$BUDGET_REPORT" = "MISSING" ]; then
  fail "SKILL.md frontmatter has no description"
else
  TOTAL="${BUDGET_REPORT%% *}"
  FIRST="${BUDGET_REPORT##* }"
  if [ "$TOTAL" -le 200 ] && [ "$FIRST" -le 80 ]; then
    pass "$TOTAL chars total, $FIRST-char first sentence"
  else
    fail "description is $TOTAL chars (budget 200) with a $FIRST-char first sentence (budget 80)"
  fi
fi

# --- Check 3: the plan-mode guard, verbatim ---------------------------------
echo
echo "-- Check 3: plan-mode guard present verbatim --"
if grep -qF "$GUARD" "$PLUGIN_SKILL/SKILL.md"; then
  pass
else
  echo "    expected verbatim: $GUARD"
  fail "SKILL.md mutates the working tree but carries no plan-mode guard"
fi

# The repo-wide retention check owns this invariant for every other mutating
# skill. Registering here too is what makes a future guard-stripping edit fail
# in the shared test rather than only in this one.
echo
echo "-- Check 4: registered in the repo-wide guard manifest --"
if grep -qE '^[[:space:]]*code-testing-agent/skills/verified-change/SKILL\.md$' "$GUARD_TEST"; then
  pass
else
  fail "verified-change is not in the WRITE_HEAVY manifest of tests/plugins/test-exitplanmode-guard.sh"
fi

# --- Check 5: the project-local copy is byte-identical -----------------------
echo
echo "-- Check 5: project-local copy matches the plugin, references included --"
# `diff -r`, not `cmp` on SKILL.md alone: copying SKILL.md by itself leaves its
# relative references/ links dangling in precisely the worktree and Desktop
# environments the copy exists to serve.
DIFF_OUT="$(diff -r "$PLUGIN_SKILL" "$LOCAL_SKILL" 2>&1 || true)"
if [ -z "$DIFF_OUT" ]; then
  pass
else
  printf '%s\n' "$DIFF_OUT" | sed 's/^/    /'
  fail ".claude/skills/verified-change has diverged from the plugin copy"
fi

# Positive assertion, because check 5 is satisfied by two identical *empty*
# trees. Every references/<name>.md the local SKILL.md names must resolve
# beside it.
DANGLING=""
while IFS= read -r ref; do
  [ -n "$ref" ] || continue
  [ -f "$LOCAL_SKILL/$ref" ] || DANGLING="$DANGLING\n    $ref"
done <<EOF
$(grep -oE 'references/[A-Za-z0-9._-]+\.md' "$LOCAL_SKILL/SKILL.md" | sort -u)
EOF
if [ -z "$DANGLING" ]; then
  pass "every references/ link in the local copy resolves"
else
  printf "%b\n" "$DANGLING"
  fail "the project-local SKILL.md names reference file(s) that are not beside it"
fi

# --- Check 6: the dogfood gate is byte-identical to the template -------------
echo
echo "-- Check 6: scripts/verify.sh matches the plugin's assets/verify.sh --"
if cmp -s "$PLUGIN_GATE" "$REPO_GATE"; then
  pass
else
  # `|| true` is load-bearing: diff exits 1 when the files differ, and under
  # `set -e` with pipefail that killed the script here — the check failed with
  # no message at all, which is the one thing a parity check must not do.
  diff "$PLUGIN_GATE" "$REPO_GATE" | head -20 | sed 's/^/    /' || true
  fail "scripts/verify.sh and the plugin template have forked — every gate change is a two-file edit"
fi

if [ -x "$INSTALLER" ]; then
  pass "bin/install-verify-gate is executable"
else
  fail "kit/plugins/code-testing-agent/bin/install-verify-gate is not executable"
fi

# --- Check 7: the merge-gate rule is binding in CLAUDE.md --------------------
echo
echo "-- Check 7: CLAUDE.md carries the merge-gate rule --"
# Three independent things, so the check cannot be satisfied by a sentence that
# merely mentions the script: the gate must be named, it must be tied to a
# green run, and the VERIFICATION handoff must be named.
RULE_MISSING=""
grep -qF 'scripts/verify.sh' "$CLAUDE_MD" || RULE_MISSING="$RULE_MISSING\n    names scripts/verify.sh"
grep -qiE 'green|exits 0' "$CLAUDE_MD" || RULE_MISSING="$RULE_MISSING\n    requires the gate to be green"
grep -qF 'VERIFICATION' "$CLAUDE_MD" || RULE_MISSING="$RULE_MISSING\n    names the VERIFICATION section"
if [ -z "$RULE_MISSING" ]; then
  pass
else
  printf "%b\n" "$RULE_MISSING"
  fail "the CLAUDE.md merge-gate rule is missing the element(s) above"
fi

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "=== FAILED ($FAILURES check(s)) ==="
  exit 1
fi
echo "=== PASSED ==="
