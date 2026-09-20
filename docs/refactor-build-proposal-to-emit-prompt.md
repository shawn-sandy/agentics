# Make build-proposal converge on a saved prompt authored by write-prompt

> build-proposal currently ends by hand-writing a one-line handoff string, and the skill that exists to author prompts properly cannot be called at all. This w...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
**Type:** refactor

## What shipped

- Create `kit/plugins/plan-agent/commands/write-prompt.md` mirroring `commands/deep-grill.md` exactly — frontmatter wit...
- Prove the invocation seam before building on it — from a session with the plugin loaded, invoke `/plan-agent:write-pr...
- Create `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` following the shape of the...
- Wire the `proposal` type through `kit/plugins/plan-agent/skills/write-prompt/SKILL.md` — add the fifth row to the Pha...
- Add a pre-gathered-answers bypass to `write-prompt` Phase 2 so a caller that has already interviewed the user skips t...
- Update `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` — add `proposal` as a fifth filter chip at lines...
- Rewrite `build-proposal`'s Step 6 to dual-write — invoke `write-prompt` with the proposal content and the Step 5 bypa...
- Preserve tier behavior across the refactor in `build-proposal/SKILL.md` — Tier 0 continues to answer directly and wri...
- Update `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` — add the section-to-slot mapping...
- Update `kit/plugins/plan-agent/skills/build/SKILL.md` Step 1b so the returned artifact is a prompt path — the `Skill(...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/commands/write-prompt.md` | thin Skill wrapper that unblocks programmatic invocation | Created |
| `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` | fifth template with proposal-shaped slots | Created |
| `kit/plugins/plan-agent/skills/write-prompt/SKILL.md` | fifth type across Phases 1, 2, 3, 4, 7 | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | dual-write in Step 6, prompt handoff in Step 8, --dir ret... | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` | slot mapping and the bare-.md handoff fix at line 102 | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Step 1b prompt path, dirty-tree exclusion, abandonment co... | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | fifth filter chip and tolerance for status/modified front... | Modified |
| `tests/plugins/test-proposal-prompt-pipeline.sh` | objective-verification test for the whole wiring | Created |
| `tests/plugins/test-write-prompt-proposal-type.sh` | unit coverage for the fifth type | Created |
| `tests/plugins/test-build-proposal.sh` | checks 10, 11, 14, 15 rewritten to the dual-write contract | Modified |
| `tests/plugins/test-build-skill.sh` | Step 1b assertions updated; runs in CI | Modified |
| `kit/plugins/plan-agent/README.md` | build-proposal and write-prompt sections, Plugin Structur... | Modified |
| `kit/plugins/artifact-tools/README.md` | prompt-artifact type list | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 6.0.0 entry | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | fifth-chip entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 5.0.0 to 6.0.0, artifact-tools minor bump | Modified |
| `CLAUDE.md` | plan-agent and artifact-tools table rows | Modified |
| `README.md` | build-proposal artifact path | Modified |

## How it works

Refactor build-proposal so its decision-complete output is a saved, copy-pasteable prompt under docs/prompts/, authored by delegating to write-prompt, while dual-writing the legacy docs/proposals/ document for one deprecation release. Ship the whole change as plan-agent 6.0.0.

`build-proposal` already ends by emitting a prompt — a hand-built one-line invocation string for `implementation-plan`. The skill spends an entire paragraph (`build-proposal/SKILL.md:207-214`), duplicated in `references/operating-principles.md:49` and `build/SKILL.md:185-188`, warning that getting that string's grammar wrong drops `implementation-plan` into conversion mode and yields a plan whose steps restate proposal headings. That is prompt authoring being done by hand, in prose, in triplicat...

The implementation proceeded through these steps: Create `kit/plugins/plan-agent/commands/write-prompt.md` mirroring `commands/deep-grill.md` exactly — frontmatter wit...; Prove the invocation seam before building on it — from a session with the plugin loaded, invoke `/plan-agent:write-pr...; Create `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` following the shape of the...; Wire the `proposal` type through `kit/plugins/plan-agent/skills/write-prompt/SKILL.md` — add the fifth row to the Pha...; Add a pre-gathered-answers bypass to `write-prompt` Phase 2 so a caller that has already interviewed the user skips t....

- Step 1 deviates from "mirror `commands/deep-grill.md` exactly" — a command shadows a skill of the same name in the `Skill` namespace, so a wrapper whose body is `Skill(skill: "plan-agent:write-prompt", ...)` returns itself and `SKILL.md` never loads; measured with a headless probe against the work

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
