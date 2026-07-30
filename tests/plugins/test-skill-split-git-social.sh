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
#   5. Guard retention     — every guard phrase is in the CORE of the skill
#                            that owns each, not only in a reference.
#
# Plus check 6: the plugin-level references/ link counts in the three share-*
# cores are unchanged, proving the split added skill-local files rather than
# rewiring shared infrastructure eleven other skills already read.
#
# And check 7: share-selection's reuse lookup and its card type cannot disagree.
# `reuse-check.md` scans `${FILE_PREFIX}-*.html` and `saving-and-delivery.md`
# saves as `${FILE_PREFIX}-…`, so the two are the same variable read at two
# points in one run. The pre-fix core bound it provisionally at Phase 1c
# ("default snippet") and only classified `CODE_RAW` at Phase 4 — so diff
# content was looked up under `snippet-` and saved under `diff-`, the lookup
# missed the existing diff post, and the skill made a duplicate. This is an
# ORDERING assertion on where the variable is bound, not a wording check.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
# Exclusive: a core must be strictly UNDER this, so 600 fails and 599 passes.
# That is the contract the plan states in three places ("a core under 600 words"),
# hence `-lt` below rather than `-le` — switching the comparison would loosen the
# spec by one word rather than fix anything.
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
# "not under", not "over": the ceiling is exclusive, so a 600-word core fails —
# and calling that "over the 600-word ceiling" would be untrue at the boundary.
if [ -n "$OVER" ]; then fail "not under the $CEILING-word ceiling:$OVER"; fi
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

