#!/usr/bin/env bash
set -euo pipefail

# Unit coverage for prompt's fifth `proposal` prompt type
# (docs/plans/refactor-build-proposal-to-emit-prompt.md, steps 3-5).
# Asserts the type is wired through every phase that branches on type, that the
# caller-supplied --out contract and the in-place rewrite rule are documented,
# and that the template carries all 11 slots. The drift-detection snippet is
# additionally *executed*, not just grepped — a hash rule that does not
# discriminate is worse than no rule, since it trains the user to click through
# the confirmation.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/plan-agent/skills/prompt/SKILL.md"
TEMPLATE="$ROOT/kit/plugins/plan-agent/skills/prompt/references/proposal-prompt-template.md"
WRAPPER="$ROOT/kit/plugins/plan-agent/commands/prompt.md"
FAILURES=0

SLOTS="TLDR CONTEXT CORE_FINDING COMPARISON_TABLE LOCKED_DECISIONS WORKSTREAMS RISKS OPEN_QUESTIONS ROADMAP APPENDICES CORE_INSTRUCTION"

# Phase bodies, so a rule cannot pass by living in the wrong phase.
phase() { sed -n "/^## Phase $1 —/,/^## Phase $(( $1 + 1 )) —/p" "$SKILL"; }
# SKILL.md is hard-wrapped, so any prose assertion spanning more than a few words
# must run against a flattened copy or it fails on where the line happens to break.
flat() { tr '\n' ' ' | tr -s ' '; }

echo "=== prompt proposal-type Unit Test ==="

echo "1. The command wrapper loads the skill body by path, without self-delegating..."
# The command and the skill share the name `plan-agent:prompt`, and the
# COMMAND wins in the Skill namespace. A wrapper that delegates with
# Skill(skill: "plan-agent:prompt") — the shape commands/deep-grill.md uses
# — therefore returns itself, and SKILL.md's seven phases never load. Verified by
# probe: that wrapper yielded 0 "## Phase" headings; loading by path yields 7.
# So the wrapper must Read the skill file, not call its own name.
MISSING=""
[ -f "$WRAPPER" ] || MISSING="$MISSING wrapper-file"
if [ -f "$WRAPPER" ]; then
  WF="$(cat "$WRAPPER" | flat)"
  printf '%s' "$WF" | grep -qF 'skills/prompt/SKILL.md' || MISSING="$MISSING no-skill-path"
  printf '%s' "$WF" | grep -qi 'do \*\*not\*\* call `Skill(skill: "plan-agent:prompt")`' \
    || MISSING="$MISSING no-loop-warning"
  printf '%s' "$WF" | grep -qi 'shadows the skill' || MISSING="$MISSING shadowing-unexplained"
  printf '%s' "$WF" | grep -qF 'allowed-tools: Read' || MISSING="$MISSING read-not-allowed"
  # The wrapper must scope Bash the same way the skill does (Bash(git *),
  # Bash(mkdir *), Bash(awk *), Bash(shasum *)) — a bare "Bash" token here would
  # grant the wrapper broader shell access than SKILL.md itself declares.
  ATLINE="$(awk '/^allowed-tools:/{f=1; print; next} f && /^[A-Za-z-]+:/{f=0} f' "$WRAPPER" | flat)"
  if printf '%s' "$ATLINE" | grep -qE '(^|, )Bash(,|$)'; then
    MISSING="$MISSING unscoped-bash"
  fi
  for scope in 'Bash(git *)' 'Bash(mkdir *)' 'Bash(awk *)' 'Bash(shasum *)'; do
    printf '%s' "$ATLINE" | grep -qF "$scope" || MISSING="$MISSING missing-scope:$scope"
  done
  WLINES="$(wc -l < "$WRAPPER" | tr -d ' ')"
  [ "$WLINES" -le 20 ] || MISSING="$MISSING wrapper-too-long($WLINES)"
