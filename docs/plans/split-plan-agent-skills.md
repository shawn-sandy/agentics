---
status: completed
modified: 2026-08-01
type: refactor
created: 2026-07-27
effort: high
glance: Five plan-agent skills bill 10,776 words of context every time they fire, and an ordinary run reads maybe a quarter of it — Step 1b's 60-line no-plan contract is paid in full by every invocation that names a plan. The cost is invisible today because nothing measures it, so this ships the measurement alongside the fix and treats a behavioral regression as blocking even if every word count drops.
workflow: true
---

# Plan: Stop paying 10,776 words for guidance nobody reads yet

## Objective

Split the five monolithic `plan-agent` skills — `build`, `finalize-plan`, `documenting-plans`, `plan-status`, `setup-sites` — into a SKILL.md core under 600 words holding trigger, arguments, and step names, with the mechanics moved to `references/<topic>.md` files loaded on demand.

## Context

Anthropic's "The new rules of context engineering for Claude 5 generation models" makes progressive disclosure (Rule 3) the load-bearing rule for skill authoring: move detailed guidance out of the always-loaded body into references the model pulls when it needs them, and split long skills into multiple files. A SKILL.md body is paid in **full** whenever the skill triggers — there is no partial load, no lazy paragraph. A measured audit of this repo found 17 SKILL.md files over 1,200 words shipping as a single file with zero sibling reference files. Five of them live in one plugin, `plan-agent`: `build` (2,907 words), `finalize-plan` (2,764), `documenting-plans` (1,897), `plan-status` (1,681), `setup-sites` (1,527) — 10,776 words in one plugin, and one plugin means one version bump.

`build` is the clearest case. Its `## Step 1b — Author a plan first (the no-plan chain)` runs from line 159 to line 219 — about 60 lines of delegation contract, proposal-versus-direct gating, and return-path rules — and it fires **only** when the skill is invoked with no plan named. Every ordinary `/plan-agent:build docs/plans/x.md` pays for all of it and reads none of it. The three mandatory gates (Steps 3, 4, 5, lines 227-303) are the same shape: ~80 lines of verification mechanics that matter at the end of a run, not at the trigger. `finalize-plan` carries an entire `## Sweep mode (--all)` section plus a duplicated legacy-HTML-surgery path; `plan-status` carries a full `## Bulk mode` branch; `setup-sites` carries four embedded shell blocks.

The pattern is already proven inside this very plugin. `kit/plugins/plan-agent/skills/implementation-plan/` ships `guidelines/planning-principles.md`, `guidelines/section-catalog.md`, `guidelines/right-sizing.md`, `guidelines/writing-style.md`, and `reference/SKELETON.md`, and its core says explicitly: "read the full file when the step calls for it, not all up front". `code-testing-agent` and `wcag-compliance-reviewer` do the same with `references/` dirs. This plan copies that pattern, using `references/` (the plural, dominant spelling in the repo and the name `build-dist.mjs` already whitelists).

**Risk: silent behavior change.** Moving 60 lines of contract into another file can drop a rule. Mitigation: `tests/plugins/test-build-skill.sh` already pins 18 checks' worth of `build`'s exact contract phrases — the `Step 1b` delegation calls, the discovery cap, the misparse note, the AskUserQuestion-unavailable fallback. That test becomes the behavior-preservation harness: its section extractors are taught to resolve a heading from whichever file now carries it, and every assertion must still pass unchanged. `test-finalize-all-flag.sh` and `test-setup-sites.sh` get the same treatment.

**Risk: dangling or orphaned references.** A reference file nothing links to is dead weight; a link to a file that does not exist is a hole in the workflow. Progressive disclosure only works if the core names every file it expects the model to fetch. Mitigation: the objective test asserts both directions — every `references/*.md` on disk is linked from its SKILL.md, and every `references/<name>.md` mentioned in a SKILL.md resolves to a real file.

**Risk: description drift.** Splitting must not change any frontmatter `description` — those strings are what makes a skill trigger, and `tests/plugins/test-description-budget.sh` already enforces the 200-char budget. Mitigation: an explicit `git diff` check that the five `description:` lines are byte-identical to `main`.

