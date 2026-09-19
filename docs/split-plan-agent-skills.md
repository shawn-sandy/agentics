# Stop paying 10,776 words for guidance nobody reads yet

> Five monolithic `plan-agent` skills billed their full bodies on every invocation. Each was split into a SKILL.md core under 600 words plus on-demand `references/*.md` files, reducing always-loaded context by ~90% while keeping all existing test assertions green.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
**Type:** refactor

## What shipped

- Wrote `tests/plugins/test-progressive-disclosure.sh` before any skill was edited: asserts each SKILL.md is under 600 words, has at least one `references/*.md`, links every file that exists on disk (no orphans), and mentions no path that doesn't exist (no dangling links). The test exited 1 on the unmodified skills, proving it can fail.
- Wired the new test into `.github/workflows/check-plugin-versions.yml` as a named step.
- Split `build` (2,907 words) into a core plus `references/invocation.md`, `references/resolve-plan.md`, `references/author-plan-chain.md`, and `references/completion-gates.md`; kept the re-render subroutine inline since every step calls it.
- Split `finalize-plan` (2,764 words) into a core plus `references/resolve-and-modes.md`, `references/sweep-mode.md`, `references/evidence-analysis.md`, and `references/write-completions.md`.
- Split `documenting-plans` (1,897 words) into a core plus `references/resolve-and-preconditions.md`, `references/gather-evidence.md`, and `references/doc-template.md`; deleted the hand-maintained Table of Contents.
- Split `plan-status` (1,681 words) into a core plus `references/single-file-flow.md`, `references/bulk-mode.md`, and `references/type-classification.md`; deleted its Table of Contents.
- Split `setup-sites` (1,527 words) into a core plus `references/preflight.md`, `references/scaffold.md`, and `references/enable-and-verify.md`.
- Updated `tests/plugins/test-build-skill.sh`, `tests/plugins/test-finalize-all-flag.sh`, and `tests/plugins/test-setup-sites.sh` so their section extractors search both `SKILL.md` and every `references/*.md` in the skill directory; all 18 behavior-preservation checks in `test-build-skill.sh` pass unchanged.
- Bumped plan-agent from 7.5.0 to 7.6.0 in `.claude-plugin/marketplace.json`; added the `## 7.6.0` CHANGELOG entry naming all five split skills with before/after word counts.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Core: trigger, arguments, step names, re-render subroutine, Steps 2 and 6 | Modified |
| `kit/plugins/plan-agent/skills/build/references/invocation.md` | Command vs model activation, flag parsing, objective-vs-path grammar | Created |
| `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` | Step 0: plan-mode exit, dirty-tree guard, plans-dir resolution, discovery | Created |
| `kit/plugins/plan-agent/skills/build/references/author-plan-chain.md` | Step 1b: no-plan chain, proposal-vs-direct gate, delegation paths | Created |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Steps 3, 4, 5 and spec-is-source-of-truth rules | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Core plus step names | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/resolve-and-modes.md` | Step 1 argument parsing, plans-dir precedence, spec-vs-legacy edit mode | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/sweep-mode.md` | `--all` flow steps S1 through S5 | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md` | Steps 2, 3a–3c, and Step 4 findings table | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Step 5 spec mode and legacy mode, Step 6 delivery | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Core plus step names; Table of Contents deleted | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/references/resolve-and-preconditions.md` | Steps 0–2: todos, plan resolution, completed-and-30-days-old gate | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/gather-evidence.md` | Steps 3–7: parse plan, slug, file inspection, git history, collision check | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/doc-template.md` | Step 8 document template and Step 9 report table | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Core plus step names; Table of Contents deleted | Modified |
| `kit/plugins/plan-agent/skills/plan-status/references/single-file-flow.md` | Steps 0–4, 6–7: resolution, git dates, frontmatter, evidence scoring | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/bulk-mode.md` | Directory / `--all` seven-stage flow with triage table | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/type-classification.md` | Step 5 signal-to-type table and keep-existing-type rule | Created |
| `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` | Core plus step names | Modified |
| `kit/plugins/plan-agent/skills/setup-sites/references/preflight.md` | Steps 1–3: git/remote URL derivation, plans-dir sanity, template lookup | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/scaffold.md` | Step 4 idempotent artifacts and hub placeholder/card-pruning rules | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/enable-and-verify.md` | Steps 5–7: Pages source enablement, verification block, delivery summary | Created |
| `tests/plugins/test-progressive-disclosure.sh` | Objective test: 600-word ceiling, link integrity in both directions | Created |
| `tests/plugins/test-build-skill.sh` | Section extractors updated to search SKILL.md plus references/ | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Same extractor update for `--all` sweep assertions | Modified |
| `tests/plugins/test-setup-sites.sh` | Same extractor update for scaffold assertions | Modified |
| `.github/workflows/check-plugin-versions.yml` | New step: `test-progressive-disclosure.sh` | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 7.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | `## 7.6.0` entry naming all five split skills | Modified |

## How it works

Anthropic's "The new rules of context engineering" Rule 3 (progressive disclosure) makes the mechanism explicit: move detail out of the always-loaded SKILL.md body into reference files the model pulls when it needs them. A SKILL.md body is paid in full whenever the skill triggers — there is no partial load. `build`'s Step 1b alone (the no-plan chain) ran ~60 lines that fired only when invoked with no plan named; every ordinary `/plan-agent:build docs/plans/x.md` paid for all of it and read none of it.

The pattern was already proven inside the same plugin. `implementation-plan` shipped a core plus four `guidelines/*.md` files telling the model to read each "when the step calls for it, not all up front". This plan applied the same pattern to the other five skills using `references/` (the dominant spelling in the repo and the directory `build-dist.mjs` already whitelists).

The objective test was written first so every subsequent split had an immediate pass/fail signal. The test checks all four conditions: ceiling, existence of references, no orphaned files, no dangling links. Writing it before any SKILL.md edit proved it could fail.

Three existing tests (`test-build-skill.sh`, `test-finalize-all-flag.sh`, `test-setup-sites.sh`) groped skill bodies by path and would break the moment content moved. Each was updated in the same step that performed the corresponding split — the step's Verify ran the updated test. All 18 behavior-preservation checks in `test-build-skill.sh` were kept unchanged; section extractors were taught to search the whole skill directory rather than just SKILL.md.

One deliberate exception to the 600-word ceiling: the four-line re-render bash subroutine in `build` stays in the core rather than moving to a reference, because every single step calls it; pulling it out would trade one always-paid block for five on-demand fetches of the same four lines.

Hand-maintained Tables of Contents in `documenting-plans` and `plan-status` were deleted rather than maintained alongside the new linked step lists. Per Rule 4 (say a thing once), a TOC beside a step list is pure repetition.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