fi
# The wrapper is the workaround for the flag, not a reason to remove it —
# dropping it would re-enable ambient activation on every mention of "prompt".
grep -q '^disable-model-invocation: true$' "$SKILL" || MISSING="$MISSING disable-model-invocation-dropped"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "2. Phase 1 declares the fifth type in both the type table and the technique matrix..."
P1="$(phase 1)"
P1F="$(phase 1 | flat)"
MISSING=""
printf '%s' "$P1" | grep -qE '^\| \*\*proposal\*\*' || MISSING="$MISSING type-table-row"
printf '%s' "$P1" | grep -qE '^\| proposal +\|' || MISSING="$MISSING technique-matrix-row"
printf '%s' "$P1F" | grep -qi 'five types' || MISSING="$MISSING type-count-stale"
# The clarify menu must not offer it: proposal is caller-driven, and a user who
# picks it by hand has no proposal content to populate the slots with.
printf '%s' "$P1F" | grep -qi 'never offer `proposal` in that menu' || MISSING="$MISSING clarify-menu-exclusion"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: Phase 1 wiring incomplete:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "3. Phase 2 documents the pre-gathered-answers bypass and its skip condition..."
P2="$(phase 2 | flat)"
MISSING=""
printf '%s' "$P2" | grep -qF -- '--answers-gathered' || MISSING="$MISSING bypass-token"
printf '%s' "$P2" | grep -qi 'zero' || MISSING="$MISSING zero-questions-rule"
printf '%s' "$P2" | grep -qi 'build-proposal' || MISSING="$MISSING caller-named"
# Inferring the bypass would silently skip the interview for any content-rich
# invocation, which is every second one.
printf '%s' "$P2" | grep -qi 'never infer it' || MISSING="$MISSING no-inference-rule"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: Phase 2 bypass incomplete:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "4. Phase 3 maps the proposal sections onto XML layers..."
P3="$(phase 3)"
P3F="$(phase 3 | flat)"
MISSING=""
printf '%s' "$P3F" | grep -qi 'proposal grounding' || MISSING="$MISSING proposal-layer"
for tag in '<finding>' '<decisions>' '<open-questions>' '<appendices>'; do
  printf '%s' "$P3" | grep -qF "$tag" || MISSING="$MISSING layer:$tag"
done
# Summarizing a table or an appendix discards the grounded evidence the prompt
# exists to carry downstream.
printf '%s' "$P3F" | grep -qi 'verbatim' || MISSING="$MISSING passthrough-rule"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: Phase 3 mapping incomplete:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "5. Phase 4 selects the proposal template and the file resolves..."
P4="$(phase 4)"
if printf '%s' "$P4" | grep -qF 'references/proposal-prompt-template.md' && [ -f "$TEMPLATE" ]; then
  echo "  PASS"
else
  echo "  FAIL: template not selected in Phase 4, or the file is missing"
  FAILURES=$((FAILURES + 1))
fi

echo "6. Phase 7 honours --out over its own directory resolution and intent slug..."
P7="$(sed -n '/^## Phase 7 —/,$p' "$SKILL")"
P7F="$(sed -n '/^## Phase 7 —/,$p' "$SKILL" | flat)"
MISSING=""
printf '%s' "$P7F" | grep -qF -- '--out <path>' || MISSING="$MISSING out-flag"
printf '%s' "$P7F" | grep -qi 'no directory resolution' || MISSING="$MISSING skips-dir-resolution"
printf '%s' "$P7F" | grep -qi 'intent slug' || MISSING="$MISSING skips-intent-slug"
# Normalizing the path would reintroduce exactly the disagreement --out removes.
printf '%s' "$P7F" | grep -qi 'byte-for-byte' || MISSING="$MISSING exact-path-roundtrip"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: --out contract incomplete:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "6b. Phase 7 inserts the framing line the section-to-slot mapping promises..."
# artifact-shape.md's mapping table promises "H1 + fixed framing line" for the
# Title+framing section, but the template starts directly at <tldr>/<context>
# and the generic write-the-file block only adds the H1 — so without an
# explicit proposal-type insertion rule every authoritative prompt silently
# drops the "this is a proposal, not an execution plan" signal. Caught by
# review, reproduced against real generated output (three probe runs, zero
# framing blockquotes).
SHAPE="$ROOT/kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md"
MISSING=""
printf '%s' "$P7F" | grep -qi 'fixed framing line' || MISSING="$MISSING framing-rule-missing"
printf '%s' "$P7F" | grep -qi 'not an execution plan' || MISSING="$MISSING framing-text-missing"
printf '%s' "$P7F" | grep -qi 'not a substituted slot' || MISSING="$MISSING framing-not-a-slot-stated"
grep -qi 'fixed framing line' "$SHAPE" || MISSING="$MISSING shape-mapping-unmatched"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: framing-line contract incomplete:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "7. Phase 7 records status/modified/generated-sha and rewrites the proposal file in place..."
MISSING=""
for k in 'status:' 'modified:' 'generated-sha:'; do
  printf '%s' "$P7" | grep -qF "$k" || MISSING="$MISSING key:$k"
