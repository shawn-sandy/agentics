#!/usr/bin/env bash
# Objective-verification test for docs/plans/split-git-social-skills.md.
#
# Objective: the six monolithic SKILL.md bodies in git-agent and
# social-media-tools became small cores plus skill-local reference files —
# without losing a description, a reference, or a safety guard.
#
# A SKILL.md body is paid in FULL every time the skill fires; there is no
# partial load. So the invariant is about the CORE, not the plugin: guidance
# that merely exists somewhere under kit/plugins/ is not "out of context", and
# a guard that moved behind a link is a guard that may never load. Three of
# these six skills rewrite refs, push to remotes, and end in an irreversible
# squash merge, which is why check 5 exists at all.
#
# Five things are asserted, each failing for a different real mistake:
#
#   1. Core word ceiling  — the split did not actually shrink the core.
#   2. References exist    — a skill-local references/ dir with at least one
#                            .md, matching the share-react / create-issue
#                            layout these two plugins already use.
#   3. Link integrity      — every references/*.md a core names resolves, and
#                            every file in that dir is named by its core.
#                            Catches a dead pointer AND dead weight.
#   4. Descriptions pinned — the frontmatter description is the sole trigger
#                            surface; a split must not retune it.
#   5. Guard retention     — the eleven guard phrases are in the CORE of the skill
#                            that owns each, not only in a reference.
#
# Plus check 6: the plugin-level references/ link counts in the three share-*
# cores are unchanged, proving the split added skill-local files rather than
# rewiring shared infrastructure eleven other skills already read.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
CEILING=600