Deliberate exception to the ceiling logic: `build`'s re-render subroutine (a four-line bash block) stays in the core rather than moving to a reference, because every single step calls it. Pulling it out would trade one always-paid block for five on-demand fetches of the same four lines.

## Files

- kit/plugins/plan-agent/skills/build/SKILL.md (modified) — reduced to trigger, arguments summary, step names, the re-render subroutine, Step 2, and Step 6
- kit/plugins/plan-agent/skills/build/references/invocation.md (new) — command vs model activation, flag parsing, objective-versus-path grammar and the misparse note
- kit/plugins/plan-agent/skills/build/references/resolve-plan.md (new) — Step 0 exit-plan-mode, the dirty-tree pre-flight guard, AskUserQuestion-unavailable rule, plans-directory resolution, discovery offer, preconditions
- kit/plugins/plan-agent/skills/build/references/author-plan-chain.md (new) — Step 1b in full: objective check, proposal-versus-direct gate, both delegation paths, return path, abandonment contract
- kit/plugins/plan-agent/skills/build/references/completion-gates.md (new) — Steps 3, 4, 5 and the spec-is-source-of-truth rules they enforce
- kit/plugins/plan-agent/skills/finalize-plan/SKILL.md (modified) — core plus step names
- kit/plugins/plan-agent/skills/finalize-plan/references/resolve-and-modes.md (new) — Step 1 argument parsing, plans-directory precedence, spec-versus-legacy edit mode
- kit/plugins/plan-agent/skills/finalize-plan/references/sweep-mode.md (new) — the `--all` flow, S1 through S5
- kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md (new) — Steps 2, 3a, 3b, 3c and the Step 4 findings table
- kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md (new) — Step 5 spec mode and legacy mode, Step 6 delivery
- kit/plugins/plan-agent/skills/documenting-plans/SKILL.md (modified) — core plus step names
- kit/plugins/plan-agent/skills/documenting-plans/references/resolve-and-preconditions.md (new) — Steps 0-2: todos, plan resolution priority order, completed-and-30-days-old gate
- kit/plugins/plan-agent/skills/documenting-plans/references/gather-evidence.md (new) — Steps 3-7: parse plan, derive slug, inspect shipped files, git history, target-doc collision
- kit/plugins/plan-agent/skills/documenting-plans/references/doc-template.md (new) — the Step 8 document template and Step 9 report table
- kit/plugins/plan-agent/skills/plan-status/SKILL.md (modified) — core plus step names
- kit/plugins/plan-agent/skills/plan-status/references/single-file-flow.md (new) — Steps 0-4 and Steps 6-7: resolution, git dates, frontmatter read, evidence scoring, confirmation, write rules
- kit/plugins/plan-agent/skills/plan-status/references/bulk-mode.md (new) — the directory / `--all` seven-stage flow with its triage table
- kit/plugins/plan-agent/skills/plan-status/references/type-classification.md (new) — Step 5's signal-to-type table and the keep-existing-type rule
- kit/plugins/plan-agent/skills/setup-sites/SKILL.md (modified) — core plus step names
- kit/plugins/plan-agent/skills/setup-sites/references/preflight.md (new) — Steps 1-3: git/remote URL derivation, `plansDirectory` sanity check, template directory lookup
- kit/plugins/plan-agent/skills/setup-sites/references/scaffold.md (new) — Step 4's four idempotent artifacts and the hub placeholder/card-pruning rules
- kit/plugins/plan-agent/skills/setup-sites/references/enable-and-verify.md (new) — Steps 5-7: Pages source enablement, verification block, delivery summary
- tests/plugins/test-progressive-disclosure.sh (new) — objective test: word ceiling plus link integrity in both directions
- tests/plugins/test-build-skill.sh (modified) — section extractors resolve headings across SKILL.md and references/
- tests/plugins/test-finalize-all-flag.sh (modified) — same, for the `--all` sweep assertions
- tests/plugins/test-setup-sites.sh (modified) — same, for the scaffold assertions
- .github/workflows/check-plugin-versions.yml (modified) — new step running `tests/plugins/test-progressive-disclosure.sh`
- .claude-plugin/marketplace.json (modified) — `plan-agent` version 7.5.0 to 7.6.0
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 7.6.0 entry

