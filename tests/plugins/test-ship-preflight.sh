#!/usr/bin/env bash
set -euo pipefail

# Objective test for docs/plans/harden-ship-preflight.md.
#
# Four files carry one contract between them and drift independently:
#
#   ship-autonomous/references/preflight-and-verify.md  the guards + browser probe
#   ship/references/preflight-guards.md                 ship's own copy of the guards
#   ship/SKILL.md                                       ship's core statement of them
#   pr-agent/SKILL.md                                   where the marker reaches a reviewer
#   ship-autonomous/references/ci-autofix.md            the CI classification table
#
# The pr-agent assertion is the one that matters most: without it the browser
# marker requirement passes its own test while never reaching a PR body, which
# is exactly the gap an earlier draft of the plan shipped with.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GA="$ROOT/kit/plugins/git-agent"
SA_PREFLIGHT="$GA/skills/ship-autonomous/references/preflight-and-verify.md"
SHIP_PREFLIGHT="$GA/skills/ship/references/preflight-guards.md"
SHIP_CORE="$GA/skills/ship/SKILL.md"
PR_AGENT="$GA/skills/pr-agent/SKILL.md"
CI_AUTOFIX="$GA/skills/ship-autonomous/references/ci-autofix.md"

FAILURES=0

pass() { echo "  PASS: $1"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

# has <file> <fixed-string> <label>
has() {
  if grep -qF -- "$2" "$1" 2>/dev/null; then pass "$3"
  else fail "$3 — $(basename "$(dirname "$1")")/$(basename "$1") is missing: $2"; fi
}

# lacks <file> <fixed-string> <label>
lacks() {
  if grep -qF -- "$2" "$1" 2>/dev/null; then
    fail "$3 — $(basename "$(dirname "$1")")/$(basename "$1") still contains: $2"
  else pass "$3"; fi
}

echo "=== ship pre-flight hardening (objective test) ==="

echo "0. Every file under test exists..."
for f in "$SA_PREFLIGHT" "$SHIP_PREFLIGHT" "$SHIP_CORE" "$PR_AGENT" "$CI_AUTOFIX"; do
  if [ -f "$f" ]; then pass "${f#"$ROOT"/}"
  else fail "missing ${f#"$ROOT"/}"; fi
done
# Nothing below can be trusted if a file vanished — a grep against a missing
# file fails every assertion for the wrong reason.
[ "$FAILURES" -eq 0 ] || { echo; echo "$FAILURES check(s) failed."; exit 1; }

# ---------------------------------------------------------------------------
# 1. Both pre-flight surfaces describe ONE combined report.
# ---------------------------------------------------------------------------
echo "1. Both pre-flight surfaces run every guard, then report once..."
for f in "$SA_PREFLIGHT" "$SHIP_PREFLIGHT"; do
  has "$f" "Run every guard before reporting any of them" "run-all contract stated"
  has "$f" "Never stop on the first failure" "first-failure semantics explicitly rejected"
  has "$f" "BLOCKED" "the report uses a BLOCKED status"
  has "$f" "Remediation" "each row carries a remediation command"
done
# ship's core has to say it too — a contract that only lives behind a reference
# link is a contract the model may never load.
has "$SHIP_CORE" "Run every guard before reporting any of them" "ship core states the contract"
has "$SHIP_CORE" "Never stop on the first failure" "ship core rejects first-failure semantics"
# The exact sentence this change removes. Its return is the regression.
lacks "$SHIP_CORE" "Stop on the first failure" "ship core no longer stops on the first failure"

# ---------------------------------------------------------------------------
# 2. The worktree env-parity check, gated on --git-common-dir, never copying.
# ---------------------------------------------------------------------------
echo "2. Both surfaces carry the env-parity check, gated and non-copying..."
for f in "$SA_PREFLIGHT" "$SHIP_PREFLIGHT"; do
  has "$f" "--git-common-dir" "gated on the linked-worktree probe"
  has "$f" "Omit the row entirely" "the row is absent outside a linked worktree"
  has "$f" "cp <main-checkout-path>/.env" "the remediation quotes a cp command"
  has "$f" "Never run it" "the cp is never executed"
done
has "$SHIP_CORE" "Worktree env parity" "ship core names the env-parity guard"
has "$SHIP_CORE" "Never copy" "ship core forbids copying the env file"

# No automatic remediation anywhere on the pre-flight path. `git stash` in
# particular is offered to the *user* as a plan-files option and must never
# become something the skill runs on its own.
echo "3. Nothing on the pre-flight path remediates automatically..."
for f in "$SA_PREFLIGHT" "$SHIP_PREFLIGHT"; do
  has "$f" "Never remediate automatically" "automatic remediation forbidden"
done

# ---------------------------------------------------------------------------
# 4. The browser probe and its honest marker.
# ---------------------------------------------------------------------------
echo "4. The browser probe names UNVERIFIED — no browser..."
has "$SA_PREFLIGHT" "UNVERIFIED — no browser" "the marker string is present"
has "$SA_PREFLIGHT" "preview_start" "the probe names the tool it checks for"
has "$SA_PREFLIGHT" "Probe availability before the preview block" "Step 2.5 probes before previewing"

# ---------------------------------------------------------------------------
# 5. pr-agent carries the marker through to the PR body. Without this the
#    marker is produced and then dropped before any reviewer sees it.
# ---------------------------------------------------------------------------
echo "5. pr-agent's body template carries the marker to the PR..."
has "$PR_AGENT" "UNVERIFIED — no browser" "pr-agent names the marker"
has "$PR_AGENT" "Verification marker" "pr-agent's template has a marker rule"
has "$PR_AGENT" "verbatim" "the marker is reproduced verbatim"
has "$PR_AGENT" "never invent a marker" "no marker reported leaves the template unchanged"
# The rule has to sit in the Test Plan section of Step 5, not in some unrelated
# step — that section is what `gh pr create` writes into the body.
if python3 - "$PR_AGENT" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
step5 = text.split("## Step 5: Create Pull Request", 1)
if len(step5) != 2:
    print("  no Step 5 section found"); sys.exit(1)
sys.exit(0 if "UNVERIFIED — no browser" in step5[1] and "Test Plan" in step5[1] else 1)
PY
then pass "the marker rule lives inside Step 5's Test Plan"
else fail "the marker rule is not in Step 5's Test Plan section"; fi

# ---------------------------------------------------------------------------
# 6. Every AskUserQuestion on the pre-flight path names a headless default.
# ---------------------------------------------------------------------------
echo "6. Every pre-flight AskUserQuestion names a headless default..."
if python3 - "$SA_PREFLIGHT" "$SHIP_PREFLIGHT" <<'PY'
import sys

bad = []
for path in sys.argv[1:]:
    text = open(path, encoding="utf-8").read()
    # Only Step 1 raises pre-flight questions; Step 2.5 onward is out of scope.
    step1 = text.split("## Step 1", 1)[-1].split("## Step 2", 1)[0]
    # "Use AskUserQuestion" is a gate being RAISED. A bare mention of the tool
    # name is not — the surface that raises no question still has to say so,
    # which the second check below covers, but it has nothing to default.
    raised = step1.count("Use AskUserQuestion")
    named = step1.count("Headless default:")
    if raised and named < raised:
        bad.append(
            f"{path}: {raised} gate(s) raised, {named} named headless default(s)")
    # Every surface states a headless rule either way, so a reader in `claude -p`
    # is never left to improvise.
    if "Headless" not in step1:
        bad.append(f"{path}: no headless rule stated at all")
for b in bad:
    print(" ", b)
sys.exit(1 if bad else 0)
PY
then pass "each questioning gate has a named headless fallback"
else fail "a pre-flight AskUserQuestion has no headless default"; fi
# The plan-files gate's default is specifically `abort` — `include` or `stash`
# would touch the user's files at the one gate that exists to avoid that.
has "$SA_PREFLIGHT" "Headless default: \`abort\`" "the plan-files gate defaults to abort"

# ---------------------------------------------------------------------------
# 7. CI triage classifies infrastructure failures as non-defects.
# ---------------------------------------------------------------------------
echo "7. ci-autofix lists external-blocker ahead of lint..."
if python3 - "$CI_AUTOFIX" <<'PY'
import sys
rows = [ln for ln in open(sys.argv[1], encoding="utf-8")
        if ln.startswith("| `") ]
if not rows:
    print("  no classification rows found"); sys.exit(1)
first = rows[0]
if "external-blocker" not in first:
    print("  first data row is not external-blocker:", first.strip()[:80]); sys.exit(1)
# Ordering is the point: it must be classified before the autofixable classes,
# or a billing block matching nothing still falls through to a code fix.
names = [r.split("`")[1] for r in rows]
if names.index("external-blocker") > names.index("lint"):
    print("  external-blocker is listed after lint:", names); sys.exit(1)
sys.exit(0)
PY
then pass "external-blocker is the first classification row"
else fail "external-blocker is missing or ordered below lint"; fi

has "$CI_AUTOFIX" "gh run view <run-id> --json jobs" "the empty-log probe command is documented"
has "$CI_AUTOFIX" "does not advance the three-attempt cap" "the attempt cap does not advance"
has "$CI_AUTOFIX" "billing" "billing blocks are classified"
has "$CI_AUTOFIX" "Bad credentials" "expired credentials are classified"
has "$CI_AUTOFIX" "quota" "quota blocks are classified"
has "$CI_AUTOFIX" "returns no output" "all-failed-with-empty-logs is the condition"

echo
if [ "$FAILURES" -eq 0 ]; then echo "All checks passed."; exit 0
else echo "$FAILURES check(s) failed."; exit 1; fi
