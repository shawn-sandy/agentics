#!/usr/bin/env bash
# Objective-verification test for docs/plans/split-plan-agent-skills.md.
#
# Objective: the five monolithic plan-agent skills became small cores plus
# per-topic reference files that the core actually points at.
#
# A SKILL.md body is paid in FULL every time the skill fires — there is no
# partial load, no lazy paragraph. So the invariant is about the CORE, not the
# plugin: mechanics that merely exist somewhere under kit/plugins/ are not "out
# of context", and a reference the core never names is a file the model will
# never fetch. Four things are asserted, each failing for a different mistake:
#
#   1. Core word ceiling — the split did not actually shrink the core.
#   2. References exist  — a skill-local references/ dir with at least one .md,
#                          so "split" cannot be satisfied by deletion alone.
#   3. No dangling links — every references/<name>.md the core names resolves.
#                          A core that names a file that is not there is a hole
#                          in the workflow at exactly the step that needed it.
#   4. No orphans        — every references/*.md on disk is named by its core.
#                          An unlinked reference is dead weight: guidance that
#                          was moved out of context and never moved back in.
#
# Checks 3 and 4 are deliberately both directions. Either one alone passes for
# a split that is broken in the other direction.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
CEILING=600
SKILLS="build finalize-plan documenting-plans plan-status setup-sites"
BASE="kit/plugins/plan-agent/skills"

# Deliberately NOT `wc -w`. These bodies are full of multibyte characters (em
# dashes, arrows, ≤), and `wc -w` counts them differently by locale: in the C
# locale a standalone `—` is not a word, in C.UTF-8 it is. That is a ~20 word
# swing per file — the difference between passing on a dev machine and failing
# on a CI runner, the exact drift this test exists to prevent. Python decodes
# UTF-8 regardless of the ambient locale and gives the same answer everywhere.
count_words() { python3 -c "import sys;print(len(open(sys.argv[1],encoding='utf-8').read().split()))" "$1"; }

FAILURES=0
pass() { echo "  PASS${1:+ — $1}"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== plan-agent progressive disclosure (objective test) ==="

# ---------------------------------------------------------------------------
# 1. Every core is under the word ceiling.
# ---------------------------------------------------------------------------
echo "1. Each of the five cores is under $CEILING words..."
TOTAL=0
for s in $SKILLS; do
  core="$BASE/$s/SKILL.md"
  if [ ! -f "$core" ]; then fail "$core is missing"; continue; fi
  words="$(count_words "$core")"
  TOTAL=$((TOTAL + words))
  if [ "$words" -lt "$CEILING" ]; then
    printf '  %5d  %s\n' "$words" "$core"
  else
    fail "$core is $words words (ceiling $CEILING)"
  fi
done
[ "$FAILURES" -eq 0 ] && pass "$TOTAL words across five cores" || true

# ---------------------------------------------------------------------------
# 2. Each skill has a sibling references/ dir holding at least one .md.
# ---------------------------------------------------------------------------
echo "2. Each skill ships a references/ dir with at least one .md..."
MISSING=""
for s in $SKILLS; do
  dir="$BASE/$s/references"
  if [ ! -d "$dir" ]; then MISSING="$MISSING $s:[no-dir]"; continue; fi
  n="$(find "$dir" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')"
  [ "$n" -ge 1 ] || MISSING="$MISSING $s:[empty]"
done
if [ -z "$MISSING" ]; then pass; else fail "reference dirs:$MISSING"; fi

# ---------------------------------------------------------------------------
# 3 + 4. Link integrity, both directions.
# ---------------------------------------------------------------------------
echo "3. Every references/*.md the core names resolves (no dangling links)..."
echo "4. Every references/*.md on disk is named by its core (no orphans)..."
python3 - "$BASE" $SKILLS <<'PY' || FAILURES=$((FAILURES + 1))
import pathlib, re, sys

base, skills = pathlib.Path(sys.argv[1]), sys.argv[2:]
# `references/<name>.md`, however the core spells the prefix: bare,
# `${CLAUDE_PLUGIN_ROOT}/skills/<skill>/`, or a markdown link target.
NAMED = re.compile(r'references/([A-Za-z0-9._-]+\.md)')

bad = []
for skill in skills:
    core = base / skill / "SKILL.md"
    refdir = base / skill / "references"
    if not core.is_file():
        bad.append(f"{core} is missing")
        continue
    named = set(NAMED.findall(core.read_text(encoding="utf-8")))

    # Forward: the core points at a file that is not on disk.
    for name in sorted(named):
        if not (refdir / name).is_file():
            bad.append(f"{skill}: core points at references/{name}, which does not exist")

    # Reverse: a file on disk that the core never names.
    for ref in sorted(refdir.glob("*.md")) if refdir.is_dir() else []:
        if ref.name not in named:
            bad.append(f"{skill}: {ref} is orphaned — the core never links it")

if bad:
    for b in bad:
        print(f"  FAIL: {b}")
    sys.exit(1)
print("  PASS — both directions")
PY

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "All progressive-disclosure checks passed."
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