## Steps

1. [x] Write `tests/plugins/test-progressive-disclosure.sh` covering the five skill directories, asserting each `SKILL.md` is under 600 words via a Python word count (deliberately not `wc -w`, whose count of em dashes and arrows drifts by locale — the same ~20-word swing that separates a pass on a dev machine from a fail on a CI runner), has at least one `references/*.md`, links every reference file that exists on disk, and mentions no `references/*.md` path that does not exist. Why: writing the gate before the refactor means every subsequent step has an objective pass/fail instead of a judgment call, and the failing-first run proves the test can fail. Verify: `bash tests/plugins/test-progressive-disclosure.sh` exits 1 and names all five skills as over the ceiling with no reference files.
2. [x] Wire the new test into `.github/workflows/check-plugin-versions.yml` as a step named "Test skill progressive disclosure", placed after the existing `test-build-skill.sh` step, with a comment explaining that a re-monolithized skill is invisible in review otherwise. Why: the repo has no test runner, so a test not named in a workflow never runs in CI. Verify: `grep -c "test-progressive-disclosure.sh" .github/workflows/check-plugin-versions.yml` prints 1 and `python3 -c "import yaml,sys;yaml.safe_load(open('.github/workflows/check-plugin-versions.yml'))"` exits 0.
3. [x] Split `kit/plugins/plan-agent/skills/build/SKILL.md` into a core plus `references/invocation.md`, `references/resolve-plan.md`, `references/author-plan-chain.md`, and `references/completion-gates.md`, moving section text verbatim, leaving the re-render subroutine in the core, and replacing each moved section with a named step line that links its reference file. Why: `Step 1b` alone is ~60 lines that fire only on a no-plan invocation, and the three gates are ~80 more that matter only at the end of a run. Verify: `wc -w kit/plugins/plan-agent/skills/build/SKILL.md` reports under 600, and `git diff main -- kit/plugins/plan-agent/skills/build/SKILL.md | grep '^-description:'` prints nothing.
4. [x] Update `tests/plugins/test-build-skill.sh` so its `flatten`/`sed` section extractors search `SKILL.md` and every `references/*.md` in the skill directory for the owning heading, keeping all 18 checks and their exact phrase assertions untouched. Why: those assertions are the only record that `build`'s contract survived the move, so they must keep failing on a dropped rule rather than being relaxed to match the new layout. Verify: `bash tests/plugins/test-build-skill.sh` prints "All build-skill checks passed." and exits 0.
5. [x] Split `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` into a core plus `references/resolve-and-modes.md`, `references/sweep-mode.md`, `references/evidence-analysis.md`, and `references/write-completions.md`, then update `tests/plugins/test-finalize-all-flag.sh` to resolve its assertions across the split. Why: the `--all` sweep and the legacy HTML-surgery path are each a whole branch that most invocations never enter. Verify: `wc -w kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` reports under 600 and `bash tests/plugins/test-finalize-all-flag.sh` exits 0.
6. [x] Split `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` into a core plus `references/resolve-and-preconditions.md`, `references/gather-evidence.md`, and `references/doc-template.md`, and delete the now-redundant `## Table of Contents` section in favor of the linked step list. Why: the ~75-line document template is output formatting that is irrelevant until Step 8, and a hand-maintained TOC beside a step list is Rule 4 repetition. Verify: `wc -w kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` reports under 600 and `grep -c "Table of Contents" kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` prints 0.
7. [x] Split `kit/plugins/plan-agent/skills/plan-status/SKILL.md` into a core plus `references/single-file-flow.md`, `references/bulk-mode.md`, and `references/type-classification.md`, dropping its `## Table of Contents` the same way. Why: bulk mode is an entire alternate seven-stage workflow that a single-file status check never touches. Verify: `wc -w kit/plugins/plan-agent/skills/plan-status/SKILL.md` reports under 600 and `grep -c "references/bulk-mode.md" kit/plugins/plan-agent/skills/plan-status/SKILL.md` prints at least 1.
8. [x] Split `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` into a core plus `references/preflight.md`, `references/scaffold.md`, and `references/enable-and-verify.md`, moving all four embedded shell/python blocks with their steps, then update `tests/plugins/test-setup-sites.sh` to resolve across the split. Why: the scaffold shell blocks are the bulk of the file and are needed only once the preflight has passed. Verify: `wc -w kit/plugins/plan-agent/skills/setup-sites/SKILL.md` reports under 600 and `bash tests/plugins/test-setup-sites.sh` exits 0.
9. [x] Bump `plan-agent` from `7.5.0` to `7.6.0` in `.claude-plugin/marketplace.json` (never adding a `version` key to `kit/plugins/plan-agent/.claude-plugin/plugin.json`) and add a `## 7.6.0` entry to `kit/plugins/plan-agent/CHANGELOG.md` naming the five split skills, the word counts before and after, and the new test. Why: `plan-agent` is the only plugin this plan touches, and any edit under `kit/plugins/<name>/` requires a marketplace version higher than `main` plus a CHANGELOG entry; the new `references/*.md` files are added skill content, which `.claude/rules/marketplace.md` puts in the MINOR row. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 and `head -5 kit/plugins/plan-agent/CHANGELOG.md` shows the 7.6.0 heading.

