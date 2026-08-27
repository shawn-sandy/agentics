#!/usr/bin/env bash
set -euo pipefail

# Objective test: completion state reaches an ARTIFACT-published plan.
#
# An artifact plan is a spec with an `artifact-url:` and NO sibling <stem>.html
# — its rendered view lives on claude.ai, not on disk. That absent sibling is
# the file-published signal every part of the pipeline keys off, and it is
# exactly what used to make these plans fall through:
#
#   * render-plan-html.py skips them by design (no sibling to re-render), so a
#     spec write alone leaves the shared page showing the old status forever.
#   * plan-status wrote frontmatter and stopped — nothing republished.
#   * finalize-plan --all discovered candidates with `grep ... *.html`, so a
#     plan with no HTML was never even a candidate.
#
# The failure is silent and public: the spec says completed, the page everyone
# else reads says todo. These asserts pin the republish path in each skill that
# writes completion state, so it cannot be dropped again.
#
# Deliberately NOT asserted: that `build` republishes. It already routes
# through its own re-render subroutine, pinned elsewhere, and its core sits one
# word under the progressive-disclosure ceiling.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLAN_AGENT="$ROOT/kit/plugins/plan-agent"
STATUS_SKILL="$PLAN_AGENT/skills/plan-status/SKILL.md"
STATUS_SINGLE="$PLAN_AGENT/skills/plan-status/references/single-file-flow.md"
STATUS_BULK="$PLAN_AGENT/skills/plan-status/references/bulk-mode.md"
SWEEP="$PLAN_AGENT/skills/finalize-plan/references/sweep-mode.md"
WRITE_COMPLETIONS="$PLAN_AGENT/skills/finalize-plan/references/write-completions.md"
README="$PLAN_AGENT/README.md"

