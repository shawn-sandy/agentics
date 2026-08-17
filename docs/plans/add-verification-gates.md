---
status: completed
type: fix
created: 2026-08-17
modified: 2026-08-17
repo-name: agentics
---

# Add Verification Gates

## context

Tier 2 of the agent-prompting audit run against
<https://shumer.dev/prompting-ai-agents> (Tier 1 shipped as the
security-scrub PR): five confirmed places where a skill can declare success on
broken output because "done" is defined as producing the artifact, not
verifying it. The audit's central finding — agents produce plausible-looking
work and confidently declare completion — held in each. No follow-up question
needed: every fix is a named skill-markdown edit below; the whole-suite test
run is the executable check.

## objective

Redefine "done" as artifact + verification in the five highest-blast-radius
skills: settings-restore, code-review (both paths), ship/agent-ship,
code-testing-agent (both skills), and review-plan.

## steps

1. **settings-restore — verify the restore**
   (`kit/plugins/settings-sync/skills/settings-restore/SKILL.md`): new Step 7
   re-runs the Step 4 comparison for every restored entry, checks
   `~/.claude/hooks` execute bits, and the Step 9 report uses verified results
   only, leading with `Restore INCOMPLETE` on any failure.
   *Why:* a destructive overwrite reported planned counts, not verified ones.
   *Verify:* Step 7 heading exists; Step 9 states it is reachable only through
   the gate.
2. **code-review — findings survive a re-read**
   (`.../code-review-agent/SKILL.md`, `agents/agent-code-reviewer.md`): a
   Verify Findings step re-Reads each cited file:line, pastes the verbatim
   snippet, drops or labels **Unconfirmed** anything unsubstantiated; the
   background agent gets the same as a workflow step plus a filled example
   finding. *Why:* checklist → report with no evidence requirement.
   *Verify:* both files contain the re-read requirement.
3. **ship/agent-ship — PR state check**
   (`.../ship/references/pr-body.md`, `agents/agent-ship.md`,
   `.../ship/SKILL.md`): STOP only on `"state":"OPEN"`/`"opened"`; merged,
   closed, or no-PR proceeds to create. *Why:* `gh pr view` resolves dead PRs;
   pr-agent fixed this in 3.3.2, ship never ported it.
   *Verify:* all three files query `state`.
4. **code-testing-agent — run what you write**
   (`.../code-testing-agent/SKILL.md` Step 6a, `.../reviewing-tests/SKILL.md`
   Step 7): execute written/edited tests via Bash, bounded 3-iteration fix
   loop with honest hard stops, behavior-gap failures reported as findings;
   stale-mock findings need paired mock+source quotes.
   *Why:* both skills handed verification to the user despite having Bash.
   *Verify:* both files define done as written AND executed.
5. **review-plan — edit the spec, not the render**
   (`.../review-plan/SKILL.md`, `references/output-template.md`,
   `agents/agent-review-plan.md`, `commands/review-plan-bg.md`): Step 1
   spec/legacy mode detection; spec mode maps selector targets to spec
   sections and re-renders with `plan-agent-render`; Team Review appended to
   the spec; Step 7 verifies each edit landed and announces an
   applied/skipped tally, with `REVIEW INCOMPLETE` in background mode on any
   skip. *Why:* HTML edits were regenerated away by the pipeline's own hook.
   *Verify:* `tests/review-plan-skill.test.mjs` passes (12/12).
6. **Bump versions and changelogs**: code-review 3.3.4, code-testing-agent
   3.5.1, git-agent 4.19.1, settings-sync 1.1.3 (skips in-flight 1.1.2),
   plan-agent 9.4.3 (skips in-flight 9.4.2).
   *Verify:* `BASE_REF=main node scripts/check-plugin-versions.mjs` passes.

## tests

**Objective-verification test** — the repo's existing behavioral suites cover
the edited skills and must stay green:
`tests/review-plan-skill.test.mjs` (12 assertions over review-plan's workflow
text, exercised against the rewritten Step 7),
`tests/plugins/test-exitplanmode-guard.sh` (guards intact across all edited
mutating skills), `tests/plugins/test-no-shell-expansion.sh` (no new expansion
call sites), and the full `tests/plugins/` sweep. No new test file: the
changes are instruction prose whose repo-level invariants these suites already
assert; per-skill behavioral tests need a live `claude` run, tracked as the
Tier 3 runner work.

## acceptance-criteria

- [x] settings-restore cannot report success without the Step 7 gate passing.
- [x] Every code-review Critical Issue/Breaking Change requires a verbatim
      current-file quote.
- [x] ship proceeds to PR creation when the existing PR is merged or closed.
- [x] Both code-testing skills execute the files they write/edit before
      reporting done.
- [x] review-plan edits the `.md` spec on spec-backed plans and reports an
      applied/skipped tally.
- [x] All five plugin versions exceed `origin/main`; changelogs document the
      changes.

## verification

`bash tests/plugins/*.sh` sweep + `node tests/review-plan-skill.test.mjs` +
`git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` +
marketplace.json JSON parse — all green before the PR opened.

## next-steps

- **Done** — all four sub-items shipped together in PR #569 (`ab2f769`,
  merged 2026-08-17): the verification-gate and worked-example requirements
  in `plugin-patterns.md` with `tests/plugins/test-verification-gate-rule.sh`
  as the retention grep, the Warning-level Dimension 3 rubric check in
  skill-reviewer's `audit-steps.md`, `tests/run-all.sh` with its documented
  skip list wired into `check-plugin-versions.yml`, and
  `scripts/build-dist.mjs` setting `exitCode=1` on any plugin error.
  Original item — Tier 3 (leverage point) from the audit:

  ```text
  In the agentics repo, implement Tier 3 of the 2026-08-17 agent-prompting
  audit: (1) add two requirements to .claude/rules/plugin-patterns.md — any
  skill that mutates files/git/remote must end with a verification step that
  redefines done as artifact + check, and any skill with structured output
  must include one worked example — with a CI retention grep; (2) add a
  Warning-level rubric check to skill-reviewer's
  references/audit-steps.md Dimension 3 for missing verification gates;
  (3) add tests/run-all.sh globbing tests/**/test-*.{sh,mjs} with a
  documented skip-list and wire it into CI (49 of 77 test files currently run
  in no workflow); (4) make scripts/build-dist.mjs set exitCode=1 when any
  plugin errors. Bump versions and changelogs per plugin.
  ```

- **Done** — shipped in PR #572 (settings-sync 1.1.4, merged 2026-08-17):
  both skills carry the guard as Step 0, list `ToolSearch, ExitPlanMode` in
  `allowed-tools`, and are registered in the WRITE_HEAVY manifest.
  Original item — settings-restore was missing the plan-mode guard line
  despite running `rm -rf`/`rsync --delete` (spotted in passing, out of
  scope here):

  ```text
  In the agentics repo, add the verbatim plan-mode guard line required by
  .claude/rules/plugin-patterns.md to
  kit/plugins/settings-sync/skills/settings-restore/SKILL.md (and audit
  settings-backup for the same gap), then add both files to the WRITE_HEAVY
  manifest in tests/plugins/test-exitplanmode-guard.sh. Bump settings-sync
  and add a changelog entry.
  ```
