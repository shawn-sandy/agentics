# Stop paying 10,776 words for guidance nobody reads yet

> Five plan-agent skills bill 10,776 words of context every time they fire, and an ordinary run reads maybe a quarter of it — Step 1b's 60-line no-plan contrac...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
**Type:** refactor

## What shipped

- Write `tests/plugins/test-progressive-disclosure.sh` covering the five skill directories, asserting each `SKILL.md` is under 600 words via a Python word count (deliberately not `wc -w`, whose count of em dashes and arrows drifts by locale — the same ~20-word swing that separates a pass on a dev machine from a fail on a CI runner), has at least one `references/*.md`, links every reference file that exists on disk, and mentions no `references/*.md` path that does not exist.
- Wire the new test into `.github/workflows/check-plugin-versions.yml` as a step named "Test skill progressive disclosure", placed after the existing `test-build-skill.sh` step, with a comment explaining that a re-monolithized skill is invisible in review otherwise.
- Split `kit/plugins/plan-agent/skills/build/SKILL.md` into a core plus `references/invocation.md`, `references/resolve-plan.md`, `references/author-plan-chain.md`, and `references/completion-gates.md`, moving section text verbatim, leaving the re-render subroutine in the core, and replacing each moved section with a named step line that links its reference file.
- Update `tests/plugins/test-build-skill.sh` so its `flatten`/`sed` section extractors search `SKILL.md` and every `references/*.md` in the skill directory for the owning heading, keeping all 18 checks and their exact phrase assertions untouched.
- Split `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` into a core plus `references/resolve-and-modes.md`, `references/sweep-mode.md`, `references/evidence-analysis.md`, and `references/write-completions.md`, then update `tests/plugins/test-finalize-all-flag.sh` to resolve its assertions across the split.
- Split `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` into a core plus `references/resolve-and-preconditions.md`, `references/gather-evidence.md`, and `references/doc-template.md`, and delete the now-redundant `## Table of Contents` section in favor of the linked step list.
- Split `kit/plugins/plan-agent/skills/plan-status/SKILL.md` into a core plus `references/single-file-flow.md`, `references/bulk-mode.md`, and `references/type-classification.md`, dropping its `## Table of Contents` the same way.
- Split `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` into a core plus `references/preflight.md`, `references/scaffold.md`, and `references/enable-and-verify.md`, moving all four embedded shell/python blocks with their steps, then update `tests/plugins/test-setup-sites.sh` to resolve across the split.
- Bump `plan-agent` from `7.5.0` to `7.6.0` in `.claude-plugin/marketplace.json` (never adding a `version` key to `kit/plugins/plan-agent/.claude-plugin/plugin.json`) and add a `## 7.6.0` entry to `kit/plugins/plan-agent/CHANGELOG.md` naming the five split skills, the word counts before and after, and the new test.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | reduced to trigger, arguments summary, step names, the re-render subroutine, Step 2, and Step 6 | Modified |
| `kit/plugins/plan-agent/skills/build/references/invocation.md` | command vs model activation, flag parsing, objective-versus-path grammar and the misparse note | Created |
| `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` | Step 0 exit-plan-mode, the dirty-tree pre-flight guard, AskUserQuestion-unavailable rule, plans-directory resolution, discovery offer, preconditions | Created |
| `kit/plugins/plan-agent/skills/build/references/author-plan-chain.md` | Step 1b in full: objective check, proposal-versus-direct gate, both delegation paths, return path, abandonment contract | Created |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Steps 3, 4, 5 and the spec-is-source-of-truth rules they enforce | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | core plus step names | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/resolve-and-modes.md` | Step 1 argument parsing, plans-directory precedence, spec-versus-legacy edit mode | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/sweep-mode.md` | the `--all` flow, S1 through S5 | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md` | Steps 2, 3a, 3b, 3c and the Step 4 findings table | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Step 5 spec mode and legacy mode, Step 6 delivery | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | core plus step names | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/references/resolve-and-preconditions.md` | Steps 0-2: todos, plan resolution priority order, completed-and-30-days-old gate | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/gather-evidence.md` | Steps 3-7: parse plan, derive slug, inspect shipped files, git history, target-doc collision | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/doc-template.md` | the Step 8 document template and Step 9 report table | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | core plus step names | Modified |
| `kit/plugins/plan-agent/skills/plan-status/references/single-file-flow.md` | Steps 0-4 and Steps 6-7: resolution, git dates, frontmatter read, evidence scoring, confirmation, write rules | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/bulk-mode.md` | the directory / `--all` seven-stage flow with its triage table | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/type-classification.md` | Step 5's signal-to-type table and the keep-existing-type rule | Created |
| `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` | core plus step names | Modified |
| `kit/plugins/plan-agent/skills/setup-sites/references/preflight.md` | Steps 1-3: git/remote URL derivation, `plansDirectory` sanity check, template directory lookup | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/scaffold.md` | Step 4's four idempotent artifacts and the hub placeholder/card-pruning rules | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/enable-and-verify.md` | Steps 5-7: Pages source enablement, verification block, delivery summary | Created |
| `tests/plugins/test-progressive-disclosure.sh` | objective test: word ceiling plus link integrity in both directions | Created |
| `tests/plugins/test-build-skill.sh` | section extractors resolve headings across SKILL.md and references/ | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | same, for the `--all` sweep assertions | Modified |
| `tests/plugins/test-setup-sites.sh` | same, for the scaffold assertions | Modified |
| `.github/workflows/check-plugin-versions.yml` | new step running `tests/plugins/test-progressive-disclosure.sh` | Modified |
| `.claude-plugin/marketplace.json` | `plan-agent` version 7.5.0 to 7.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.6.0 entry | Modified |

