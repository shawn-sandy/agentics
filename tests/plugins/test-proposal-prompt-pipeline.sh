#!/usr/bin/env bash
set -euo pipefail

# OBJECTIVE-VERIFICATION TEST
# docs/plans/refactor-build-proposal-to-emit-prompt.md
#
# Objective: build-proposal converges on a saved prompt authored by write-prompt.
#
# One run over every seam of the refactor: the command wrapper that unblocks
# programmatic invocation, the fifth prompt type and its template, the Step 6
# dual-write with its date-free derived path and deprecation banner, the Step 8
# handoff, preserved tier behaviour, the gallery's fifth chip, and the absence of
# any bare-.md handoff. A seam that passes in isolation but not here means the
# pieces exist and do not connect.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PA="$ROOT/kit/plugins/plan-agent"
WRAPPER="$PA/commands/write-prompt.md"
WP="$PA/skills/write-prompt/SKILL.md"
TEMPLATE="$PA/skills/write-prompt/references/proposal-prompt-template.md"
BP_DIR="$PA/skills/build-proposal"
BP="$BP_DIR/SKILL.md"
SHAPE="$BP_DIR/references/artifact-shape.md"
BUILD="$PA/skills/build/SKILL.md"
GALLERY="$ROOT/kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md"
# prompt-artifact is split core-plus-references: the library gallery's card and
# filter rules live in references/prompt-page.md, the tolerant-frontmatter rule in
# references/prompt-resolution.md. Check 8 asserts on what the skill ships, so it
# reads the core plus those two — not the core alone, which would go green on a
# gallery whose fifth chip was quietly dropped from the reference.
GALLERY_REFS=(
  "$ROOT/kit/plugins/artifact-tools/references/prompt-page.md"
  "$ROOT/kit/plugins/artifact-tools/references/prompt-resolution.md"
)
FAILURES=0

# These files are hard-wrapped prose; flatten before asserting on a phrase.
flat() { tr '\n' ' ' | tr -s ' '; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== Proposal-to-Prompt Pipeline (objective test) ==="

echo "1. The seam is open: a command wrapper reaches write-prompt despite disable-model-invocation..."
# The flag blocks programmatic Skill() invocation, not just ambient activation, so
# a command wrapper is needed to put the name in the registry at all. But the
# command SHADOWS the skill of the same name: a wrapper that delegates via
# Skill(skill: "plan-agent:write-prompt") returns itself, and the seven phases
# never load (probe: 0 "## Phase" headings that way, 7 when loaded by path).
# The wrapper must therefore Read the skill file, and say why.
M=""
[ -f "$WRAPPER" ] || M="$M wrapper-missing"
if [ -f "$WRAPPER" ]; then
  WF="$(cat "$WRAPPER" | flat)"
  printf '%s' "$WF" | grep -qF 'skills/write-prompt/SKILL.md' || M="$M wrapper-loads-nothing"
  printf '%s' "$WF" | grep -qi 'shadows the skill' || M="$M self-delegation-unguarded"
fi
grep -q '^disable-model-invocation: true$' "$WP" || M="$M flag-dropped"
[ -z "$M" ] && echo "  PASS" || fail "invocation seam:$M"

echo "2. write-prompt declares the proposal type and its template carries all 11 slots..."
M=""
grep -qE '^\| \*\*proposal\*\*' "$WP" || M="$M type-table"
grep -qF 'references/proposal-prompt-template.md' "$WP" || M="$M template-selection"
[ -f "$TEMPLATE" ] || M="$M template-file"
if [ -f "$TEMPLATE" ]; then
  for s in TLDR CONTEXT CORE_FINDING COMPARISON_TABLE LOCKED_DECISIONS WORKSTREAMS \
           RISKS OPEN_QUESTIONS ROADMAP APPENDICES CORE_INSTRUCTION; do
    grep -qF "{{$s}}" "$TEMPLATE" || M="$M slot:$s"
  done
fi
[ -z "$M" ] && echo "  PASS" || fail "fifth type incomplete:$M"

echo "3. build-proposal Step 6 delegates to write-prompt and dictates the path..."
# The caller must pass --out. Skill() returns nothing this skill can read, and
# write-prompt's own Phase 7 would resolve a different directory and a different
# intent slug — so an independently derived path names a file nobody wrote.
STEP6="$(sed -n '/^### Step 6 —/,/^### Step 7 —/p' "$BP")"
STEP6F="$(printf '%s' "$STEP6" | flat)"
M=""
printf '%s' "$STEP6" | grep -qF 'Skill(skill: "plan-agent:write-prompt"' || M="$M no-delegation"
printf '%s' "$STEP6" | grep -qF -- '--out' || M="$M no-out-path"
printf '%s' "$STEP6" | grep -qF -- '--answers-gathered' || M="$M no-interview-bypass"
cat "$WP" | flat | grep -qF -- '--out <path>' || M="$M out-not-honoured"
printf '%s' "$STEP6F" | grep -qi 'byte-identical' || M="$M path-agreement-unstated"
[ -z "$M" ] && echo "  PASS" || fail "Step 6 delegation:$M"

echo "4. The derived prompt path is date-free, so a multi-day loop keeps one file..."
# A dated filename would resolve differently after midnight and fork the living
# document in two — the exact failure the in-place rewrite exists to prevent.
M=""
grep -qF 'proposal-<slug>.md' "$BP" || M="$M no-date-free-pattern"
# A dated pattern is allowed only on the line that forbids it.
if grep -E 'proposal-<slug>-<?(YYYY|[0-9]{4})' "$BP" | grep -qvi 'never'; then
  M="$M dated-filename"
fi
cat "$BP" | flat | grep -qi 'filename carries no date' || M="$M rule-unstated"
grep -qF 'docs/prompts/' "$BP" || M="$M no-default-prompts-dir"
[ -z "$M" ] && echo "  PASS" || fail "prompt path derivation:$M"

echo "5. The legacy proposal copy is still written, and says it is not authoritative..."
M=""
printf '%s' "$STEP6F" | grep -qi 'deprecated' || M="$M no-banner"
printf '%s' "$STEP6F" | grep -qi 'authoritative artifact is the saved prompt' || M="$M banner-omits-authority"
printf '%s' "$STEP6" | grep -qF '<proposals-dir>/<slug>.md' || M="$M no-legacy-write"
grep -q 'planAgent.proposalsDirectory' "$BP" || M="$M legacy-dir-unresolved"
[ -z "$M" ] && echo "  PASS" || fail "dual-write legacy copy:$M"

echo "6. Step 8 hands off the prompt path, led by objective text..."
STEP8="$(sed -n '/^### Step 8 —/,/^## Operating principles/p' "$BP")"
STEP8F="$(printf '%s' "$STEP8" | flat)"
M=""
printf '%s' "$STEP8" | grep -qF 'prompts-dir>/proposal-<slug>.md' || M="$M handoff-not-prompt-path"
printf '%s' "$STEP8F" | grep -qi 'author an execution plan from the proposal prompt at' || M="$M no-objective-lead"
if printf '%s' "$STEP8" | grep -qE 'implementation-plan +[^ ]+\.md'; then M="$M bare-md-token"; fi
# The chain reads whatever Step 8 reports, so build/ must expect a prompt too.
printf '%s' "$(cat "$BUILD" | flat)" | grep -qi 'proposal prompt at <prompt path>' || M="$M chain-not-updated"
[ -z "$M" ] && echo "  PASS" || fail "Step 8 handoff:$M"

echo "7. Tier behaviour survives: Tier 0 writes nothing, Tier 1 omits unpopulated slots..."
# build/SKILL.md falls through to direct plan authoring precisely when the
# proposal stage produces no artifact; a Tier 0 run that wrote a file would
# silently break that fall-through.
BPF="$(cat "$BP" | flat)"
M=""
printf '%s' "$BPF" | grep -qi 'Tier 0 writes no artifact of either kind' || M="$M tier0-writes-nothing"
printf '%s' "$BPF" | grep -qi 'omits the unpopulated slots rather than emitting them empty' || M="$M tier1-no-empty-slots"
printf '%s' "$(cat "$BUILD" | flat)" | grep -qi 'No proposal written' || M="$M fallthrough-lost"
for s in '{{CONTEXT}}' '{{CORE_FINDING}}' '{{OPEN_QUESTIONS}}' '{{CORE_INSTRUCTION}}'; do
  printf '%s' "$BPF" | grep -qF "$s" || M="$M tier1-subset:$s"
done
[ -z "$M" ] && echo "  PASS" || fail "tier behaviour:$M"

echo "8. The gallery can see the new type: five filter chips and tolerant frontmatter..."
GF="$(cat "$GALLERY" "${GALLERY_REFS[@]}" | flat)"
M=""
for t in task system creative analytical proposal; do
  printf '%s' "$GF" | grep -qF "\`$t\`" || M="$M chip:$t"
done
printf '%s' "$GF" | grep -qi 'unrecognized key is not an error' || M="$M frontmatter-not-tolerant"
[ -z "$M" ] && echo "  PASS" || fail "prompt-artifact gallery:$M"

echo "9. No build-proposal file advertises a bare .md handoff (conversion-mode trap)..."
if grep -rqE 'implementation-plan +[^ ]+\.md' "$BP_DIR"; then
  grep -rnE 'implementation-plan +[^ ]+\.md' "$BP_DIR" | sed 's/^/    /'
  fail "a bare '.md' first token drops implementation-plan into conversion mode"
else
  echo "  PASS"
fi

echo "10. The canonical proposal shape maps onto the prompt slots without loss..."
M=""
grep -qi 'Section-to-slot mapping' "$SHAPE" || M="$M no-mapping-table"
# Every canonical section needs a destination, or content is dropped silently on
# the way into the authoritative artifact.
for s in TLDR CONTEXT CORE_FINDING COMPARISON_TABLE LOCKED_DECISIONS WORKSTREAMS \
         RISKS OPEN_QUESTIONS ROADMAP APPENDICES CORE_INSTRUCTION; do
  grep -qF "{{$s}}" "$SHAPE" || M="$M mapping:$s"
done
[ -z "$M" ] && echo "  PASS" || fail "section-to-slot mapping:$M"

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "Objective verified: build-proposal converges on a saved prompt authored by write-prompt."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