FAILURES=0
pass() { echo "  PASS${1:+ — $1}"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

# Word count, deliberately NOT `wc -w`. These bodies are full of multibyte
# characters (em dashes, →, ≤) and `wc -w` counts them differently by locale —
# a ~20 word swing, which is the difference between passing on a dev machine
# and failing on CI. Python decodes UTF-8 regardless of ambient locale.
count_words() { python3 -c "import sys;print(len(open(sys.argv[1],encoding='utf-8').read().split()))" "$1"; }

GA=kit/plugins/git-agent/skills
SM=kit/plugins/social-media-tools/skills

TARGETS="\
$GA/ship-autonomous/SKILL.md
$GA/branch-agent/SKILL.md
$GA/ship/SKILL.md
$SM/share-explanation/SKILL.md
$SM/share-session/SKILL.md
$SM/share-selection/SKILL.md"

echo "=== git-agent + social-media-tools skill split (objective test) ==="

# ---------------------------------------------------------------------------
# 1. Every core is under the word ceiling.
# ---------------------------------------------------------------------------
echo "1. Each split core is under $CEILING words..."
TOTAL=0
OVER=""
ABSENT=""
COUNTED=0
while read -r skill; do
  [ -n "$skill" ] || continue
  # A missing core is counted separately from an oversized one. Folding it into
  # FAILURES alone would leave OVER empty, and check 1 would print
  # "PASS: N words across six cores" for five cores while the script still
  # exited 1 — a log that contradicts the exit code.
  if [ ! -f "$skill" ]; then ABSENT="$ABSENT $(basename "$(dirname "$skill")")"; continue; fi
  words=$(count_words "$skill")
  TOTAL=$((TOTAL + words))
  COUNTED=$((COUNTED + 1))
  if [ "$words" -lt "$CEILING" ]; then
    echo "  $words  $skill"
  else
    OVER="$OVER $(basename "$(dirname "$skill")")($words)"
  fi
done <<< "$TARGETS"
if [ -n "$ABSENT" ]; then fail "core file missing:$ABSENT"; fi
if [ -n "$OVER" ]; then fail "over the $CEILING-word ceiling:$OVER"; fi
if [ -z "$ABSENT" ] && [ -z "$OVER" ]; then pass "$TOTAL words across $COUNTED cores"; fi

# ---------------------------------------------------------------------------
# 2. Each skill ships a skill-local references/ dir with at least one .md.
# ---------------------------------------------------------------------------
echo "2. Each skill has a skill-local references/ dir with >= 1 .md..."
MISSING=""
while read -r skill; do
  [ -n "$skill" ] || continue
  name="$(basename "$(dirname "$skill")")"
  refdir="$(dirname "$skill")/references"
  if [ ! -d "$refdir" ]; then MISSING="$MISSING $name:[no-dir]"; continue; fi
  n=$(find "$refdir" -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
  [ "$n" -ge 1 ] || MISSING="$MISSING $name:[no-md]"
done <<< "$TARGETS"
if [ -z "$MISSING" ]; then pass; else fail "reference layout:$MISSING"; fi

# ---------------------------------------------------------------------------
# 3. Link integrity, both directions.
# ---------------------------------------------------------------------------
echo "3. Every referenced file resolves, and no reference file is orphaned..."
python3 - <<'PY' || FAILURES=$((FAILURES + 1))
import pathlib, re, sys

GA = "kit/plugins/git-agent/skills"
SM = "kit/plugins/social-media-tools/skills"
TARGETS = [f"{GA}/ship-autonomous/SKILL.md", f"{GA}/branch-agent/SKILL.md",
           f"{GA}/ship/SKILL.md", f"{SM}/share-explanation/SKILL.md",
           f"{SM}/share-session/SKILL.md", f"{SM}/share-selection/SKILL.md"]

# `references/<name>.md`, however the core spells the prefix.
NAMED = re.compile(r'references/([A-Za-z0-9._-]+\.md)')
# Plugin-level references are shared infrastructure, not this split's output.
PLUGIN_LEVEL = {"platforms.md", "variables.md", "copy-panels.md",
                "rendering-pipeline.md", "saving-and-delivery.md",
                "reuse-check.md", "language-map.md", "social-config.md"}

bad = []
for skill in TARGETS:
    core = pathlib.Path(skill)
    if not core.is_file():
        bad.append(f"{skill} does not exist")
        continue
    own = core.parent / "references"
    text = core.read_text(encoding="utf-8")
    named = set(NAMED.findall(text))
    # Forward: a core naming a skill-local reference that is not on disk.
    for name in sorted(named - PLUGIN_LEVEL):
        if not (own / name).is_file():
            bad.append(f"{skill} points at references/{name}, which does not exist")
    # Reverse: a file in the skill's own references/ that the core never names.
    if own.is_dir():
        for ref in sorted(own.glob("*.md")):
            if ref.name not in named:
                bad.append(f"{ref} is orphaned — {skill} never names it")

if bad:
    for b in bad:
        print(f"  FAIL: {b}")
    sys.exit(1)
print("  PASS")
PY

# ---------------------------------------------------------------------------
# 4. The frontmatter description of each core is byte-identical to the
#    pre-split string. The description is the ONLY trigger surface, so a
#    reworded one silently changes when the skill fires.
# ---------------------------------------------------------------------------
echo "4. All six frontmatter descriptions are unchanged by the split..."
python3 - <<'PY' || FAILURES=$((FAILURES + 1))
import pathlib, re, sys

GA = "kit/plugins/git-agent/skills"
SM = "kit/plugins/social-media-tools/skills"
EXPECTED = {
 f"{GA}/ship-autonomous/SKILL.md":
  '"Runs the full ship pipeline with verification, CI polling, and bounded autofix. Chains tests, preview, commit, PR, CI poll, and gated merge. Use when asked to autonomously ship or watch CI."',
 f"{GA}/branch-agent/SKILL.md":
  '"Creates a git branch from origin/<default> with no upstream tracking. Auto-names the branch from staged or unstaged changes in the working tree. Use when the user asks to create or start a new branch."',
 f"{GA}/ship/SKILL.md":
  '"Ships changes by staging, committing, pushing, and opening a PR. Supports GitHub and GitLab in a single guided flow. Use when the user asks to ship changes or commit and create a PR."',
 f"{SM}/share-explanation/SKILL.md":
  '"Explains how any project file, component, or concept works. Reads source files, synthesizes principles, and generates a social card. Use when the user asks how something works or to explain it."',
 f"{SM}/share-session/SKILL.md":
  '"Generates a session recap card. Reads session JSONL and git history to produce a narrative plus highlights card. Use when asked to share a session recap or what you worked on today."',
 f"{SM}/share-selection/SKILL.md":
  '"Turns selected or pasted code into a platform-aware social card. Scrubs, picks a template, and screenshots via Playwright. Use when asked to share, post, or tweet highlighted or pasted code."',
}

bad = []
for path, want in EXPECTED.items():
    p = pathlib.Path(path)
    if not p.is_file():
        bad.append(f"{path} does not exist")
        continue
    # Read the OPENING frontmatter block only — a body code sample may legally
    # contain a `description:` line.
    m = re.match(r'---\n(.*?)\n---\n', p.read_text(encoding="utf-8"), re.S)
    if not m:
        bad.append(f"{path} has no frontmatter block")
        continue
    got = next((l[len("description:"):].strip()
                for l in m.group(1).splitlines()
                if l.startswith("description:")), None)
    if got is None:
        bad.append(f"{path} has no description: line")
    elif got != want:
        bad.append(f"{path} description drifted\n         want: {want}\n          got: {got}")

if bad:
    for b in bad:
        print(f"  FAIL: {b}")
    sys.exit(1)
print("  PASS")
PY

# ---------------------------------------------------------------------------
# 5. Guard retention. Each phrase must appear in the CORE of the skill that
#    owns it. Relocating one of these into a reference file is exactly the
#    failure mode this whole test exists for: the guard's absence is invisible
#    until the day it should have fired.
# ---------------------------------------------------------------------------
echo "5. The eleven guard phrases are still in their owning cores..."
check_guard() {
  local skill="$1" phrase="$2"
  if ! grep -qF -- "$phrase" "$skill" 2>/dev/null; then
    fail "$(basename "$(dirname "$skill")")/SKILL.md lost guard: $phrase"
  fi
}
BEFORE=$FAILURES
for phrase in \
  "Never merge on anything but green" \
  "--delete-branch" \
  "--match-head-commit" \
  "no-verify" \
  "Cap autofix at" \
  "do not commit a red tree"; do
  check_guard "$GA/ship-autonomous/SKILL.md" "$phrase"
done
check_guard "$GA/ship/SKILL.md" "Cannot ship from the default branch"
check_guard "$GA/ship/SKILL.md" "no-verify"
# ship's fourth pre-flight stop. The first split moved the STATEMENT of this one
# into references/platform-clis.md and left only "verify the CLI" in the core —
# the exact relocation this check exists to catch, and it went unnoticed because
# no phrase here covered it. The commands, install URLs, and message text stay in
# the reference; that the stop exists is core.
check_guard "$GA/ship/SKILL.md" "CLI not available or not authenticated"
check_guard "$GA/branch-agent/SKILL.md" "no-track"
check_guard "$GA/branch-agent/SKILL.md" "Do not retry. Do not force"
check_guard "$GA/branch-agent/SKILL.md" "detached HEAD"
# The three share-* cores keep their blocking scrub gate.
for s in share-explanation share-session share-selection; do
  check_guard "$SM/$s/SKILL.md" "GATE RESULT: BLOCKED"
  check_guard "$SM/$s/SKILL.md" "security-scrub"
done
[ "$FAILURES" -eq "$BEFORE" ] && pass "11 git guards + the scrub gate in all three share-* cores" || true

# ---------------------------------------------------------------------------
# 6. Plugin-level references are untouched. Those eight files are read by
#    eleven skills; rewiring them would ripple far beyond this split.
# ---------------------------------------------------------------------------
echo "6. Plugin-level \$PLUGIN_DIR/references/ links in the share-* cores are unchanged..."
MISSING=""
for pair in share-explanation:7 share-session:8 share-selection:11; do
  name="${pair%%:*}"; want="${pair##*:}"
  got=$(grep -c 'PLUGIN_DIR/references/' "$SM/$name/SKILL.md" || true)
  [ "$got" = "$want" ] || MISSING="$MISSING $name:[want $want got $got]"
done
n=$(find kit/plugins/social-media-tools/references -maxdepth 1 -name '*.md' | wc -l | tr -d ' ')
[ "$n" = "8" ] || MISSING="$MISSING plugin-references:[want 8 got $n]"
if [ -z "$MISSING" ]; then pass "7 / 8 / 11 links, 8 shared files"; else fail "shared reference set changed:$MISSING"; fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: six cores split, references wired, descriptions pinned, guards retained"
  exit 0
fi
echo "FAIL: $FAILURES check(s) failed"
exit 1
