#!/usr/bin/env bash
set -euo pipefail

# Objective test: finalize-plan reconciles the plan against what SHIPPED.
#
# Before this, finalize-plan only ever asked one direction of the question:
# "was each planned thing built?" It scored tokens, verified criteria, ran the
# objective test, and reported shortfalls. Nothing ever asked the other
# direction — "what got built that the plan never mentions?" — so a plan whose
# implementation grew a new file, a new flag, or a different approach was
# marked completed while its published artifact still described only the
# original scope. The spec, and therefore the shared claude.ai page, silently
# under-reported the work.
#
# Reconcile closes that by sorting the shipped commits into four buckets and
# routing each to a section the renderer ALREADY handles:
#
#   planned + shipped        -> [x] ticks            (5b/5c, pre-existing)
#   planned, not shipped     -> ## Completion Report (5d, pre-existing)
#   shipped, never planned   -> a [x] step           (5c2, new)
#   built differently        -> ## Decisions         (5d2, new)
#
# Deliberately NOT asserted: a new `## What Shipped` section. Adding one would
# need parse + render + digest round-trip + extractSections + CSS, and the
# Completion Report's red-dot styling makes it the wrong home for work that
# shipped fine. The four buckets above need no renderer change at all.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLAN_AGENT="$ROOT/kit/plugins/plan-agent"
SKILL="$PLAN_AGENT/skills/finalize-plan/SKILL.md"
EVIDENCE="$PLAN_AGENT/skills/finalize-plan/references/evidence-analysis.md"
WRITE_COMPLETIONS="$PLAN_AGENT/skills/finalize-plan/references/write-completions.md"
README="$PLAN_AGENT/README.md"