## Tests

Tier 1 — This plan changes application code

- Objective: proves every one of the five skills is genuinely progressively disclosed — a small core plus reachable references — and not merely shorter. File: tests/plugins/test-progressive-disclosure.sh; Type: smoke; Asserts: for each of `build`, `finalize-plan`, `documenting-plans`, `plan-status`, `setup-sites`, that `SKILL.md` is under 600 words, that at least one `references/*.md` exists beside it, that every `references/*.md` file on disk is linked by name from that `SKILL.md` (no orphans), and that every `references/<name>.md` string appearing in that `SKILL.md` resolves to an existing file (no dangling links); Run: bash tests/plugins/test-progressive-disclosure.sh
- Unit: behavior preservation for `build`, the most contract-heavy of the five. File: tests/plugins/test-build-skill.sh; Targets: kit/plugins/plan-agent/skills/build/SKILL.md and its references/; Key cases: all 18 existing checks pass unchanged after the split — Step 1b's two `Skill(...)` delegation calls, the "offer, never a silent pickup" discovery rule, the three-candidate cap, the objective-versus-path misparse note, the AskUserQuestion-unavailable stop-and-report rule, and the `Do not set status: completed here` gate ordering — each resolved from whichever file now carries its section.
- Unit: behavior preservation for the two other tested skills. File: tests/plugins/test-finalize-all-flag.sh and tests/plugins/test-setup-sites.sh; Targets: finalize-plan and setup-sites SKILL.md plus their references/; Key cases: the `--all` sweep assertions and the scaffold/verification assertions pass unchanged with extractors that search the whole skill directory.
- Unit: descriptions are untouched by the split. File: tests/plugins/test-description-budget.sh; Targets: every shipped SKILL.md frontmatter description; Key cases: all five descriptions still pass the 200-char total and 80-char first-sentence budget, complementing the plan's byte-identical `git diff` criterion.

## Acceptance Criteria

- [x] `wc -w` reports under 600 words for each of the five files `kit/plugins/plan-agent/skills/{build,finalize-plan,documenting-plans,plan-status,setup-sites}/SKILL.md`
- [x] Each of those five skill directories contains a `references/` directory with at least one `.md` file in it
- [x] `bash tests/plugins/test-progressive-disclosure.sh` exits 0
- [x] `bash tests/plugins/test-build-skill.sh` exits 0 with all 18 checks passing and no check deleted or weakened (`grep -c '^echo "[0-9]' tests/plugins/test-build-skill.sh` is unchanged from `main`)
- [x] `bash tests/plugins/test-finalize-all-flag.sh` and `bash tests/plugins/test-setup-sites.sh` both exit 0
- [x] `bash tests/plugins/test-description-budget.sh` exits 0
- [x] `git diff main -- kit/plugins/plan-agent/skills/ | grep -c '^[-+]description:'` prints 0 — no frontmatter description changed
- [x] `.github/workflows/check-plugin-versions.yml` contains a step running `tests/plugins/test-progressive-disclosure.sh`
- [x] `.claude-plugin/marketplace.json` sets `plan-agent` to `7.6.0`, and `python3 -c "import json;print('version' in json.load(open('kit/plugins/plan-agent/.claude-plugin/plugin.json')))"` prints `False`
- [x] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0
- [x] `kit/plugins/plan-agent/CHANGELOG.md` has a `## 7.6.0` entry naming all five split skills
- [x] `node scripts/build-dist.mjs` produces `dist/` containing every new `references/*.md` under `kit/plugins/plan-agent/skills/*/references/`

## Verification

Run `bash tests/plugins/test-progressive-disclosure.sh` — expected result: exit 0 with a passing line for each of the five skills and no orphan or dangling-link report. Then run `bash tests/plugins/test-build-skill.sh`, `bash tests/plugins/test-finalize-all-flag.sh`, `bash tests/plugins/test-setup-sites.sh`, and `bash tests/plugins/test-description-budget.sh` — all four exit 0. Confirm the version guard with `BASE_REF=main node scripts/check-plugin-versions.mjs` (exit 0), and confirm distribution with `node scripts/build-dist.mjs && find dist -path '*plan-agent/skills/*/references/*.md' | wc -l`, which must equal the number of reference files created.

**Tautology check — the objective test must be able to fail three times, once per assertion it makes.** First break the ceiling: append 700 words of filler to `kit/plugins/plan-agent/skills/setup-sites/SKILL.md`, re-run `bash tests/plugins/test-progressive-disclosure.sh`, confirm it exits 1 naming that file as over 600 words, then `git checkout -- kit/plugins/plan-agent/skills/setup-sites/SKILL.md`. Next break the links: delete the line in `kit/plugins/plan-agent/skills/build/SKILL.md` that links `references/author-plan-chain.md`, re-run, confirm it exits 1 reporting that file as an orphaned reference, then revert. Finally break the other direction: add a link to `references/does-not-exist.md` in the same core, re-run, confirm it exits 1 reporting a dangling link, then revert. A test that stays green through any of the three is measuring nothing and must be fixed before this plan is done.

**Behavioral check — the skills must still work, not merely be shorter.** Word counts falling is not evidence of correctness. In a scratch git repo outside this worktree, load the plugin with `claude --plugin-dir kit/plugins/plan-agent` and exercise each split skill end to end: run `/plan-agent:setup-sites` and confirm it still writes `.github/workflows/deploy-pages.yml`, `docs/.nojekyll`, `scripts/serve-docs.sh`, and `docs/index.html` and prints its PASS verification lines; run `/plan-agent:plan-status <a plan file>` and confirm it presents the findings table and writes frontmatter only after confirmation; run `/plan-agent:finalize-plan <a plan file>` and confirm it produces the evidence table, per-criterion breakdown, and objective-test result; run `/plan-agent:build <an existing small plan>` and confirm it reaches all three gates and re-renders the HTML; run `/plan-agent:build` with no arguments and confirm it still enters the Step 1b chain and asks the proposal-versus-direct question. In each run, confirm the model actually opened the relevant `references/*.md` file — a core that names a reference the model never reads is a broken handoff, not a smaller skill. Record any skill whose behavior changed; a behavioral regression blocks this plan regardless of test results.

## Next Steps

- Split the remaining oversized skills in the other plugins
    The audit found 17 single-file SKILL.md files over 1,200 words; this plan handles the five in `plan-agent`. The other twelve span several plugins and each needs its own version bump and CHANGELOG entry, so they are separate units of work.

    ```text
    In the agentics repo (a Claude Code plugin marketplace), find every SKILL.md under kit/plugins/ that is over 1,200 words and ships as a single file with no sibling reference files, excluding the five in kit/plugins/plan-agent/skills/ (build, finalize-plan, documenting-plans, plan-status, setup-sites) which were already split. Measure with `wc -w`. For each one found, split it into a SKILL.md core under 600 words holding the trigger, arguments, and step names, plus references/<topic>.md files beside it holding the mechanics, following the pattern in kit/plugins/plan-agent/skills/implementation-plan/ (guidelines/ + reference/) and kit/plugins/code-testing-agent/skills/*/references/. Do not change any frontmatter description. For every plugin you touch, bump its version in .claude-plugin/marketplace.json (semver: refactor = minor bump, must be higher than the value on main; never add a version field to plugin.json) and add an entry to kit/plugins/<name>/CHANGELOG.md. Verify with: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0; `bash tests/plugins/test-progressive-disclosure.sh` exits 0 after you extend its skill list to cover the newly split skills; `bash tests/plugins/test-description-budget.sh` exits 0; and `git diff main -- kit/plugins/ | grep -c '^[-+]description:'` prints 0.
    ```

- Add a repo-wide word-ceiling lint so new skills cannot ship monolithic
    Today nothing stops a new 3,000-word single-file skill from landing. A generic guard would catch it at review time instead of at the next audit.

    ```text
    In the agentics repo (a Claude Code plugin marketplace), add tests/plugins/test-skill-word-ceiling.sh: a bash test that walks every kit/plugins/*/skills/*/SKILL.md, and fails with exit 1 for any file over 1,200 words (`wc -w`) that has no sibling references/ or guidelines/ directory containing at least one .md file. Print one line per skill checked and a summary. Wire it into .github/workflows/check-plugin-versions.yml as its own step with a comment explaining that an oversized single-file skill is paid in full on every trigger and is otherwise invisible in review. If any currently-shipping skill fails, list them in the PR description rather than silently raising the threshold. This touches no plugin files, so no marketplace.json version bump and no CHANGELOG entry are needed — state that explicitly in the PR body. Verify by running `bash tests/plugins/test-skill-word-ceiling.sh` (expect exit 0), then temporarily appending 1,500 words to a skill that has no references/ dir, re-running to confirm exit 1, and reverting.
    ```

## Resources

- The new rules of context engineering for Claude 5 generation models — https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models — Rule 3 (progressive disclosure over upfront dumps) is the direct basis for this split; Rule 4 (say a thing once) justifies deleting the hand-maintained Tables of Contents.
- `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` — the in-repo precedent: its "Guidelines library" block names four `guidelines/*.md` files and tells the model to read each "when the step calls for it, not all up front". Copy this linking style.
- `kit/plugins/plan-agent/skills/implementation-plan/guidelines/` and `reference/SKELETON.md` — the target directory shape, already shipping in this plugin.
- `kit/plugins/code-testing-agent/skills/*/references/` and `kit/plugins/wcag-compliance-reviewer/skills/*/references/` — the `references/` plural spelling this plan standardizes on.
- `tests/plugins/test-build-skill.sh` — 18 checks pinning `build`'s exact contract phrases via section-scoped `sed` extraction; the behavior-preservation harness for the riskiest split, and the file whose extractors must be taught the new layout.
- `tests/plugins/test-finalize-all-flag.sh` and `tests/plugins/test-setup-sites.sh` — the other two tests that grep these skills by path and will break without the same extractor update.
- `tests/plugins/test-description-budget.sh` — already enforces the 200-char description budget across every shipped SKILL.md; proves the split left descriptions alone.
- `.github/workflows/check-plugin-versions.yml` — shows how individual tests are wired as named steps; there is no package.json and no test runner, so this file is the only path into CI.
- `scripts/check-plugin-versions.mjs` — the version guard run as `BASE_REF=main node scripts/check-plugin-versions.mjs`.
- `scripts/build-dist.mjs` — its `KEEP` set already includes `references`, and `skills/` is copied recursively, so nested reference files ship without a script change; the dist check confirms it.
- `.claude/rules/skill-authoring.md` — the repo's own checklist: "SKILL.md body is under 500 lines", "Additional details are in separate files", "File references are one level deep", "Progressive disclosure used appropriately".
- `.claude/rules/marketplace.md` — the version-bump table whose MINOR row covers added skill content, and the "What you do" list pairing every bump with a `kit/plugins/<name>/CHANGELOG.md` entry. Note its "there is no CI version guard" line is stale: `scripts/check-plugin-versions.mjs` and its workflow now exist.
