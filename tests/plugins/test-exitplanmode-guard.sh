#!/usr/bin/env bash
set -euo pipefail

# A skill that starts writing files inside plan mode violates a standing user
# preference, and it fails silently — the write either errors confusingly or
# escapes a mode the user deliberately entered. So the guard must survive.
#
# It used to survive as a four-line tutorial repeated in 43 files: what plan
# mode is, why writes are mutations, how to ToolSearch for the deferred tool,
# how to treat the "not in plan mode" error. That is context cost in every
# session, teaching a current model something it already knows.
#
# This test holds both ends: the tutorial stays gone, and the guard stays
# present in every skill that mutates. The third check is the one that matters
# — it fails if a future cleanup strips the guard along with the boilerplate.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGINS="$ROOT/kit/plugins"
WORD_BUDGET=200
FAILURES=0

# The full canonical line, verbatim, as documented in
# .claude/rules/plugin-patterns.md. Matching the whole sentence rather than its
# tail is what makes "verbatim" true: a substring match would accept reworded
# openings like "Before writing anything, call `ExitPlanMode` first — ...".
GUARD='**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.'

# Skills, commands, and agents that carried a plan-mode guard before the
# boilerplate sweep. Hardcoded rather than derived: a list computed from "files
# that contain the guard" would assert only that present files are present.
#
# SCOPE: this manifest is a retention check, not a repo-wide coverage check.
# Roughly 20 other instruction files declare Write/Edit and have never carried a
# guard (`code-testing-agent/skills/tdd-fix`, `settings-sync/skills/*`, and
# others). Guarding those is real work with its own blast radius, tracked as a
# follow-up in docs/plans/remove-exitplanmode-boilerplate.md. Do not read a
# green Check 3 as "every mutating workflow in this repo is guarded".
WRITE_HEAVY=(
  artifact-tools/skills/diff-artifact/SKILL.md
  artifact-tools/skills/plan-artifact/SKILL.md
  artifact-tools/skills/prompt-artifact/SKILL.md
  artifact-tools/skills/session-artifact/SKILL.md
  artifact-tools/skills/teach-artifact/SKILL.md
  code-testing-agent/skills/tdd-loop/SKILL.md
  code-testing-agent/skills/verified-change/SKILL.md
  content-tools/skills/artifact-to-post/SKILL.md
  git-agent/agents/agent-merge.md
  git-agent/agents/agent-ship-ci.md
  git-agent/agents/agent-ship.md
  git-agent/skills/branch-agent/SKILL.md
  git-agent/skills/commit-agent/SKILL.md
  git-agent/skills/create-issue/SKILL.md
  git-agent/skills/merge/SKILL.md
  git-agent/skills/pr-agent/SKILL.md
  git-agent/skills/ship-autonomous/SKILL.md
  git-agent/skills/ship/SKILL.md
  plan-agent/skills/build-feature/SKILL.md
  plan-agent/skills/build-proposal/SKILL.md
  plan-agent/skills/build/SKILL.md
  plan-agent/skills/finalize-plan/SKILL.md
  plan-agent/skills/implementation-plan/SKILL.md
  plan-agent/skills/plan-status/SKILL.md
  plan-agent/skills/plans-library/SKILL.md
  plan-agent/skills/prototype/SKILL.md
  plan-agent/skills/publish-hub/SKILL.md
  plan-agent/skills/review-plan/SKILL.md
  plan-agent/skills/setup-sites/SKILL.md
  settings-sync/skills/settings-backup/SKILL.md
  settings-sync/skills/settings-restore/SKILL.md
  skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md
  social-media-tools/skills/media-library/SKILL.md
  social-media-tools/skills/save-artifact/SKILL.md
  social-media-tools/skills/share-blog/SKILL.md
  social-media-tools/skills/share-code/SKILL.md
  social-media-tools/skills/share-explanation/SKILL.md
  social-media-tools/skills/share-github/SKILL.md
  social-media-tools/skills/share-init/SKILL.md
  social-media-tools/skills/share-project/SKILL.md
  social-media-tools/skills/share-react/SKILL.md
  social-media-tools/skills/share-scan/SKILL.md
  social-media-tools/skills/share-selection/SKILL.md
  social-media-tools/skills/share-session/SKILL.md
  social-media-tools/skills/share-video/SKILL.md
  social-media-tools/skills/social-share/SKILL.md
)

# Pure dispatchers. Each hands off to a skill or agent that carries its own
# guard, so a second copy here would be the duplication this test exists to
# prevent.
READ_ONLY=(
  plan-agent/commands/review-plan-bg.md
  social-media-tools/commands/digest.md
)

echo "=== ExitPlanMode Guard Test ==="

if [ ! -d "$PLUGINS" ]; then
  echo "FATAL: $PLUGINS does not exist — every check below would cascade."
  exit 1
