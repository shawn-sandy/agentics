---
status: completed
type: feature
created: 2026-08-19
modified: 2026-08-19
repo-name: agentics
glance: Usage analysis found the top friction is first implementations shipping with real defects — no-op edits, vacuous test assertions, self-introduced regressions, unsafe auth lookups — caught only by PR review bots at 2-6 rounds per PR. This adds a mandatory single-pass adversarial review of the branch diff to every git-agent flow that opens a PR, run in a fresh-context subagent where the flow can spawn one and as an inline cold re-read where it cannot, so the bots find nothing.
effort: small
workflow: never
---

# Add Pre-PR Adversarial Review

## context

The 2026-08 usage analysis ranks bots-as-QA as the #1 friction: first
implementations ship with provable defects (no-op edits, vacuous test
assertions, self-introduced regressions, unsafe auth/role/key lookups) that
only get caught by PR review bots, costing 2–6 review rounds per PR. The
author of a diff is the worst-placed reviewer of it — knowing what an edit was
*meant* to do makes a no-op edit read like a fix — so the review must run in a
context with no memory of the implementation.

## objective

Every git-agent flow that opens a PR runs a single-pass adversarial review of
`git diff <base>...HEAD` before `gh pr create` — fresh-context subagent in the
interactive skills, inline cold re-read in the background agents — against one
shared six-point checklist.

## steps

1. **`skills/pr-agent/SKILL.md`** — new Step 4.7 spawning the review subagent
   (`code-review:agent-code-reviewer`, else `general-purpose`); confirmed
   findings become a `fix:` commit + re-push (post-push, so never amend);
   unconfirmed ones go in the body's `## Review Notes`; `Agent` added to
   `allowed-tools`. *Verify:* Step 4.7 sits between Step 4.5 and Step 5.
2. **`skills/ship/SKILL.md` + `references/self-review.md`** — Step 4.5
   upgraded from the four-check inline list to the subagent dispatch and
   six-point checklist; amend-before-push procedure kept; `--no-review`
   opt-out kept. *Verify:* reference names the dispatch, checklist, and amend
   procedure.
3. **`skills/ship-autonomous/SKILL.md`** — opens its PR by invoking
   `pr-agent`, so it inherits Step 4.7; Step 4 names the review instead of
   duplicating it (the core sits at the split test's 600-word ceiling, and one
   review per PR is the point). *Verify:* Step 4 names the adversarial review;
   `test-skill-split-git-social.sh` stays green.
4. **`agents/agent-pr.md`, `agents/agent-ship.md`** — inline report-only
   variant (no Agent tool, `disallowedTools` denies edits): cold re-read with
   the same checklist, findings in `## Review Notes` and the final report;
   a proven secret stops the flow and is never named in a PR body.
   *Verify:* both carry the six checks; report-only framing intact.
5. **Housekeeping** — marketplace.json 4.19.2 → 4.19.3, CHANGELOG v4.19.3
   entry, this plan file. *Verify:* `BASE_REF=main node
   scripts/check-plugin-versions.mjs` passes.

## tests

**Objective-verification test** — `bash tests/run-all.sh`: the existing plugin
guard suite (ExitPlanMode guard, verification-gate rule, shell-expansion
ledger) run against the edited skill and agent files, plus a grep that each of
the five touched flows names the adversarial review before its PR-create step.

## acceptance-criteria

- [x] All five PR-opening flows run the review before `gh pr create`;
      commit-agent, branch-agent, merge, post-merge-cleanup, agent-commit,
      agent-merge, and agent-ship-ci are untouched.
- [x] Interactive skills use a fresh-context subagent; background agents use
      an inline cold re-read; both share the six-point checklist verbatim.
- [x] Single pass everywhere — no flow loops the review.
- [x] git-agent version exceeds origin/main with a changelog entry.

## verification

`bash tests/run-all.sh` + `BASE_REF=main node scripts/check-plugin-versions.mjs`
+ `python3 -c "import json; json.load(open('.claude-plugin/marketplace.json'))"`
— all green before the PR opens.
