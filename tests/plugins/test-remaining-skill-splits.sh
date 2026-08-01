#!/usr/bin/env bash
# Objective-verification test for docs/plans/split-remaining-plugin-skills.md.
#
# Objective: six monolithic SKILL.md bodies became small cores plus per-topic
# reference files, with no behaviour and no frontmatter changed.
#
# A SKILL.md body is paid in FULL every time the skill fires — there is no
# partial load. So the invariant is about the core, not the plugin: content that
# merely exists somewhere under kit/plugins/ is not "moved out of context", and a
# gate that moved behind a link is a gate that may never load. Four things are
# asserted, and each one fails for a different real mistake:
#
#   1. Core word ceiling      — the split did not actually shrink the core.
#   2. Reference placement    — references landed where the plugin's convention
#                               puts them (per-skill vs plugin-level), and there
#                               are at least two, so "split" is not one rename.
#   3. Link integrity         — every references/*.md a core names resolves, and
#                               every reference on disk is named by some core.
#                               Catches both a dead pointer and dead weight.
#   4. Gate retention         — the blocking security-scrub gate is still in the
#                               CORE of both artifact-tools skills, ahead of the
#                               publish bootstrap.
#
# Plus a unit check: the four frontmatter lines of all six targets are
# byte-identical to origin/main, so the split cannot have silently retuned a
# description, an allowed-tools list, or an invocation flag.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
CEILING=600
BASE_REF="${BASE_REF:-origin/main}"

# Word count, deliberately NOT `wc -w`. These bodies are full of multibyte
# characters (em dashes, ≤, →, …), and `wc -w` counts them differently by locale:
# in the C locale a standalone `—` is not a word, in C.UTF-8 it is. That is a ~20
# word swing per file, which is the difference between passing on a dev machine
# and failing on a CI runner — the exact drift this test exists to prevent. So
# count in Python, which decodes UTF-8 regardless of the ambient locale and gives
# the same answer everywhere. `python3` is already a hard dependency below.
count_words() { python3 -c "import sys;print(len(open(sys.argv[1],encoding='utf-8').read().split()))" "$1"; }

