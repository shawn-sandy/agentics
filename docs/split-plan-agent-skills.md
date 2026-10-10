# Stop paying 10,776 words for guidance nobody reads yet

> Split five monolithic plan-agent skills into small SKILL.md cores (under 600 words each) plus on-demand reference files, reducing always-loaded context by ~80% without changing any skill's behavior or frontmatter description.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
**Type:** refactor

## What shipped

- Split `build` SKILL.md into a core plus `references/invocation.md`, `references/resolve-plan.md`, `references/author-plan-chain.md`, and `references/completion-gates.md`
- Split `finalize-plan` SKILL.md into a core plus `references/resolve-and-modes.md`, `references/sweep-mode.md`, `references/evidence-analysis.md`, and `references/write-completions.md`
- Split `documenting-plans` SKILL.md into a core plus `references/resolve-and-preconditions.md`, `references/gather-evidence.md`, and `references/doc-template.md`
- Split `plan-status` SKILL.md into a core plus `references/single-file-flow.md`, `references/bulk-mode.md`, and `references/type-classification.md`
- Split `setup-sites` SKILL.md into a core plus `references/preflight.md`, `references/scaffold.md`, and `references/enable-and-verify.md`
- Wrote `tests/plugins/test-progressive-disclosure.sh` asserting each SKILL.md is under 600 words with linked and resolving reference files
- Updated `tests/plugins/test-build-skill.sh`, `test-finalize-all-flag.sh`, and `test-setup-sites.sh` so their section extractors search across SKILL.md and all reference files
- Wired the new test into `.github/workflows/check-plugin-versions.yml`
- Bumped plan-agent to 7.6.0 and added a CHANGELOG entry

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Core reduced to trigger, arguments, re-render subroutine, step names | Modified |
| `kit/plugins/plan-agent/skills/build/references/invocation.md` | Flag parsing, command vs model activation, misparse note | Created |
| `kit/plugins/plan-agent/skills/build/references/resolve-plan.md` | Step 0 exit-plan-mode, dirty-tree guard, discovery offer, preconditions | Created |
| `kit/plugins/plan-agent/skills/build/references/author-plan-chain.md` | Step 1b no-plan chain in full | Created |
| `kit/plugins/plan-agent/skills/build/references/completion-gates.md` | Steps 3, 4, 5 — spec-is-source-of-truth rules | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/SKILL.md` | Core plus step names | Modified |
| `kit/plugins/plan-agent/skills/finalize-plan/references/resolve-and-modes.md` | Argument parsing, spec-vs-legacy edit mode | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/sweep-mode.md` | `--all` flow, S1–S5 | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/evidence-analysis.md` | Steps 2–3c and Step 4 findings table | Created |
| `kit/plugins/plan-agent/skills/finalize-plan/references/write-completions.md` | Step 5 spec/legacy mode, Step 6 delivery | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Core plus step names | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/references/resolve-and-preconditions.md` | Steps 0–2: todos, resolution priority, completed gate | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/gather-evidence.md` | Steps 3–7: parse, slug, inspect files, git history | Created |
| `kit/plugins/plan-agent/skills/documenting-plans/references/doc-template.md` | Step 8 document template and Step 9 report table | Created |
| `kit/plugins/plan-agent/skills/plan-status/SKILL.md` | Core plus step names | Modified |
| `kit/plugins/plan-agent/skills/plan-status/references/single-file-flow.md` | Steps 0–4, 6–7: resolution, evidence scoring, write rules | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/bulk-mode.md` | Directory/`--all` seven-stage flow | Created |
| `kit/plugins/plan-agent/skills/plan-status/references/type-classification.md` | Step 5 signal-to-type table | Created |
| `kit/plugins/plan-agent/skills/setup-sites/SKILL.md` | Core plus step names | Modified |
| `kit/plugins/plan-agent/skills/setup-sites/references/preflight.md` | Steps 1–3: git/remote derivation, sanity checks | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/scaffold.md` | Step 4: four idempotent artifacts, hub placeholder rules | Created |
| `kit/plugins/plan-agent/skills/setup-sites/references/enable-and-verify.md` | Steps 5–7: Pages enablement, verification block | Created |
| `tests/plugins/test-progressive-disclosure.sh` | Objective test: word ceiling + link integrity in both directions | Created |
| `tests/plugins/test-build-skill.sh` | Section extractors updated to search across SKILL.md and references/ | Modified |
| `tests/plugins/test-finalize-all-flag.sh` | Same update for --all sweep assertions | Modified |
| `tests/plugins/test-setup-sites.sh` | Same update for scaffold assertions | Modified |
| `.github/workflows/check-plugin-versions.yml` | Added step for progressive disclosure test | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 7.5.0 → 7.6.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 7.6.0 entry | Modified |

## How it works

A SKILL.md body is loaded in full every time the skill triggers — there is no partial load, no lazy paragraph. Before this change, five plan-agent skills totaled 10,776 words in their SKILL.md files, all paid on every invocation. `build` alone was 2,907 words; its Step 1b "no-plan chain" ran to ~60 lines but fired only when the skill was invoked with no plan named, meaning every ordinary `/plan-agent:build docs/plans/x.md` paid for it without reading it.

The progressive-disclosure pattern was already proven inside the same plugin. `kit/plugins/plan-agent/skills/implementation-plan/` shipped a core that explicitly says "read the full file when the step calls for it, not all up front" and backed it with `guidelines/` and `reference/` directories. This plan applied that pattern to the five high-cost skills, using the `references/` spelling already whitelisted by `build-dist.mjs`.

Each split follows the same structure: the SKILL.md core holds the trigger condition, argument summary, step names with links to their reference file, and any subroutine called by every step (such as `build`'s four-line re-render block). Detail that matters only in a particular context — the `--all` sweep mode, the bulk-mode seven-stage flow, the document template, the completion gates — moves to a named `references/<topic>.md` file that the step links explicitly.

The risk of silent behavior change was mitigated by the existing test suite. `tests/plugins/test-build-skill.sh` already pinned 18 checks against `build`'s exact contract phrases (the Step 1b delegation calls, the discovery cap, the misparse note, the AskUserQuestion-unavailable fallback). Those tests were updated so their section extractors search `SKILL.md` and every `references/*.md` in the skill directory for the owning heading, then re-run unchanged. A dropped rule makes the test fail; relaxing the assertion to match the new layout is not permitted.

Dangling and orphaned references are caught by `tests/plugins/test-progressive-disclosure.sh`, which asserts both directions: every `references/*.md` on disk is linked from its SKILL.md (no orphans), and every `references/<name>.md` mentioned in a SKILL.md resolves to an existing file (no dangling links). A skill with an unlinked reference file or a link to a nonexistent file fails the test.

The tautology of the objective test was verified three times: appending filler past the 600-word ceiling fails the word check; deleting a reference file link creates an orphan; adding a link to a nonexistent filename creates a dangling link. All three produce a non-zero exit with a named failure.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f3be024` | 2026-09-09 | feat(plan-agent): make the plan the dispatch contract — lanes in the renderer, authoring, and build (9.14.0–9.17.0) (#628) |
| `17114d5` | 2026-08-25 | feat(plan-agent): card artifact-only plans in the plans gallery (9.7.0) (#601) |
| `94c0569` | 2026-08-23 | feat(plan-agent): add design phase — canvas link, gallery, and drift check (#596) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [split-plan-agent-skills.md](plans/split-plan-agent-skills.md)