fi

# --- Check 1: the tutorial is gone ------------------------------------------
# CHANGELOGs are an immutable record and legitimately quote the old mechanics,
# so they are out of scope. Everything else is live instruction text.
echo
echo "-- Check 1: long-form tutorial absent --"
TUTORIAL=$(grep -rn --include='*.md' --include='*.json' 'ExitPlanMode' "$PLUGINS" \
  | grep -v '/CHANGELOG.md:' \
  | grep -iE 'select:ExitPlanMode|is a deferred tool' || true)

if [ -n "$TUTORIAL" ]; then
  echo "FAIL: the ExitPlanMode tutorial is back. Use the one-line guard instead:"
  echo "        $GUARD"
  echo "$TUTORIAL" | sed 's/^/        /'
  FAILURES=$((FAILURES + 1))
else
  echo "PASS: no file re-teaches the ToolSearch/deferred-tool mechanics."
fi

# --- Check 2: no EXCESS prose around the guard ------------------------------
# Counts words on ExitPlanMode lines that are NOT the canonical guard, so the
# budget measures tutorial creep only. A plain total would grow by 12 words
# every time someone correctly guards a new mutating workflow, and would fail
# CI for doing the right thing once two or three were added.
#
# Scope is instruction-file bodies: skills, commands, and agents. Frontmatter
# is excluded because `allowed-tools:` is the permission declaration, not
# prose — deleting it breaks the tool rather than saving context. CHANGELOGs
# are excluded as history.
echo
echo "-- Check 2: non-guard ExitPlanMode prose under $WORD_BUDGET words --"
WORDS=$(find "$PLUGINS" -type f \
  \( -path '*/skills/*/SKILL.md' -o -path '*/commands/*.md' -o -path '*/agents/*.md' \) \
  -exec awk -v guard="$GUARD" '
    FNR == 1 { infm = ($0 == "---"); if (infm) next }
    infm && $0 == "---" { infm = 0; next }
    !infm && /ExitPlanMode/ && index($0, guard) == 0 { n += NF }
    END { print n + 0 }
  ' {} \; | awk '{s += $1} END {print s + 0}')

if [ "$WORDS" -ge "$WORD_BUDGET" ]; then
  echo "FAIL: $WORDS words of non-guard ExitPlanMode prose, budget is $WORD_BUDGET."
  echo "      The tutorial is creeping back in a reworded form."
  FAILURES=$((FAILURES + 1))
else
  echo "PASS: $WORDS words of non-guard prose (budget $WORD_BUDGET)."
fi

# --- Check 3: every write-heavy skill still guards --------------------------
echo
echo "-- Check 3: guard retained in all ${#WRITE_HEAVY[@]} previously-guarded files --"
MISSING=0
for rel in "${WRITE_HEAVY[@]}"; do
  f="$PLUGINS/$rel"
  if [ ! -f "$f" ]; then
    echo "FAIL: $rel is listed as write-heavy but does not exist."
    echo "      If it was renamed or removed, update this test's manifest."
    MISSING=$((MISSING + 1))
  elif ! grep -qF "$GUARD" "$f"; then
    echo "FAIL: $rel mutates state but has lost its plan-mode guard."
    MISSING=$((MISSING + 1))
  fi
done
if [ "$MISSING" -gt 0 ]; then
  echo "      Restore verbatim: $GUARD"
  FAILURES=$((FAILURES + 1))
else
  echo "PASS: all ${#WRITE_HEAVY[@]} previously-guarded files retain the guard."
fi

# --- Check 4: read-only dispatchers carry no guard --------------------------
echo
echo "-- Check 4: dispatchers do not duplicate a downstream guard --"
EXTRA=0
for rel in "${READ_ONLY[@]}"; do
  f="$PLUGINS/$rel"
  if [ ! -f "$f" ]; then
    echo "FAIL: $rel is listed as read-only but does not exist."
    EXTRA=$((EXTRA + 1))
  elif grep -q 'ExitPlanMode' "$f"; then
    echo "FAIL: $rel dispatches to a guarded skill and needs no guard of its own."
    EXTRA=$((EXTRA + 1))
  elif sed -n '1,25p' "$f" | grep -E '^allowed-tools:' | grep -qw 'ToolSearch'; then
    echo "FAIL: $rel still declares ToolSearch, which it only needed for ExitPlanMode."
    EXTRA=$((EXTRA + 1))
  fi
done
if [ "$EXTRA" -gt 0 ]; then
  FAILURES=$((FAILURES + 1))
else
  echo "PASS: all ${#READ_ONLY[@]} dispatchers stay clean."
fi

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "=== FAILED ($FAILURES of 4 checks) ==="
  exit 1
fi
echo "=== PASSED (4 of 4 checks) ==="