# Skill-local mentions only, discriminated by CONTEXT rather than by filename.
#
# The naive `references/(...)\.md` also matches the tail of
# `$PLUGIN_DIR/references/platforms.md`, so an earlier version of this test
# carried an allowlist of the eight plugin-level basenames and skipped them. That
# allowlist was load-bearing — without it the forward check looked for
# `<skill>/references/platforms.md` and failed on a correct link — but it was too
# blunt: a core that wrote bare `references/platforms.md`, dropping the
# `$PLUGIN_DIR/`, got skipped by basename and its genuinely broken link went
# unreported. The lookbehind excludes the plugin-level path itself while still
# checking a bare mention of the same filename, which is exactly the typo case.
NAMED = re.compile(r'(?<!\$PLUGIN_DIR/)references/([A-Za-z0-9._-]+\.md)')

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
    for name in sorted(named):
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
echo "5. Every guard phrase is still in its owning core..."
# The count is tallied, never written down. Both hard-coded numbers this message
# has carried were wrong: it said "ten" while asserting 11, then "eleven" while
# asserting 12. A literal in a log line drifts the moment a guard is added, and a
# wrong count is worst exactly when someone is reading CI output to diagnose a
# guard-retention failure.
#
# Adding a guard: pick a phrase that sits on ONE line in the SKILL.md. `grep -F`
# cannot match across a newline, so a phrase the body happens to wrap — e.g.
# "Nothing to ship" breaking after "Nothing" — reports as a lost guard even
# though it is right there in the core.
GUARD_ASSERTIONS=0
GIT_GUARDS=0
check_guard() {
  local skill="$1" phrase="$2"
  GUARD_ASSERTIONS=$((GUARD_ASSERTIONS + 1))
  case "$skill" in "$GA"/*) GIT_GUARDS=$((GIT_GUARDS + 1)) ;; esac
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
[ "$FAILURES" -eq "$BEFORE" ] && pass "$GIT_GUARDS git guards + $((GUARD_ASSERTIONS - GIT_GUARDS)) scrub-gate assertions across the three share-* cores" || true

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

# ---------------------------------------------------------------------------
# 7. share-selection binds FILE_PREFIX from the card type BEFORE the reuse
#    lookup, and never rebinds it between the lookup and the save.
# ---------------------------------------------------------------------------
echo "7. share-selection's reuse-lookup prefix agrees with its card type..."
python3 - "$SM/share-selection/SKILL.md" \
         kit/plugins/social-media-tools/references/reuse-check.md \
         kit/plugins/social-media-tools/references/saving-and-delivery.md \
         "$SM/share-selection/references/card-population.md" <<'PY' \
         || FAILURES=$((FAILURES + 1))
import pathlib, re, sys

core_path, reuse_ref, save_ref, card_ref = sys.argv[1:5]
bad = []

def read(p):
    f = pathlib.Path(p)
    if not f.is_file():
        bad.append(f"{p} does not exist")
        return None
    return f.read_text(encoding="utf-8")

# Ground the premise in the references themselves rather than asserting it:
# this check only matters because BOTH consumers key off the same $FILE_PREFIX.
# If a future edit renames the variable in one of them, fail here loudly
# instead of silently checking an invariant that no longer binds anything.
for ref, role in ((reuse_ref, "reuse lookup"), (save_ref, "persistent save")):
    text = read(ref)
    if text is not None and "`$FILE_PREFIX`" not in text:
        bad.append(f"{ref} no longer declares $FILE_PREFIX — the {role} "
                   f"stopped keying off the variable this check tracks")

# The core must point at a classification step that actually exists.
card = read(card_ref)
if card is not None and not re.search(r'^#+ .*Classify `CODE_RAW`', card, re.M):
    bad.append(f"{card_ref} has no 'Classify `CODE_RAW`' section for the core to run")

core = read(core_path)
if core is None:
    for b in bad:
        print(f"  FAIL: {b}")
    sys.exit(1)
lines = core.splitlines()

# A BINDING is an assignment (`FILE_PREFIX=…`) or an imperative that hands the
# variable a value (`set `FILE_PREFIX` (`snippet` or `diff`…)` / `… to X`).
# Deliberately NOT a bare mention: Phase 5b's "Variables already set:
# `FILE_PREFIX`, `SLUG_INPUT`" restates what Phase 1c bound and must not read
# as a rebind, or the fixed core would fail its own check.
BIND = re.compile(r'FILE_PREFIX\s*=|(?:[Ss]et|[Bb]ind)\s+`?FILE_PREFIX`?\s*(?:\(|to\b)')

def first(pattern):
    for i, line in enumerate(lines):
        if re.search(pattern, line):
            return i
    return None

reuse = first(r'reuse-check\.md')
save = first(r'saving-and-delivery\.md')
card_type = first(r'CARD_TYPE')
binds = [i for i, line in enumerate(lines) if BIND.search(line)]

if reuse is None:
    bad.append("core never reads reuse-check.md")
if save is None:
    bad.append("core never reads saving-and-delivery.md")

if reuse is not None and save is not None:
    # (a) The prefix the lookup scans under must already be bound when it runs.
    if not binds:
        bad.append("core never binds FILE_PREFIX — the reuse lookup would scan "
                   "under an undefined prefix")
    elif min(binds) > reuse:
        bad.append(f"FILE_PREFIX is first bound at line {min(binds) + 1}, after the "
                   f"reuse lookup at line {reuse + 1}")

    # (b) Classification must precede the lookup. A prefix bound to a literal
    #     default with the card type "per Phase 4" is the original bug: the
    #     binding is early but the decision that determines it is not.
    if card_type is None:
        bad.append("core never establishes CARD_TYPE — the reuse lookup cannot "
                   "be using the card type Phase 4 selects")
    elif card_type > reuse:
        bad.append(f"CARD_TYPE is first established at line {card_type + 1}, after "
                   f"the reuse lookup at line {reuse + 1} — classification is deferred")

    # (c) Nothing may rebind the prefix between the lookup and the save, or the
    #     post is filed under a prefix the lookup never searched.
    late = [i + 1 for i in binds if reuse < i < save]
    if late:
        bad.append(f"FILE_PREFIX is rebound at line(s) {late}, between the reuse "
                   f"lookup (line {reuse + 1}) and the save (line {save + 1})")

if bad:
    for b in bad:
        print(f"  FAIL: {b}")
    sys.exit(1)
print("  PASS")
PY

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: six cores split, references wired, descriptions pinned, guards retained, reuse prefix consistent"
  exit 0
fi
echo "FAIL: $FAILURES check(s) failed"
exit 1