# How many distinct `references/<name>.md` links this core names that actually
# resolve — against the skill's own dir first, then the plugin-level dir.
count_own_refs() {
  python3 - "$1" "$2" <<'EOF'
import pathlib, re, sys
core, refdir = sys.argv[1], sys.argv[2]
text = pathlib.Path(core).read_text(encoding="utf-8")
names = set(re.findall(r'references/([A-Za-z0-9._-]+\.md)', text))
own = pathlib.Path(core).parent / "references"
print(sum(1 for n in sorted(names)
          if (own / n).is_file() or (pathlib.Path(refdir) / n).is_file()))
EOF
}
FAILURES=0
pass() { echo "  PASS${1:+ — $1}"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

# target|reference directory (the plugin's own convention)
#   per-skill:     skill-reviewer, memory-tools, code-testing-agent
#   plugin-level:  artifact-tools, content-tools
TARGETS="\
kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md|kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references
kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md|kit/plugins/memory-tools/skills/path-rules-advisor/references
kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md|kit/plugins/code-testing-agent/skills/tdd-fix/references
kit/plugins/content-tools/skills/artifact-to-post/SKILL.md|kit/plugins/content-tools/references
kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md|kit/plugins/artifact-tools/references
kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md|kit/plugins/artifact-tools/references"

echo "=== remaining skill splits (objective test) ==="

# ---------------------------------------------------------------------------
# 1. Every core is under the word ceiling.
# ---------------------------------------------------------------------------
echo "1. Each split core is under $CEILING words..."
TOTAL=0
while IFS='|' read -r skill _; do
  [ -n "$skill" ] || continue
  if [ ! -f "$skill" ]; then fail "$skill missing"; continue; fi
  words=$(count_words "$skill")
  TOTAL=$((TOTAL + words))
  if [ "$words" -lt "$CEILING" ]; then
    echo "  $words  $skill"
  else
    fail "$skill is $words words (ceiling $CEILING)"
  fi
done <<< "$TARGETS"
[ "$FAILURES" -eq 0 ] && pass "$TOTAL words across six cores" || true

# ---------------------------------------------------------------------------
# 2. References exist, in the directory this plugin's convention dictates, and
#    there are at least two of them per target.
# ---------------------------------------------------------------------------
echo "2. Each target links >= 2 reference files in its plugin's conventional dir..."
MISSING=""
while IFS='|' read -r skill refdir; do
  [ -n "$skill" ] || continue
  name="$(basename "$(dirname "$skill")")"
  if [ ! -d "$refdir" ]; then MISSING="$MISSING $name:[no-dir]"; continue; fi
  # Count the references THIS core links and that resolve, not every file in the
  # directory. Under a plugin-level layout the directory is shared, so counting
  # files would let a target pass on its siblings' references while linking none
  # of its own.
  n=$(count_own_refs "$skill" "$refdir")
  [ "$n" -ge 2 ] || MISSING="$MISSING $name:[$n-linked-refs]"
  # A per-skill layout and a plugin-level layout inside ONE plugin is what
  # breaks reader expectation, so assert the target has no dir of the other kind.
  sibling="$(dirname "$skill")/references"
  if [ "$refdir" != "$sibling" ] && [ -d "$sibling" ]; then
    MISSING="$MISSING $name:[two-conventions]"
  fi
done <<< "$TARGETS"
if [ -z "$MISSING" ]; then pass; else fail "reference layout:$MISSING"; fi

# ---------------------------------------------------------------------------
# 3. Link integrity, both directions.
# ---------------------------------------------------------------------------
echo "3. Every referenced file resolves, and no reference file is orphaned..."
python3 - <<'PY' || FAILURES=$((FAILURES + 1))
import pathlib, re, sys

TARGETS = [
    ("kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md",
     "kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/references"),
    ("kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md",
     "kit/plugins/memory-tools/skills/path-rules-advisor/references"),
    ("kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md",
     "kit/plugins/code-testing-agent/skills/tdd-fix/references"),
    ("kit/plugins/content-tools/skills/artifact-to-post/SKILL.md",
     "kit/plugins/content-tools/references"),
    ("kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md",
     "kit/plugins/artifact-tools/references"),
    ("kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md",
     "kit/plugins/artifact-tools/references"),
]

# `references/<name>.md`, however the core spells the prefix:
# bare, `${CLAUDE_PLUGIN_ROOT}/`, or `$SKILL_DIR/../../`.
NAMED = re.compile(r'references/([A-Za-z0-9._-]+\.md)')

bad = []
# Forward: a core naming a reference that is not on disk.
for skill, refdir in TARGETS:
    core = pathlib.Path(skill).read_text(encoding="utf-8")
    for name in sorted(set(NAMED.findall(core))):
        # Resolve against the skill's own dir first, then the plugin-level dir.
        candidates = [pathlib.Path(skill).parent / "references" / name,
                      pathlib.Path(refdir) / name]
        if not any(c.is_file() for c in candidates):
            bad.append(f"{skill} points at references/{name}, which does not exist")

# Reverse: a reference on disk that nothing in that plugin names. Readers here
# means every SKILL.md *and* every command in the plugin, since plugin-level
# references are shared (titles.md is read by four skills, not only the two
# that were split, and recap-core.md is read by three commands and no skill).
# Globbing skills alone would report a command-only reference as orphaned.
for refdir in sorted({d for _, d in TARGETS}):
    plugin = pathlib.Path(refdir)
    while plugin.parent.name != "plugins":
        plugin = plugin.parent
    readers = "\n".join(
        p.read_text(encoding="utf-8")
        for p in sorted([*plugin.glob("skills/*/SKILL.md"), *plugin.glob("commands/*.md")])
    )
    for ref in sorted(pathlib.Path(refdir).glob("*.md")):
        if f"references/{ref.name}" not in readers:
            bad.append(
                f"{ref} is orphaned — no SKILL.md or command in {plugin.name} links to it"
            )

if bad:
    for b in bad:
        print(f"  FAIL: {b}")
    sys.exit(1)
print("  PASS")
PY

# ---------------------------------------------------------------------------
# 4. The blocking scrub gate is in the CORE of both artifact skills, ahead of
#    the publish bootstrap. Order, not mere presence: a skill that published
#    first and documented the gate afterwards satisfies a presence-only check
#    while shipping unscanned content.
# ---------------------------------------------------------------------------
echo "4. The scrub gate is still in both artifact-tools cores, before publish..."
MISSING=""
for skill in diff-artifact prompt-artifact; do
  f="kit/plugins/artifact-tools/skills/$skill/SKILL.md"
  if ! python3 - "$f" <<'PY'
import re, sys
path = sys.argv[1]
skill = path.split('/')[-2]
body = re.match(r'---\n.*?\n---\n(.*)$', open(path, encoding="utf-8").read(), re.S).group(1)
lines = body.splitlines()

def first(pattern):
    for i, line in enumerate(lines):
        if re.search(pattern, line):
            return i
    return None

scrub   = first(r'security-scrub')
blocked = first(r'GATE RESULT: BLOCKED')
stop    = first(r'(?i)hard stop')
publish = first(r'select:Artifact')

for label, idx in (('security-scrub invocation', scrub),
                   ('GATE RESULT: BLOCKED verdict', blocked),
                   ('hard-stop language', stop),
                   ('select:Artifact publish bootstrap', publish)):
    if idx is None:
        sys.exit(f"{skill}: {label} is not in the CORE")

if not (scrub < publish and blocked < publish and stop < publish):
    sys.exit(f"{skill}: the gate is documented after the publish bootstrap")
PY
  then
    MISSING="$MISSING $skill"
  fi
done
if [ -z "$MISSING" ]; then pass; else fail "core gate lost in:$MISSING"; fi

# ---------------------------------------------------------------------------
# 5. UNIT: frontmatter is untouched by the split.
# ---------------------------------------------------------------------------
echo "5. UNIT: the whole opening frontmatter block matches $BASE_REF..."
if ! git rev-parse --verify --quiet "$BASE_REF" >/dev/null; then
  fail "$BASE_REF is not available locally — run: git fetch origin main"
else
  MISSING=""
  # Compare the ENTIRE opening `---` block, not a list of named keys. Checking
  # only name/description/allowed-tools/disable-model-invocation would let an
  # added or removed key through while the test still reported "unchanged" — and
  # a stray frontmatter key changes how the skill loads just as much as a
  # reworded description does. A body code sample may legally contain a
  # `description:` line, which is why this reads the opening block and not the
  # whole file.
  fm() { awk 'NR==1&&/^---$/{f=1;next} f&&/^---$/{exit} f' ; }
  while IFS='|' read -r skill _; do
    [ -n "$skill" ] || continue
    name="$(basename "$(dirname "$skill")")"
    now=$(fm < "$skill")
    was=$(git show "$BASE_REF:$skill" | fm)
    [ "$now" = "$was" ] || MISSING="$MISSING $name"
  done <<< "$TARGETS"
  if [ -z "$MISSING" ]; then pass "whole block, not just named keys"; else fail "frontmatter block drifted:$MISSING"; fi
fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: six cores split, references wired, gates retained, frontmatter unchanged"
  exit 0
fi
echo "FAIL: $FAILURES check(s) failed"
exit 1