## How it works

Split the five monolithic `plan-agent` skills — `build`, `finalize-plan`, `documenting-plans`, `plan-status`, `setup-sites` — into a SKILL.md core under 600 words holding trigger, arguments, and step names, with the mechanics moved to `references/<topic>.md` files loaded on demand.

Anthropic's "The new rules of context engineering for Claude 5 generation models" makes progressive disclosure (Rule 3) the load-bearing rule for skill authoring: move detailed guidance out of the always-loaded body into references the model pulls when it needs them, and split long skills into multiple files. A SKILL.md body is paid in **full** whenever the skill triggers — there is no partial load, no lazy paragraph. A measured audit of this repo found 17 SKILL.md files over 1,200 words shipping as a single file with zero sibling reference files. Five of them live in one plugin, `plan-agent`: `build` (2,907 words), `finalize-plan` (2,764), `documenting-plans` (1,897), `plan-status` (1,681), `setup-sites` (1,527) — 10,776 words in one plugin, and one plugin means one version bump. `build` is the clearest case. Its `## Step 1b — Author a plan first (the no-plan chain)` runs from line 159 to line 219 — about 60 lines of delegation contract, proposal-versus-direct gating, and return-path rules — and it fires **only** when the skill is invoked with no plan named. Every ordinary `/plan-agent:build docs/plans/x.md` pays for all of it and reads none of it. The three mandatory gates (Steps 3, 4, 5, lines 227-303) are the same shape: ~80 lines of verification mechanics that matter at the end of a run, not at the trigger. `finalize-plan` carries an entire `## Sweep mode (--all)` section plus a duplicated legacy-HTML-surgery path; `plan-status` carries a full `## Bulk mode` branch; `setup-sites` carries four embedded shell blocks. The pattern is already proven inside this very plugin. `kit/plugins/plan-agent/skills/implementation-plan/` ships `guidelines/planning-principles.md`, `guidelines/section-catalog.md`, `guidelines/right-sizing.md`, `guidelines/writing-style.md`, and `reference/SKELETON.md`, and its core says explicitly: "read the full file when the step calls for it, not all up front". `code-testing-agent` and `wcag-compliance-reviewer` do the same with `references/` dirs. This plan copies that pattern, using `references/` (the plural, dominant spelling in the repo and the name `build-dist.mjs` already whitelists). **Risk: silent behavior change.** Moving 60 lines of contract into another file can drop a rule. Mitigation: `tests/plugins/test-build-skill.sh` already pins 18 checks' worth of `build`'s exact contract phrases — the `Step 1b` delegation calls, the discovery cap, the misparse note, the AskUserQuestion-unavailable fallback. That test becomes the behavior-preservation harness: its section extractors are taught to resolve a heading from whichever file now carries it, and every assertion must still pass unchanged. `test-finalize-all-flag.sh` and `test-setup-sites.sh` get the same treatment. **Risk: dangling or orphaned references.** A reference file nothing links to is dead weight; a link to a file that does not exist is a hole in the workflow. Progressive disclosure only works if the core names every file it expects the model to fetch. Mitigation: the objective test asserts both directions — every `references/*.md` on disk is linked from its SKILL.md, and every `references/<name>.md` mentioned in a SKILL.md resolves to a real file. **Risk: description drift.** Splitting must not change any frontmatter `description` — those strings are what makes a skill trigger, and `tests/plugins/test-description-budget.sh` already enforces the 200-char budget. Mitigation: an explicit `git diff` check that the five `description:` lines are byte-identical to `main`. Deliberate exception to the ceiling logic: `build`'s re-render subroutine (a four-line bash block) stays in the core rather than moving to a reference, because every single step calls it. Pulling it out would trade one always-paid block for five on-demand fetches of the same four lines.