FAILURES=0
pass() { echo "  PASS${1:+ — $1}"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== finalize-plan reconciles plan against shipped work (objective test) ==="

# ---------------------------------------------------------------------------
# 1. The core names Step 3d.
#
# A reference step the core never names is a step the model never reaches:
# evidence-analysis.md is only fetched because SKILL.md points at it, and the
# model follows the steps the core enumerates. An unnamed 3d is dead prose.
# ---------------------------------------------------------------------------
echo "1. finalize-plan core names Step 3d..."
if grep -qF 'Step 3d' "$SKILL"; then
  pass
else
  fail "SKILL.md never names Step 3d — nothing routes the model to the reconcile"
fi

# ---------------------------------------------------------------------------
# 2. Step 3d exists in the reference and derives the commit range from git.
#
# The user picked merged commits + diff over PR metadata and codebase-only
# scoring, so the range has to come from git log, not gh.
# ---------------------------------------------------------------------------
echo "2. evidence-analysis has a 3d that reads the shipped commits..."
if grep -qF '### 3d' "$EVIDENCE" && grep -qF 'git log' "$EVIDENCE"; then
  pass
else
  fail "evidence-analysis.md has no 3d / no git log — there is no shipped-work signal"
fi

# The primary range is the commits that touched the SPEC itself: this repo
# commits the plan file alongside the change it describes, which makes the
# spec's own history the precise commit set for that plan. Without it the only
# range available is a date window over the whole repo, which is noise.
echo "2a. ...uses the spec's own commit history as the primary range..."
if grep -qF 'git log --oneline --follow' "$EVIDENCE"; then
  pass
else
  fail "evidence-analysis.md 3d does not follow the spec's history — range falls back to a noisy date window"
fi

# A plan finalized on its own unmerged branch has NO spec history yet (the
# commit lands with the finalize). Without a fallback, 3d silently reports
# "nothing shipped" on exactly the branch where everything just shipped.
echo "2b. ...falls back to the default-branch range when the spec has no history..."
if grep -qF '...HEAD' "$EVIDENCE"; then
  pass
else
  fail "evidence-analysis.md 3d has no <default>...HEAD fallback — an unmerged branch reports nothing shipped"
fi

# Three buckets have to be distinguished by name, or the model collapses them
# into one undifferentiated "notes" list that no write rule can route.
echo "2c. ...names the unplanned and changed-approach buckets..."
if grep -qF 'shipped but unplanned' "$EVIDENCE" \
   && grep -qF 'built differently' "$EVIDENCE"; then
  pass
else
  fail "evidence-analysis.md 3d does not name both new buckets — 5c2/5d2 have no input to route"
fi

# ---------------------------------------------------------------------------
# 3. Unplanned shipped work is written as a step.
#
# The step list is what a viewer reads as "what was built". Recording unplanned
# work only in prose leaves the rendered step list under-reporting the work.
# ---------------------------------------------------------------------------
echo "3. write-completions writes unplanned shipped work into ## Steps..."
if grep -qF '5c2' "$WRITE_COMPLETIONS" && grep -qF 'Unplanned:' "$WRITE_COMPLETIONS"; then
  pass
else
  fail "write-completions.md has no 5c2 / no Unplanned: marker — shipped-but-unplanned work is never recorded"
fi

# A phased spec is the trap: appending a done step to the END of the list drops
# it inside whichever phase happens to be last, which is routinely a phase that
# was never started. That makes an unstarted phase look partly done and, worse,
# muddies the 5a0 phase gate that decides completable-vs-checkpointed. A
# trailing phase of its own is all-[x], so the gate ignores it.
echo "3a. ...and puts them in their own trailing phase when the spec is phased..."
if grep -qF '### Phase: Unplanned' "$WRITE_COMPLETIONS"; then
  pass
else
  fail "write-completions.md 5c2 has no trailing-phase rule — an unplanned step lands inside an unstarted phase"
fi

# ---------------------------------------------------------------------------
# 4. A changed approach is written to ## Decisions.
#
# Decisions is already defined as the settled-choices ledger a resumed session
# reads so it does not re-litigate. "We built it this other way" is exactly
# that. The Completion Report is the wrong home: every entry there renders with
# a red dot, which reads as a defect.
# ---------------------------------------------------------------------------
echo "4. write-completions routes a changed approach to ## Decisions..."
if grep -qF '5d2' "$WRITE_COMPLETIONS" && grep -qF '## Decisions' "$WRITE_COMPLETIONS"; then
  pass
else
  fail "write-completions.md has no 5d2 — a changed approach is recorded nowhere"
fi

# The red-dot reasoning is load-bearing and non-obvious; the next editor will
# otherwise "tidy" these entries into the Completion Report. Pin the rationale.
echo "4a. ...and says why reconcile notes do NOT go in the Completion Report..."
if grep -qiF 'red dot' "$WRITE_COMPLETIONS"; then
  pass
else
  fail "write-completions.md does not explain why reconcile notes stay out of the Completion Report"
fi

# ---------------------------------------------------------------------------
# 5. 5d's delete rule cannot swallow the reconcile findings.
#
# 5d says: if every criterion verified and the objective test passed, REMOVE
# the Completion Report and add nothing. That is the exact state a clean
# plan-plus-extra-scope run lands in — so unless 5d is scoped to itself, the
# happy path is precisely where reconcile output would be discarded.
# ---------------------------------------------------------------------------
echo "5. the 5d removal rule is scoped so it cannot discard 5c2/5d2 writes..."
if grep -qF 'never removes the 5c2 or 5d2 writes' "$WRITE_COMPLETIONS"; then
  pass
else
  fail "write-completions.md 5d removal is unscoped — a fully-verified plan discards its reconcile findings"
fi

# ---------------------------------------------------------------------------
# 6. Documented for users.
# ---------------------------------------------------------------------------
echo "6. README documents the shipped-work reconcile..."
if grep -qF 'Reconciles the plan against what shipped' "$README"; then
  pass
else
  fail "plan-agent README does not document the reconcile step"
fi

# Version parity with the CHANGELOG is deliberately NOT asserted here:
# tests/plugins/test-finalize-all-flag.sh check 7 already makes that assertion
# for this same plugin, and duplicating it fails twice for one drift.

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks passed."
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
