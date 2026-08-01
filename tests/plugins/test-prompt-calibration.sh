#!/usr/bin/env bash
set -euo pipefail

# OBJECTIVE-VERIFICATION TEST
#
# Objective: the prompt skill applies the Claude 5 generation calibration, and
# that calibration is reachable from the skill core rather than orphaned.
#
# best-practices-reference.md shipped for several releases with no file in the
# skill linking it — the technique catalog existed and never loaded. Section 0
# is worth nothing under the same failure, so check 1 asserts the link before
# any check asserts the content. The remaining checks pin the three places the
# calibration has to bite: the drafting pass, and the two templates whose slots
# used to be mandatory.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PS="$ROOT/kit/plugins/plan-agent/skills/prompt"
SKILL="$PS/SKILL.md"
REF="$PS/references/best-practices-reference.md"
DRAFT="$PS/references/structuring-and-drafting.md"
SYS_TPL="$PS/references/system-prompt-template.md"
TASK_TPL="$PS/references/task-prompt-template.md"
FAILURES=0

# These files are hard-wrapped prose; flatten before asserting on a phrase.
flat() { tr '\n' ' ' | tr -s ' '; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== prompt skill — Claude 5 calibration (objective test) ==="

echo "1. The calibration is reachable: the skill core links the reference..."
# The regression this guards is silent — an unlinked reference file still lints,
# still greps, still reads correctly. Only a link from the core makes it load.
M=""
grep -qF 'references/best-practices-reference.md' "$SKILL" || M="$M core-does-not-link-reference"
# Phase 3 is where the layer decisions happen, so the link has to be in Phase 3
# rather than anywhere in the file.
P3="$(awk '/^## Phase 3/{f=1} /^## Phase 4/{f=0} f' "$SKILL")"
printf '%s' "$P3" | grep -qF 'best-practices-reference.md' || M="$M link-not-in-phase-3"
printf '%s' "$P3" | flat | grep -qF 'section 0' || M="$M phase-3-does-not-name-section-0"
[ -z "$M" ] && echo "  PASS" || fail "check 1:$M"

echo "2. Section 0 carries the five shifts and its source..."
S0="$(awk '/^## 0\./{f=1} /^## 1\./{f=0} f' "$REF")"
[ -n "$S0" ] || fail "check 2: section 0 missing entirely"
M=""
printf '%s' "$S0" | grep -qF 'claude.com/blog/the-new-rules-of-context-engineering' \
  || M="$M no-source-link"
# One row per shift. A section that drops a row silently reverts that rule.
for shift in 'judgment' 'interface design' 'progressive disclosure' 'one source' 'rich references'; do
  printf '%s' "$S0" | grep -qiF "$shift" || M="$M shift:$shift"
done
# The obsolete list is the operative half — it is what a draft must stop doing.
for gone in 'guardrails' 'examples' 'Repeating' 'system prompt'; do
  printf '%s' "$S0" | grep -qF "$gone" || M="$M obsolete:$gone"
done
[ -z "$M" ] && echo "  PASS" || fail "check 2:$M"

echo "3. Section 0 is stated once — the drafting rules point at it, not copy it..."
# "Repetition -> single authoritative source" applied to the skill's own files.
# A second copy of the shift table drifts from the first and the skill then
# carries two versions of the same rule.
M=""
grep -qF 'best-practices-reference.md' "$DRAFT" || M="$M draft-does-not-point-at-reference"
grep -qiF 'Then | Now' "$DRAFT" && M="$M shift-table-duplicated-into-draft"
# The three draft-time rules only bite on an assembled draft, so they belong
# here rather than in the catalog.
DF="$(flat < "$DRAFT")"
printf '%s' "$DF" | grep -qiF 'duplicated instruction' || M="$M no-dedupe-rule"
printf '%s' "$DF" | grep -qiF 'higher-fidelity artifact' || M="$M no-fidelity-rule"
[ -z "$M" ] && echo "  PASS" || fail "check 3:$M"

echo "4. The templates stopped treating their slots as quotas..."
# Both templates still ship every slot; what changed is that filling them is no
# longer mandatory. Asserting the slots still exist catches an over-correction
# that deletes the capability instead of making it optional.
M=""
SF="$(flat < "$SYS_TPL")"
grep -qF '{{GUARDRAIL_2}}' "$SYS_TPL" || M="$M system-lost-guardrail-slot"
printf '%s' "$SF" | grep -qiF 'optional' || M="$M system-constraints-still-mandatory"
printf '%s' "$SF" | grep -qiF 'drop the whole block' || M="$M system-no-drop-instruction"
TF="$(flat < "$TASK_TPL")"
grep -qF '{{EXAMPLE_INPUT}}' "$TASK_TPL" || M="$M task-lost-example-slot"
grep -qF '{{REASONING_STEP_1}}' "$TASK_TPL" || M="$M task-lost-thinking-slot"
printf '%s' "$TF" | grep -qiF 'are optional' || M="$M task-blocks-still-mandatory"
printf '%s' "$TF" | grep -qiF 'invented reasoning steps' || M="$M task-no-filler-warning"
[ -z "$M" ] && echo "  PASS" || fail "check 4:$M"

echo "5. The calibration reaches the draft without a second hop..."
# File references stay one level deep (skill-authoring checklist). Phase 3 links
# the reference; the reference must not then punt to a further file for the
# rules themselves, or the run needs two reads to learn what it must apply.
M=""
printf '%s' "$S0" | grep -qE '\[[^]]+\]\((\.\./|references/)' \
  && M="$M section-0-defers-to-another-file"
# Non-empty rules, not just headings: the shift table plus the obsolete list.
[ "$(printf '%s' "$S0" | grep -c '^| ')" -ge 6 ] || M="$M shift-table-has-no-rows"
[ "$(printf '%s' "$S0" | grep -c '^- \*\*')" -ge 4 ] || M="$M obsolete-list-too-short"
[ -z "$M" ] && echo "  PASS" || fail "check 5:$M"

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "Objective verified: the Claude 5 calibration ships, is linked from Phase 3, and is stated once."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