The implementation proceeded through the following steps: Write `tests/plugins/test-progressive-disclosure.sh` covering the five skill directories, asserting each `SKILL.md` is under 600 words via a Python word count (deliberately not `wc -w`, whose count of em dashes and arrows drifts by locale — the same ~20-word swing that separates a pass on a dev machine from a fail on a CI runner), has at least one `references/*.md`, links every reference file that exists on disk, and mentions no `references/*.md` path that does not exist.; Wire the new test into `.github/workflows/check-plugin-versions.yml` as a step named "Test skill progressive disclosure", placed after the existing `test-build-skill.sh` step, with a comment explaining that a re-monolithized skill is invisible in review otherwise.; Split `kit/plugins/plan-agent/skills/build/SKILL.md` into a core plus `references/invocation.md`, `references/resolve-plan.md`, `references/author-plan-chain.md`, and `references/completion-gates.md`, moving section text verbatim, leaving the re-render subroutine in the core, and replacing each moved section with a named step line that links its reference file.; Update `tests/plugins/test-build-skill.sh` so its `flatten`/`sed` section extractors search `SKILL.md` and every `references/*.md` in the skill directory for the owning heading, keeping all 18 checks and their exact phrase assertions untouched.; Split `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` into a core plus `references/resolve-and-modes.md`, `references/sweep-mode.md`, `references/evidence-analysis.md`, and `references/write-completions.md`, then update `tests/plugins/test-finalize-all-flag.sh` to resolve its assertions across the split.; Split `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` into a core plus `references/resolve-and-preconditions.md`, `references/gather-evidence.md`, and `references/doc-template.md`, and delete the now-redundant `## Table of Contents` section in favor of the linked step list.; Split `kit/plugins/plan-agent/skills/plan-status/SKILL.md` into a core plus `references/single-file-flow.md`, `references/bulk-mode.md`, and `references/type-classification.md`, dropping its `## Table of Contents` the same way.; Split `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` into a core plus `references/preflight.md`, `references/scaffold.md`, and `references/enable-and-verify.md`, moving all four embedded shell/python blocks with their steps, then update `tests/plugins/test-setup-sites.sh` to resolve across the split.; Bump `plan-agent` from `7.5.0` to `7.6.0` in `.claude-plugin/marketplace.json` (never adding a `version` key to `kit/plugins/plan-agent/.claude-plugin/plugin.json`) and add a `## 7.6.0` entry to `kit/plugins/plan-agent/CHANGELOG.md` naming the five split skills, the word counts before and after, and the new test..

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
