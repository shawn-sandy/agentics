#!/usr/bin/env bash
set -euo pipefail

# Objective test: an ARTIFACT-published plan is reachable by the skills that
# consume a plan after it is authored.
#
# Since plan-agent 9.7.0 the local `<stem>.html` is a `--file` opt-in and the
# claude.ai artifact is the default deliverable, so the ordinary shape of a
# plan on disk is a `.md` spec carrying `artifact-url:` and NOTHING else. The
# completion path was taught that shape in 9.9.0
# (tests/plugins/test-artifact-plan-completion.sh). Three consumers were not:
#
#   * review-plan discovered plans with `glob docs/plans/*.html`, so an
#     artifact plan was invisible to the reviewer — and its Step 7 re-render
#     wrote `<stem>.html` unconditionally, resurrecting the file the author
#     chose not to publish and flipping the gallery card off the artifact.
#   * design and prototype classified only a `.html` first token as a plan
#     path. A `.md` spec fell through to the "raw idea" branch, so the skill
#     silently designed against the literal path string instead of the plan.
#
# These asserts pin the artifact shape in each of those entry points.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLAN_AGENT="$ROOT/kit/plugins/plan-agent"
REVIEW="$PLAN_AGENT/skills/review-plan/SKILL.md"
DESIGN="$PLAN_AGENT/skills/design/SKILL.md"
PROTOTYPE="$PLAN_AGENT/skills/prototype/SKILL.md"
AGENT="$PLAN_AGENT/agents/agent-review-plan.md"
README="$PLAN_AGENT/README.md"

FAILURES=0
pass() { echo "  PASS${1:+ — $1}"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== artifact-published plans reach their consumers (objective test) ==="

# ---------------------------------------------------------------------------
# 1. review-plan can actually call Artifact.
#
# Without it in allowed-tools the republish prompts mid-run — which in
# background mode, the mode the agent-review-plan subagent always uses, means
# it silently never happens.
# ---------------------------------------------------------------------------
echo "1. review-plan lists Artifact in allowed-tools..."
if grep -qE '^allowed-tools:.*\bArtifact\b' "$REVIEW"; then
  pass
else
  fail "review-plan allowed-tools has no Artifact — the republish would prompt or fail"
fi

# The background agent's own `tools:` list gates what the skill it invokes can
# reach, so review-plan's allowed-tools alone is not enough: agent-review-plan
# always runs in background mode, the one mode with no human to approve a
# prompt.
echo "1a. ...and so does the agent-review-plan background subagent..."
if grep -qE '^tools:.*\bArtifact\b' "$AGENT"; then
  pass
else
  fail "agent-review-plan tools has no Artifact — the background republish cannot run"
fi

# ---------------------------------------------------------------------------
# 2. Step 1 discovery can SEE an artifact plan.
#
# The HTML glob cannot: these plans have no HTML. The default-discovery path
# is the one that matters — a user who runs the skill bare gets whichever plan
# it found, and before this it could only ever find a file-published one.
# ---------------------------------------------------------------------------
echo "2. review-plan Step 1 discovers artifact plans by spec, not by HTML alone..."
if grep -qF 'artifact-url:' "$REVIEW" \
   && grep -qF 'no sibling' "$REVIEW"; then
  pass
else
  fail "review-plan Step 1 has no spec-side artifact discovery — an artifact plan is invisible to it"
fi

# A hostless `https://` reaches Artifact as a NEW url rather than an update,
# stranding the link people already have. Same gate implementation-plan 7b,
# publish-hub, and the finalize-plan sweep apply.
echo "2a. ...and requires an http(s) URL with a host before republishing..."
if grep -qF 'http(s)' "$REVIEW" && grep -qF 'host' "$REVIEW"; then
  pass
else
  fail "review-plan does not gate artifact-url on an http(s) URL with a host"
fi

# ---------------------------------------------------------------------------
# 3. An explicit `.md` spec path is accepted.
#
# It is the only path an artifact plan has. finalize-plan Step 1 already takes
# "a token ending in .html or .md"; review-plan took .html only, so the obvious
# invocation — pasting the path the author actually has — did not resolve.
# ---------------------------------------------------------------------------
echo "3. review-plan accepts an explicit .md spec path..."
if grep -qF '.html` or `.md' "$REVIEW"; then
  pass
else
  fail "review-plan Step 1 accepts only .html paths — an artifact plan cannot be passed by path"
fi

# ---------------------------------------------------------------------------
# 4. Step 7 re-render branches on the sibling and republishes.
#
# Writing <stem>.html here is the tempting wrong fix: it makes the render
# "work" while flipping the plan's gallery card off the artifact onto a local
# path. The review is also exactly when the shared page most needs updating —
# it is the state every other reader sees.
# ---------------------------------------------------------------------------
echo "4. review-plan Step 7 renders to scratchpad and republishes when no sibling exists..."
if grep -qF '$SCRATCHPAD' "$REVIEW" \
   && grep -qF 'Never write `<stem>.html`' "$REVIEW"; then
  pass
else
  fail "review-plan Step 7 always writes <stem>.html — it resurrects the unpublished file and never republishes"
fi

# Dropping `-o` does not error: the renderer defaults its output to the
# sibling <stem>.html, exits 0, and says nothing — silently producing the one
# file this whole path exists to avoid. Verified against bin/plan-agent-render.
# The instruction has to say so, because "the example shows -o" is not a rule.
echo "4a. ...and says -o is mandatory, since omitting it silently writes the sibling..."
if grep -qF '`-o` is **mandatory** here' "$REVIEW"; then
  pass
else
  fail "review-plan Step 7 does not mark -o mandatory — omitting it silently creates the forbidden sibling"
fi

# ---------------------------------------------------------------------------
# 5-6. design and prototype classify a `.md` spec as a plan path.
#
# Their token test was `.html` only. A `.md` fell through to the final
# "otherwise the whole argument string is a raw idea" branch, so the skill ran
# to completion having designed against a filename.
# ---------------------------------------------------------------------------
echo "5. design treats a .md spec as a plan path..."
if grep -qF 'ends in `.html` or `.md`' "$DESIGN"; then
  pass
else
  fail "design classifies only .html as a plan path — an artifact plan's spec becomes a raw idea"
fi

echo "6. prototype treats a .md spec as a plan path..."
if grep -qF 'ends in `.html` or `.md`' "$PROTOTYPE"; then
  pass
else
  fail "prototype classifies only .html as a plan path — an artifact plan's spec becomes a raw idea"
fi

# ---------------------------------------------------------------------------
# 7. Documented.
# ---------------------------------------------------------------------------
echo "7. README documents that artifact plans are reviewable and designable..."
if grep -qF 'Artifact-published plans are first-class' "$README"; then
  pass
else
  fail "plan-agent README does not document artifact plans as first-class consumer input"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks passed."
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
