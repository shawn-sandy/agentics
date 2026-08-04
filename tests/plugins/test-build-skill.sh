#!/usr/bin/env bash
set -euo pipefail

# Smoke test for the `build` skill: it exists, ships (is not gitignored), is
# well-formed, owns the three implementation gates, and implementation-plan
# delegates to it instead of carrying a second copy of the loop.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL_DIR="$ROOT/kit/plugins/plan-agent/skills/build"
SKILL="$SKILL_DIR/SKILL.md"
IMPL="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/SKILL.md"
MARKETPLACE="$ROOT/.claude-plugin/marketplace.json"
FAILURES=0

echo "=== build Skill Smoke Test ==="

if [ ! -f "$SKILL" ]; then
  echo "FATAL: $SKILL does not exist — every check below would cascade."
  exit 1
fi

# The skill is progressively disclosed: SKILL.md is a small core and the moved
# sections live in references/*.md beside it. Every assertion below is about the
# skill's contract, not about which file happens to carry it, so the extractors
# resolve the owning file first. references/ is searched ahead of the core
# because the core keeps a same-named summary heading pointing at each one — the
# file that carries the *section* is the reference, and that is what must be
# checked. Nothing here relaxes what is required: only where it is looked for.
SKILL_FILES=()
for f in "$SKILL_DIR"/references/*.md "$SKILL"; do
  [ -f "$f" ] && SKILL_FILES+=("$f")
done
ALLTEXT="$(cat "${SKILL_FILES[@]}")"

owner() { # owner <start-regex> — the file carrying that heading, core as fallback
  local pat="$1" f
  for f in "${SKILL_FILES[@]}"; do
    if grep -qE "$pat" "$f"; then printf '%s' "$f"; return 0; fi
  done
  printf '%s' "$SKILL"
}

section() { # section <start-regex> <end-regex> — extract from the owning file
  sed -n "/$1/,/$2/p" "$(owner "$1")"
}

echo "1. SKILL.md exists with name: build..."
if grep -q "^name: build$" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: missing name line"
  FAILURES=$((FAILURES + 1))
fi

echo "2. The skill is tracked by git (it must actually ship)..."
# Regression guard: an unanchored `build/` in .gitignore silently excluded this
# whole directory, so every local test passed while the skill was never
# committed and never reached the published dist. `check-ignore` alone does not
# express that — it passes for an untracked-and-unignored file, which is the
# broken state. Tracked-ness is the invariant; check-ignore only explains why
# when it fails. (build-dist.mjs copies from the filesystem, so a local dist
# build is not evidence: only the git path reveals this.)
if git -C "$ROOT" ls-files --error-unmatch "$SKILL" >/dev/null 2>&1; then
  echo "  PASS"
else
  echo "  FAIL: $SKILL is not tracked by git — it would not reach the published dist."
  if git -C "$ROOT" check-ignore -q "$SKILL" 2>/dev/null; then
    echo "        cause: $(git -C "$ROOT" check-ignore -v "$SKILL")"
  else
    echo "        cause: not ignored, just never 'git add'ed."
  fi
  FAILURES=$((FAILURES + 1))
fi

echo "3. description is three-part (<=200 total, first sentence <=80, 'Use when')..."
if python3 - "$SKILL" <<'PY'
import re, sys
# Tolerant of unquoted and single-quoted YAML, like tests/plugins/test-build-proposal.sh.
m = re.search(r'^description:\s*"?(.*?)"?\s*$', open(sys.argv[1]).read(), re.M)
if not m:
    sys.exit(1)
d = m.group(1)
s = re.search(r"(?<=[.!?])\s", d)
first = len(d[: s.start()] if s else d)
sys.exit(0 if len(d) <= 200 and first <= 80 and "use when" in d.lower() else 1)
PY
then
  echo "  PASS"
else
  echo "  FAIL: description must be <=200 total, first sentence <=80, and contain 'Use when'"
  FAILURES=$((FAILURES + 1))
fi

echo "4. allowed-tools declares ToolSearch and ExitPlanMode (deferred-tool bootstrap)..."
ATLINE="$(grep -m1 '^allowed-tools:' "$SKILL" || true)"
if echo "$ATLINE" | grep -qw ToolSearch && echo "$ATLINE" | grep -qw ExitPlanMode \
  && grep -qF '**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.' "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: ToolSearch/ExitPlanMode missing from allowed-tools or the body bootstrap"
  FAILURES=$((FAILURES + 1))
fi

echo "5. Body carries all three gates plus the re-render command..."
if grep -q "Acceptance criteria gate" "$SKILL" \
  && grep -q "End-to-end verification gate" "$SKILL" \
  && grep -q "Completion checklist gate" "$SKILL" \
  && grep -q "plan-agent-render" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: a gate heading or the re-render command is missing"
  FAILURES=$((FAILURES + 1))
fi

echo "6. Spec-is-source-of-truth rules survived the lift, in their owning sections..."
# Each of these was an explicit instruction in the block that moved. Checking
# the whole file was too weak: a mutation that replaced all five rules and
# appended a decoy paragraph containing the phrases still passed. Each pattern
# is therefore scoped to the section that must carry it.
# Newlines squeezed to spaces: this file is hard-wrapped, so any phrase longer
# than a few words can straddle a line break and defeat line-based grep.
flatten() { tr '\n' ' ' | tr -s ' '; }
SOT="$(section '^\*\*The markdown spec is the source of truth' '^## Invocation' | flatten)"
GATES="$(section '^## Step 3 —' '^## Step 6 —' | flatten)"
MISSING=""
printf '%s' "$GATES" | grep -q 'flip back to `- \[ \]`' || MISSING="$MISSING undo-rule"
printf '%s' "$SOT" | grep -qi "browser-only persistence" || MISSING="$MISSING browser-persistence-ban"
printf '%s' "$GATES" | grep -qi "delete the section" || MISSING="$MISSING completion-report-teardown"
printf '%s' "$GATES" | grep -qi "three status representations" || MISSING="$MISSING status-representations"
printf '%s' "$GATES" | grep -qi "no per-card run command" || MISSING="$MISSING per-card-run-note"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: lifted rules missing from their sections in build/SKILL.md:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "7. status: completed is gated behind end-to-end verification, not the criteria gate..."
if printf '%s' "$ALLTEXT" | grep -q 'Do not set `status: completed` here'; then
  echo "  PASS"
else
  echo "  FAIL: the criteria gate does not forbid marking completed before Step 4 runs"
  FAILURES=$((FAILURES + 1))
fi

echo "8. implementation-plan delegates and carries no second copy of any gate..."
# Looks for the gate *heading* form ("<name> gate (mandatory"), not any mention:
# the delegation prose legitimately names the gates it hands off, and an
# any-mention grep turned that sentence into three false positives. Newlines are
# squeezed to spaces first because this file is hard-wrapped at ~72 columns, so
# a re-inlined heading can straddle a line break.
FLAT="$(tr '\n' ' ' < "$IMPL" | tr -s ' ')"
DUPES=""
for gate in "acceptance criteria gate (mandatory" "end-to-end verification gate (mandatory" "completion checklist gate (mandatory"; do
  printf '%s' "$FLAT" | grep -qi "$gate" && DUPES="$DUPES [$gate]"
done
if grep -q 'Skill(skill: "plan-agent:build"' "$IMPL" && [ -z "$DUPES" ]; then
  echo "  PASS"
else
  echo "  FAIL: missing delegation, or implementation-plan re-inlined gates:$DUPES"
  FAILURES=$((FAILURES + 1))
fi

echo "9. marketplace.json is valid JSON and its plan-agent description names every shipped skill..."
# Structural, not lexical: the invariant is "every skill directory is
# discoverable in the blurb the marketplace surfaces", so a copy-edit that
# rewords the build clause does not turn this red. The version-regression guard
# deliberately lives in scripts/check-plugin-versions.mjs instead — that one is
# PR-gated and compares against origin/main properly.
if python3 - "$MARKETPLACE" "$ROOT" <<'PY'
import json, os, sys
doc = json.load(open(sys.argv[1]))          # raises on malformed JSON
entry = [p for p in doc["plugins"] if p["name"] == "plan-agent"][0]
desc = entry["description"]
skills = sorted(
    d for d in os.listdir(os.path.join(sys.argv[2], "kit/plugins/plan-agent/skills"))
    if not d.startswith(".")
)
missing = [s for s in skills if s not in desc]
if missing:
    print("  missing from description:", ", ".join(missing))
sys.exit(1 if missing else 0)
PY
then
  echo "  PASS"
else
  echo "  FAIL: marketplace.json is malformed, or its plan-agent description omits a shipped skill"
  FAILURES=$((FAILURES + 1))
fi

# --- No-plan chain (Step 1b) -------------------------------------------------
# Every behaviour below is prose in a hard-wrapped markdown file, so each check
# scopes its greps to the section that must carry the rule — the same technique
# check 6 uses, and for the same reason: a file-wide grep passed against a
# mutation that deleted all five rules it guarded and appended a decoy.
STEP1="$(section '^## Step 1 — Resolve the plan' '^## Step 1b —' | flatten)"
CHAIN="$(section '^## Step 1b —' '^## Step 2 —' | flatten)"
INVOKE="$(section '^## Invocation' '^## Step 0' | flatten)"

echo "10. Step 1b carries the chain and delegates to both authoring skills..."
MISSING=""
[ -n "$CHAIN" ] || MISSING="$MISSING step-1b-section"
printf '%s' "$CHAIN" | grep -qF 'Skill(skill: "plan-agent:build-proposal"' || MISSING="$MISSING build-proposal-call"
printf '%s' "$CHAIN" | grep -qF 'Skill(skill: "plan-agent:implementation-plan"' || MISSING="$MISSING implementation-plan-call"
printf '%s' "$CHAIN" | grep -qi 'objective check' || MISSING="$MISSING objective-check-first"
printf '%s' "$CHAIN" | grep -qi 'proposal-versus-direct gate' || MISSING="$MISSING proposal-gate"
printf '%s' "$CHAIN" | grep -qi 'by path' || MISSING="$MISSING return-by-path"
# build-proposal answers a Tier 0 idea directly and writes no document, so the
# chain must have somewhere to go when the proposal stage produces no artifact.
printf '%s' "$CHAIN" | grep -qi 'No proposal written' || MISSING="$MISSING tier0-no-artifact-fallthrough"
# --dir names where the *plan* goes, so the proposal branch must forward it to
# implementation-plan even though it withholds it from build-proposal.
printf '%s' "$CHAIN" | grep -qi 'is forwarded here' || MISSING="$MISSING dir-not-forwarded-to-plan-authoring"
# Since plan-agent 6.0.0 build-proposal converges on a saved prompt, not a
# proposal doc. The chain interpolates whatever it reports without parsing it, so
# a stale artifact name here silently chains a path that was never written.
#
# Since 8.5.0 that path travels behind `--from-prompt` rather than inside prose
# ("...proposal prompt at <prompt path>"). implementation-plan scans positional
# arguments for a `.md` suffix and treats the first hit as a CONVERSION source,
# anywhere in the string — so the prose form silently restructured the proposal
# into a plan whose steps restated its headings. The chain's own prose guard
# ("never a bare `.md` first token") could not prevent that, because the scan was
# never limited to the first token. A flag value is not a positional token, so
# the flag form is the fix. Asserting the flag rather than the placeholder alone
# is what keeps a revert to prose from passing.
printf '%s' "$CHAIN" | grep -qF -- '--from-prompt <prompt path>' || MISSING="$MISSING prompt-path-chained-behind-flag"
if printf '%s' "$CHAIN" | grep -qi 'from the proposal at <'; then
  MISSING="$MISSING stale-proposal-doc-path"
fi
# The prose handoff is the conversion-mode bug itself. Fail on its return even if
# `--from-prompt` is also present somewhere, since the first `.md`-suffixed
# positional token still wins the scan.
if printf '%s' "$CHAIN" | grep -qi 'proposal prompt at <prompt path>'; then
  MISSING="$MISSING prompt-path-as-bare-positional"
fi
# Both Step 1b paths forward --type, or a plan authored through the chain gets
# its type inferred from a leading verb that belongs to the chain's own wording
# ("author an execution plan...") rather than to the user's objective — which
# resolved to `chore` for every proposal-path plan before 8.5.0.
# `flatten` collapses the section to a single line, so `grep -c` would cap at 1
# and pass on one mention. Count occurrences, not matching lines.
[ "$(printf '%s' "$CHAIN" | grep -o -- '--type' | wc -l)" -ge 2 ] || MISSING="$MISSING type-not-forwarded-on-both-paths"
# Tier 0 writes neither artifact, and the abandonment contract must cover both.
printf '%s' "$CHAIN" | grep -qi 'no artifact of either kind' || MISSING="$MISSING tier0-neither-artifact"
printf '%s' "$CHAIN" | grep -qi 'leave \*\*both\*\* artifacts in place' || MISSING="$MISSING abandonment-covers-both"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: Step 1b chain incomplete in build/SKILL.md:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "11. Discovery is an offer, capped at three, and skipped when an objective is given..."
MISSING=""
printf '%s' "$STEP1" | grep -qi 'offer, never a silent pickup' || MISSING="$MISSING offer-not-pickup"
printf '%s' "$STEP1" | grep -qF 'None of these — author a new plan' || MISSING="$MISSING author-new-option"
printf '%s' "$STEP1" | grep -qi 'at most the top three' || MISSING="$MISSING three-candidate-cap"
printf '%s' "$STEP1" | grep -qi 'how many were suppressed' || MISSING="$MISSING suppressed-count"
printf '%s' "$STEP1" | grep -qi 'skip discovery entirely' || MISSING="$MISSING objective-skips-discovery"
# The skip must be stated *before* the offer is described, or a reader following
# the branch top-to-bottom runs the offer with an objective in hand.
SKIP_AT="$(printf '%s' "$STEP1" | { grep -boi 'skip discovery entirely' || true; } | head -1 | cut -d: -f1)"
OFFER_AT="$(printf '%s' "$STEP1" | { grep -boi 'offer, never a silent pickup' || true; } | head -1 | cut -d: -f1)"
if [ -n "$SKIP_AT" ] && [ -n "$OFFER_AT" ] && [ "$SKIP_AT" -ge "$OFFER_AT" ]; then
  MISSING="$MISSING skip-stated-after-offer"
fi
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: discovery is not an objective-gated three-candidate offer:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "12. The dirty-tree guard runs ahead of resolution and the chain, other preconditions intact..."
# Compared against *resolution*, not against the Step 1b heading: the guard's old
# home — the check-before-writing preconditions — also sits above that heading,
# so a heading comparison passes with the guard un-hoisted. What must be true is
# that it fires before a plan is resolved and before any chain stage is invoked.
# All three land in whichever file carries Step 1 — the core's summary points at
# the reference, so the ordering has to be asserted inside that one file.
STEP1_FILE="$(owner '^## Step 1 — Resolve the plan')"
GUARD_LN="$(grep -n 'Dirty working tree' "$STEP1_FILE" | head -1 | cut -d: -f1 || true)"
RESOLVE_LN="$(grep -n '^Resolve the plans directory' "$STEP1_FILE" | head -1 | cut -d: -f1 || true)"
PRECOND_LN="$(grep -n '^\*\*Preconditions' "$STEP1_FILE" | head -1 | cut -d: -f1 || true)"
MISSING=""
if [ -z "$GUARD_LN" ] || [ -z "$RESOLVE_LN" ] || [ "$GUARD_LN" -ge "$RESOLVE_LN" ]; then
  MISSING="$MISSING guard-not-hoisted-above-resolution"
fi
if [ -n "$PRECOND_LN" ] && [ -n "$GUARD_LN" ] && [ "$GUARD_LN" -gt "$PRECOND_LN" ]; then
  MISSING="$MISSING guard-still-in-preconditions-block"
fi
printf '%s' "$STEP1" | grep -qi 'ahead of Step 1b' || MISSING="$MISSING guard-chain-ordering-unstated"
# The Step 8 callback re-enters this skill with the just-authored plan
# uncommitted; without an exclusion the hoisted guard fires at exactly the
# moment the hoist exists to avoid, and headless it stops the chain.
printf '%s' "$STEP1" | grep -qi 'never pre-existing work' || MISSING="$MISSING plan-artifacts-not-excluded"
printf '%s' "$STEP1" | grep -qi 'already `status: completed`' || MISSING="$MISSING completed-plan-precondition"
printf '%s' "$STEP1" | grep -qi 'resume from the first unmarked step' || MISSING="$MISSING resume-precondition"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: precondition placement wrong in build/SKILL.md:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "13. Every non-implementing Step 8 choice terminates the outer chain..."
# Both answers route execution elsewhere: proceeding would build work the user
# declined (Exit) or race the workflow they just launched (Run as workflow).
MISSING=""
printf '%s' "$CHAIN" | grep -qF "\`Exit — I'll implement later\` → **stop.**" || MISSING="$MISSING exit-stops"
printf '%s' "$CHAIN" | grep -qF '`Run as workflow` → **stop.**' || MISSING="$MISSING workflow-stops"
printf '%s' "$CHAIN" | grep -qi 'status: todo' || MISSING="$MISSING exit-leaves-todo"
# `Skill()` is synchronous: the nested build has already finished by the time
# control returns, so re-entering the preconditions would offer to redo work
# that just completed or restart a run the user chose to stop.
printf '%s' "$CHAIN" | grep -qiF '`Implement now` → **stop and report.**' || MISSING="$MISSING implement-now-not-terminal"
printf '%s' "$CHAIN" | grep -qi 're-enter Steps 1-2' || MISSING="$MISSING no-precondition-reentry"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: the chain's return path does not terminate on every non-implementing choice:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "14. build pins its model so a chained run does not inherit a planning skill's override..."
MODEL_PINS="$(grep -c '^model: opus$' "$SKILL" || true)"
if [ "$MODEL_PINS" -eq 1 ]; then
  echo "  PASS"
else
  echo "  FAIL: build/SKILL.md must carry exactly one 'model: opus' line"
  FAILURES=$((FAILURES + 1))
fi

echo "15. The objective-versus-path grammar rule is stated, misparse included..."
MISSING=""
echo "$ATLINE" | grep -qw Skill || MISSING="$MISSING allowed-tools-Skill"
grep -q '^argument-hint:.*<objective>' "$SKILL" || MISSING="$MISSING argument-hint-objective"
printf '%s' "$INVOKE" | grep -qi 'suffix' || MISSING="$MISSING suffix-rule"
# Without a flags-first pass, `--dir tmp/plans` classifies as an objective:
# the token carries neither a suffix nor a slash.
printf '%s' "$INVOKE" | grep -qi 'Parse flags first' || MISSING="$MISSING flags-not-parsed-first"
printf '%s' "$INVOKE" | grep -qi 'first positional token' || MISSING="$MISSING positional-token-rule"
printf '%s' "$INVOKE" | grep -qi 'misparse' || MISSING="$MISSING slash-misparse-note"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: the argument grammar does not distinguish an objective from a path:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "16. The two non-chaining no-plan branches still stop..."
# A mistyped filename must not author a whole plan, and an HTML-only legacy plan
# needs its spec reconstructed rather than a new plan written on top of it.
MISSING=""
printf '%s' "$STEP1" | grep -qi 'say which paths were tried' || MISSING="$MISSING missing-path-stop"
printf '%s' "$STEP1" | grep -qi 'mistyped filename' || MISSING="$MISSING typo-rationale"
printf '%s' "$STEP1" | grep -qi 'this skill edits specs, not HTML' || MISSING="$MISSING html-only-stop"
# Exactly one branch may route into the chain.
ENTER_REFUSALS="$(printf '%s' "$STEP1" | { grep -oi 'do not enter Step 1b' || true; } | wc -l | tr -d ' ')"
if [ "$ENTER_REFUSALS" -ne 2 ]; then
  MISSING="$MISSING both-branches-must-refuse-the-chain"
fi
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: a no-plan branch that must stop no longer does:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "17. The chain is command-only and the ambient route-away contract survives..."
MISSING=""
printf '%s' "$INVOKE" | grep -qi 'only from the slash command' || MISSING="$MISSING command-only-scoping"
ROUTE_AWAYS="$(printf '%s\n' "$ALLTEXT" | { grep -c 'stop and route to' || true; })"
[ "$ROUTE_AWAYS" -eq 1 ] || MISSING="$MISSING route-away-instruction"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: ambient activation scoping is wrong in build/SKILL.md:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "18. Gates stop rather than self-resolve when AskUserQuestion is unavailable..."
# Found by running the skill headless: with no AskUserQuestion, one run adopted
# the lone discovery candidate ("it was the only one") and another stopped at the
# proposal gate — the same missing tool resolved two opposite ways, because the
# fallback was undefined. Silent adoption is the exact behaviour the offer exists
# to remove, so the rule has to be stated, not inferred.
FLATSKILL="$(printf '%s\n' "$ALLTEXT" | flatten)"
MISSING=""
printf '%s' "$FLATSKILL" | grep -qi 'AskUserQuestion` is unavailable' || MISSING="$MISSING unavailable-case-unstated"
printf '%s' "$FLATSKILL" | grep -qi 'stops and reports the choice' || MISSING="$MISSING no-stop-and-report-rule"
printf '%s' "$FLATSKILL" | grep -qi 'never resolve a gate by picking' || MISSING="$MISSING no-picking-ban"
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: the AskUserQuestion-unavailable fallback is not stated in build/SKILL.md:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "19. The typed entry commands prepend their default --type, so a user's wins..."
# `build` resolves a repeated --type LAST-WINS. A command that appends its
# default therefore beats the user's explicit value:
#   /plan-agent:fix task --type docs  ->  "task --type docs --type fix"  -> fix
# Prepending is what makes the advertised override real:
#   -> "--type fix task --type docs" -> docs
# Asserting the ORDER, not just the presence of both tokens, is the whole point:
# the appended form contains exactly the same two tokens and is silently wrong.
MISSING=""
CMD_DIR="$ROOT/kit/plugins/plan-agent/commands"
for pair in "fix.md:fix" "refactor.md:refactor"; do
  f="${pair%%:*}"; kind="${pair##*:}"
  p="$CMD_DIR/$f"
  if [ ! -f "$p" ]; then MISSING="$MISSING $f-missing"; continue; fi
  # The invoke line must read `--type <kind> $ARGUMENTS`, in that order.
  grep -qF -- "args: \"--type $kind \$ARGUMENTS\"" "$p" || MISSING="$MISSING $f-not-prepended"
  # And must not carry the appended form anywhere.
  if grep -qF -- "\$ARGUMENTS --type $kind" "$p"; then MISSING="$MISSING $f-appends-default"; fi
  # last-wins is the premise the ordering depends on; if build ever changes to
  # first-wins these files must flip too, so name the coupling here.
  grep -qi 'last-wins' "$p" || MISSING="$MISSING $f-omits-precedence-rationale"
done
# The docs must not contradict the commands. Fixing the two command files while
# leaving `append a default` in invocation.md and implementation-plan/SKILL.md is
# exactly what happened once: the code was right and two skill bodies still
# taught the inverted rule, which is the version a model actually reads.
for doc in \
  "$ROOT/kit/plugins/plan-agent/skills/build/references/invocation.md" \
  "$ROOT/kit/plugins/plan-agent/skills/implementation-plan/SKILL.md"; do
  if printf '%s' "$(cat "$doc" | flatten)" | grep -qiE 'append(ing)? a default'; then
    MISSING="$MISSING $(basename "$doc")-teaches-append"
  fi
done
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: typed entry commands mishandle --type precedence:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo "20. The conversion scan is defined as positional, excluding flag values..."
# "first non-flag token ending in .md" is not sufficient: `--from-prompt`'s value
# does not begin with `-`, so a literal reading still picks it up as a conversion
# source — which is the very bug --from-prompt exists to prevent. The rule has to
# exclude recognized flag VALUES, not merely tokens that look like flags.
IPSKILL="$ROOT/kit/plugins/plan-agent/skills/implementation-plan/SKILL.md"
IPFLAT="$(cat "$IPSKILL" | flatten)"
MISSING=""
printf '%s' "$IPFLAT" | grep -qi 'not a recognized flag' || MISSING="$MISSING flag-values-not-excluded"
printf '%s' "$IPFLAT" | grep -qi 'first \*\*positional\*\* token ending in' || MISSING="$MISSING scan-not-called-positional"
if printf '%s' "$IPFLAT" | grep -qi 'first non-flag token ending in `.md`'; then
  MISSING="$MISSING md-rule-still-says-non-flag"
fi
if [ -z "$MISSING" ]; then
  echo "  PASS"
else
  echo "  FAIL: the .md conversion scan is still ambiguous about flag values:$MISSING"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All build-skill checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi
