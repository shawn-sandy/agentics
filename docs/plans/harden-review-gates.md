---
status: completed
type: feature
created: 2026-08-21
modified: 2026-08-21
repo-name: agentics
---

# Harden Review Gates

## Context

The 2026-08-21 Claude Code insights report (`~/.claude/usage-data/report.html`,
4,736 messages over 652 sessions) named code-review response as the second-most
common session goal at 133 sessions, driven by 115 buggy-code friction events.
Its evidence points at four specific gaps in this marketplace:

1. The adversarial pre-PR review added in git-agent 4.19.3 checks six defect
   classes, but the five that actually escaped to bot reviewers in the observed
   sessions — pagination tie-breakers, unvalidated `parseInt`, stale derived
   state, timezone-dependent dates, and scripts that do not abort — are not
   among them. A grep for `tie-break`, `parseInt`, `timezone`, and
   `derived state` across `git-agent/` and `code-review/` returned zero hits.
2. Billing-block detection ("did any job dispatch at all?") lives only in
   `ship-autonomous/references/ci-autofix.md`. The `merge` skill reads checks
   thoroughly but never asks the question, and the report counts at least eight
   sessions spent re-diagnosing the same block.
3. Nothing verifies that the current checkout is current before work starts on
   it. The report's highest-rated moment was Claude refusing a deletion because
   the worktree was stale — caught by chance, not by a gate.
4. `team-defaults` ships `review-bot-loops.md` to other users, but the bundled
   copy has drifted behind the maintainer's own: it is missing the Hard default,
   the whole Triage section (including "drop findings already fixed"), and the
   replies-are-for-humans rule.

## Objective

Close the four gaps so the review gates in this marketplace catch the defect
classes that actually escape, and so CI and checkout state are never silently
assumed.

## Steps

1. **Add checks (g)–(k) to the adversarial review checklist** in both live
   copies — `git-agent/skills/pr-agent/SKILL.md` Step 4.7 and
   `git-agent/skills/ship/references/self-review.md`.
   *Why:* the gate exists but is aimed away from the observed leak.
   *Verify:* `grep -c "tie-breaker"` returns 1 in each of the two files, and the
   two prompt blocks remain byte-identical to each other.

2. **Mirror the same five classes into the code-review checklist** at
   `code-review/skills/code-review-agent/references/review-checklist.md`,
   section 2.
   *Why:* `agent-code-reviewer` is the subagent Step 4.7 dispatches to; the
   checklist it reads should name the same defects.
   *Verify:* the new subsection appears under "### 2. Potential Bugs" and the
   table of contents still resolves.

3. **Add a dispatch check to `git-agent/skills/merge/SKILL.md` Step 2** — when
   the workflow list is empty or every job produced no log, report the block and
   never call it green.
   *Why:* removes eight-plus sessions of repeated re-diagnosis.
   *Verify:* `grep -n "never dispatched" merge/SKILL.md` returns a hit inside
   Step 2, before the "If any of these fails" paragraph.

4. **Add a stale-checkout guard to the `plan-agent:build` pre-flight**, in
   `skills/build/references/resolve-plan.md` beside the existing dirty-tree
   guard.
   *Why:* implementation is where a stale checkout turns into a false premise.
   *Not the core:* `build/SKILL.md` is 596 words against the 600-word ceiling
   in `tests/plugins/test-progressive-disclosure.sh` — a core is paid in full
   on every fire, and not even a one-line pointer fits. The core already
   delegates Steps 0-1 to `resolve-plan.md`, so the guard is read at the right
   moment at zero core cost.
   *Verify:* `test-progressive-disclosure.sh` still passes, and the guard sits
   inside the Step 1 pre-flight, ahead of plans-directory resolution.

5. **Sync `team-defaults/skills/sync-rules/rules/review-bot-loops.md`** forward
   to the maintainer's current version.
   *Why:* the shipped copy is a stale subset; the missing Triage section is
   exactly the already-applied guard the report asked for.
   *Verify:* `diff ~/.claude/rules/review-bot-loops.md <bundled>` exits 0.

6. **Bump `git-agent`, `code-review`, `plan-agent`, and `team-defaults`** in
   `.claude-plugin/marketplace.json` and add a CHANGELOG entry to each.
   *Why:* a CI guard fails the PR if a touched plugin's version does not exceed
   the base branch.
   *Verify:* `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.

## Tests

### Objective-verification test (mandatory)

`tests/review-gates.test.mjs` — asserts, against the real shipped files, that:

- both adversarial-review prompts contain all five new defect classes;
- the two prompt blocks are identical to each other, so they cannot drift;
- `merge/SKILL.md` contains the never-dispatched rule;
- `resolve-plan.md` carries the freshness guard and the core does not;
- the bundled `review-bot-loops.md` contains the Triage heading and the
  drop-already-applied sentence.

Each assertion fails if the corresponding edit is reverted.

## Acceptance criteria

- [x] The adversarial review names all five report-identified defect classes.
- [x] Both copies of the checklist are identical.
- [x] `merge` refuses to report "green" when no CI job dispatched.
- [x] `plan-agent:build` checks checkout freshness before implementing, without
      pushing its core past the progressive-disclosure ceiling.
- [x] The bundled review-bot-loops rule matches the maintainer's current copy.
- [x] All four touched plugins are version-bumped with CHANGELOG entries.

## Verification

Run `node --test tests/review-gates.test.mjs` (all assertions pass), then
`BASE_REF=main node scripts/check-plugin-versions.mjs` (exit 0), then the repo's
own `scripts/run-all.sh` gate.

## Next steps

- **Extract the shared adversarial checklist** — two identical copies is
  maintainable; a third would not be.

  ```text
  The adversarial pre-PR review checklist is duplicated verbatim in
  kit/plugins/git-agent/skills/pr-agent/SKILL.md (Step 4.7) and
  kit/plugins/git-agent/skills/ship/references/self-review.md. A test asserts
  they stay identical. Propose a way to keep a single source of truth for that
  prompt across two skills in one plugin, given that this repo has no existing
  cross-skill reference convention. Compare options and recommend one.
  ```