done
printf '%s' "$P7" | grep -qi 'gathering' || MISSING="$MISSING status-gathering"
printf '%s' "$P7" | grep -qi 'converged' || MISSING="$MISSING status-converged"
printf '%s' "$P7F" | grep -qi 'in-place rewrite' || MISSING="$MISSING rewrite-rule"
printf '%s' "$P7F" | grep -qi 'replaces the uniqueness guard' || MISSING="$MISSING guard-replacement"
printf '%s' "$P7" | grep -qF 'proposal-{slug}.md' || MISSING="$MISSING date-free-filename"
# Anchoring the drift check to git would fire on every uncommitted round, since
# build-proposal only *offers* to commit.
printf '%s' "$P7F" | grep -qi 'rather than to a git baseline' || MISSING="$MISSING sha-not-git-baseline"
printf '%s' "$P7" | grep -qi 'AskUserQuestion' || MISSING="$MISSING confirmation-prompt"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: living-document contract incomplete:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "8. The documented drift-detection command actually discriminates..."
# Proves the hash rule discriminates. Three cases: an untouched file must hash
# equal (no confirmation), a hand-edited body must differ (fires), and a
# frontmatter-only change must NOT fire — the rule hashes the body, and a
# `modified:` bump is written by the skill itself on every round.
#
# The hash program below is a FIXED LITERAL, never `eval`/`bash -c` on text read
# out of SKILL.md: sourcing a shell command from a Markdown file would make
# editing documentation a way to run arbitrary code in anyone's test run. The
# link to the docs is kept by string-comparing the documented snippet against
# this literal, so the two cannot drift apart without failing.
EXPECTED_BODYHASH="awk 'f{print} /^---\$/{n++; if(n==2) f=1}' \"\$FILE\" | shasum -a 256 | cut -d' ' -f1"
BODYHASH="$(sed -n "/^# body hash/,/^\`\`\`$/p" "$SKILL" | sed -n '2p')"
if [ -z "$BODYHASH" ]; then
  echo "  FAIL: the body-hash command block is missing from Phase 7"
  FAILURES=$((FAILURES + 1))
elif [ "$BODYHASH" != "$EXPECTED_BODYHASH" ]; then
  echo "  FAIL: Phase 7's documented body-hash command drifted from the one this test verifies"
  echo "    documented: $BODYHASH"
  echo "    verified  : $EXPECTED_BODYHASH"
  FAILURES=$((FAILURES + 1))
else
  TMPD="$(mktemp -d)"
  trap 'rm -rf "$TMPD"' EXIT
  FILE="$TMPD/proposal-adopt-design-md.md"
  cat > "$FILE" <<'MDEOF'
---
type: proposal
status: gathering
created: 2026-07-27
modified: 2026-07-27
generated-sha: pending
---

# Proposal: adopt design md

<context>
Two token formats, both hand-edited.
</context>
MDEOF
  # Fixed literal, kept in step with the docs by the comparison above.
  hash_of() {
    awk 'f{print} /^---$/{n++; if(n==2) f=1}' "$1" | shasum -a 256 | cut -d' ' -f1
  }
  H1="$(hash_of "$FILE")"
  H_AGAIN="$(hash_of "$FILE")"
  # frontmatter-only churn: the skill rewrites `modified:` itself every round
  sed -i.bak 's/^modified: .*/modified: 2026-07-28/' "$FILE" && rm -f "$FILE.bak"
  H_FM="$(hash_of "$FILE")"
  # a real hand edit to the body
  printf '\nHand-added by a human.\n' >> "$FILE"
  H_EDIT="$(hash_of "$FILE")"
  MISSING=""
  [ -n "$H1" ] || MISSING="$MISSING empty-hash"
  [ "$H1" = "$H_AGAIN" ] || MISSING="$MISSING unstable-on-untouched-file"
  [ "$H1" = "$H_FM" ] || MISSING="$MISSING fires-on-frontmatter-only-change"
  [ "$H1" != "$H_EDIT" ] || MISSING="$MISSING blind-to-body-edit"
  if [ -z "$MISSING" ]; then
    echo "  PASS"
  else
    echo "  FAIL: drift detection does not discriminate:$MISSING"
    FAILURES=$((FAILURES + 1))
  fi
fi

echo "9. The template carries all 11 slots in both the template block and the guide..."
TPL_BLOCK="$(sed -n '/^## Template/,/^## Placeholder Guide/p' "$TEMPLATE")"
GUIDE="$(sed -n '/^## Placeholder Guide/,/^## Assembled Example/p' "$TEMPLATE")"
MISSING=""
for s in $SLOTS; do
  printf '%s' "$TPL_BLOCK" | grep -qF "{{$s}}" || MISSING="$MISSING template:$s"
  printf '%s' "$GUIDE" | grep -qE "^\| $s \|" || MISSING="$MISSING guide:$s"
done
if [ -z "$MISSING" ]; then
  echo "  PASS (11 slots)"
else
  echo "  FAIL: slot coverage incomplete:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "10. The assembled example is fully substituted and documents the Tier 1 subset..."
EXAMPLE="$(sed -n '/^## Assembled Example/,$p' "$TEMPLATE")"
MISSING=""
if printf '%s' "$EXAMPLE" | grep -qF '{{'; then
  MISSING="$MISSING unsubstituted-placeholder"
fi
for s in CONTEXT CORE_FINDING OPEN_QUESTIONS CORE_INSTRUCTION; do
  grep -qF "{{$s}}" "$TEMPLATE" || MISSING="$MISSING tier1-slot:$s"
done
grep -qi 'never emit an empty heading' "$TEMPLATE" || MISSING="$MISSING no-empty-headings-rule"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: assembled example or Tier 1 subset incomplete:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All prompt proposal-type checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