FAILURES=0
pass() { echo "  PASS${1:+ — $1}"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== artifact-plan completion reaches the artifact (objective test) ==="

# ---------------------------------------------------------------------------
# 1. plan-status can actually call Artifact.
#
# A skill that omits a tool from allowed-tools prompts mid-run, which in a
# headless or sweep context means the republish silently never happens.
# ---------------------------------------------------------------------------
echo "1. plan-status lists Artifact in allowed-tools..."
if grep -qE '^allowed-tools:.*\bArtifact\b' "$STATUS_SKILL"; then
  pass
else
  fail "plan-status allowed-tools has no Artifact — the republish would prompt or fail"
fi

# ---------------------------------------------------------------------------
# 2. The core names the step, so the model reaches the reference at all.
#
# A reference the core never names is a file the model never fetches; the
# progressive-disclosure test enforces the link, this one enforces the intent.
# ---------------------------------------------------------------------------
echo "2. plan-status core names a republish step for artifact plans..."
if grep -qF 'Step 8' "$STATUS_SKILL" \
   && grep -qF 'artifact-url:' "$STATUS_SKILL"; then
  pass
else
  fail "plan-status SKILL.md does not name Step 8 / artifact-url — nothing routes to the republish"
fi

# ---------------------------------------------------------------------------
# 3. The single-file flow spells out the republish, and forbids the sibling.
#
# Writing <stem>.html here is the tempting wrong fix: it makes the render
# "work" while flipping the plan's gallery card off the artifact and onto a
# local path, resurrecting the file the author chose not to publish.
# ---------------------------------------------------------------------------
echo "3. single-file-flow Step 8 renders to scratchpad and refuses the sibling..."
if grep -qF '### Step 8' "$STATUS_SINGLE" \
   && grep -qF 'plan-agent-render' "$STATUS_SINGLE" \
   && grep -qF '$SCRATCHPAD' "$STATUS_SINGLE" \
   && grep -qF 'Never write `<stem>.html`' "$STATUS_SINGLE"; then
  pass
else
  fail "single-file-flow.md is missing the Step 8 heading, the scratchpad render, or the never-write-sibling rule"
fi

# ---------------------------------------------------------------------------
# 4. Bulk mode republishes too.
#
# Its prepend path is a Bash subprocess write, which fires no PostToolUse hook
# at all — so a bulk run without this pass leaves every shared page stale.
# ---------------------------------------------------------------------------
echo "4. bulk mode runs the republish pass after writing..."
if grep -qF 'Republish artifact-published plans' "$STATUS_BULK" \
   && grep -qF 'artifact-url:' "$STATUS_BULK"; then
  pass
else
  fail "bulk-mode.md has no post-write republish pass — bulk runs would leave artifact pages stale"
fi

# ---------------------------------------------------------------------------
# 5. The --all sweep can SEE an artifact plan.
#
# The HTML scan cannot: these plans have no HTML. Without a spec-side scan the
# sweep skips precisely the plans whose staleness is publicly visible.
# ---------------------------------------------------------------------------
echo "5. finalize-plan sweep discovers artifact plans by spec, not by HTML..."
if grep -qF 'artifact_candidates' "$SWEEP" \
   && grep -qF '${spec%.md}.html' "$SWEEP" \
   && grep -qF '^artifact-url: *https?://' "$SWEEP"; then
  pass
else
  fail "sweep-mode.md S1 has no spec-side artifact discovery — --all cannot reach an artifact plan"
fi

# A bare `https://` with nothing after it matched the first version of this
# regex. Passing that to Artifact claims a NEW url instead of updating the
# shared one, stranding the link people already have — so the scan must
# require a host, the same gate implementation-plan 7b and publish-hub apply.
echo "5a. ...and requires a host, so a truncated 'https://' is not republished..."
if grep -qF '^artifact-url: *https?://[^/ ]' "$SWEEP"; then
  pass
else
  fail "sweep-mode.md accepts a hostless artifact-url — a bare 'https://' reaches the republish"
fi

# The three guards below are each a bug the scan had, so each is pinned
# separately — a single "does the scan exist" check passed while two of them
# were absent.

# The loop's exit status is its last command, so a directory whose final spec
# does not match returns non-zero and aborts the sweep under `set -e` —
# silently, and exactly when there is nothing to sweep. Verified against
# fixtures both ways; the unguarded form exits 1 before printing anything.
# -x pins the whole line, so this matches the code line and not the prose
# bullet below the snippet that also quotes `done || true` — the loose form
# stayed green with the guard deleted.
echo "5b. ...guards the loop's exit status so an empty result is non-fatal..."
if grep -qxF '  done || true' "$SWEEP"; then
  pass
else
  fail "sweep-mode.md artifact scan has no 'done || true' — a no-match sweep aborts under set -e"
fi

# Matching over the whole file makes a COMPLETED plan whose body documents
# plan-agent's own keys (a bare `status: todo` line in ## Steps) a candidate.
# In this repo, where plans are about plan-agent, that is a live case — it was
# reproduced against a fixture. The match must be bounded to the frontmatter.
echo "5c. ...matches status/artifact-url inside the frontmatter only..."
if grep -qF "awk 'NR==1" "$SWEEP" && grep -qF 'frontmatter' "$SWEEP"; then
  pass
else
  fail "sweep-mode.md scans the whole spec — a body line reading 'status: todo' false-matches a completed plan"
fi

# A non-spec .md carrying both keys would enter the candidate list, and S4
# resolves edit mode via Step 1, which is told to STOP on a .md with no
# '# Plan:' heading — halting the sweep partway through the selected plans.
# Match the CODE line, not the prose bullet that also names this guard —
# grepping the bare `grep -q '^# Plan:'` passed with the guard deleted, because
# the explanation below the snippet still mentioned it.
echo "5d. ...admits only '# Plan:' specs, so S4 cannot hit Step 1's STOP..."
if grep -qF "grep -q '^# Plan:' \"\$spec\" || continue" "$SWEEP"; then
  pass
else
  fail "sweep-mode.md artifact scan has no '# Plan:' gate — a non-spec .md candidate halts the sweep in S4"
fi

# S1 builds two lists but everything downstream says "each candidate". Without
# an explicit combine the artifact list is discovered and then silently dropped.
echo "5e. ...combines both lists into the name S2-S4 actually iterate..."
if grep -qF 'candidates=$(printf' "$SWEEP"; then
  pass
else
  fail "sweep-mode.md never combines artifact_candidates into candidates — S2-S4 would iterate the HTML list alone"
fi

# S5 reports failed republishes; something has to record them first.
echo "5f. ...records each republish outcome that S5 reports..."
if grep -qF 'Record each artifact plan' "$SWEEP"; then
  pass
else
  fail "sweep-mode.md S5 reports republish failures that no step captures"
fi

# ---------------------------------------------------------------------------
# 6. Delivery does not promise a file that does not exist.
#
# Both delivery steps used to hand back "<stem>.html"; for an artifact plan
# that path is either absent or a scratchpad temp that dies with the session.
# ---------------------------------------------------------------------------
echo "6. Both delivery steps report the artifact URL instead of a missing .html..."
if grep -qF 'artifact URL' "$WRITE_COMPLETIONS" && grep -qF 'artifact URL' "$SWEEP"; then
  pass
else
  fail "delivery still promises an .html for artifact plans (write-completions.md and/or sweep-mode.md)"
fi

# ---------------------------------------------------------------------------
# 7. Documented, and versioned in step with the marketplace.
# ---------------------------------------------------------------------------
echo "7. README documents the artifact republish..."
if grep -qF 'Artifact-published plans stay current' "$README" \
   && grep -qF 'republishes to the recorded' "$README"; then
  pass
else
  fail "plan-agent README does not document the artifact republish behaviour"
fi

# CHANGELOG-versus-marketplace version parity is deliberately NOT asserted here:
# tests/plugins/test-finalize-all-flag.sh check 7 already makes exactly that
# assertion for this same plugin. Duplicating it means editing two files when
# the version scheme changes, and a drift fails twice without saying which
# plugin moved.

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks passed."
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
