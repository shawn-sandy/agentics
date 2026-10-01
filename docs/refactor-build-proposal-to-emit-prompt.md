# Make build-proposal converge on a saved prompt authored by write-prompt

> Wire build-proposal's output through the write-prompt skill so a completed proposal converges on a saved, copy-pasteable prompt under docs/prompts/, while dual-writing the legacy docs/proposals/ document for one deprecation release.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
**Type:** refactor

## What shipped

- Added a `proposal` type throughout `write-prompt/SKILL.md` — Phase 1 type table, technique matrix, Phase 3 XML layer mapping, Phase 4 template selection, and Phase 7 caller-supplied `--out <path>` contract, `status:`/`modified:`/`generated-sha:` frontmatter, and in-place rewrite with drift detection.
- Created `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` with 11 placeholder slots covering the proposal's structural sections (`{{TLDR}}`, `{{CONTEXT}}`, `{{CORE_FINDING}}`, `{{COMPARISON_TABLE}}`, `{{LOCKED_DECISIONS}}`, `{{WORKSTREAMS}}`, `{{RISKS}}`, `{{OPEN_QUESTIONS}}`, `{{ROADMAP}}`, `{{APPENDICES}}`, `{{CORE_INSTRUCTION}}`).
- Updated `build-proposal/SKILL.md` Step 6 to dual-write — invoke `write-prompt` with the `--out docs/prompts/proposal-{slug}.md` contract and also write a legacy copy under `docs/proposals/` carrying a deprecation banner.
- Added a pre-gathered-answers bypass to `write-prompt` Phase 2 so callers that already resolved decisions skip the interview.
- Updated `prompt-artifact/SKILL.md` to add `proposal` as a fifth filter chip and tolerate `status:` and `modified:` frontmatter keys.
- Updated `build/SKILL.md` Step 1b to reference the prompt path as the returned artifact.
- Fixed `build-proposal/references/artifact-shape.md` line 102 which advertised the bare-`.md` handoff the skill forbids.
- Added two new test files (`test-proposal-prompt-pipeline.sh`, `test-write-prompt-proposal-type.sh`) and updated `test-build-proposal.sh` and `test-build-skill.sh`.
- Bumped plan-agent from 5.0.0 to 6.0.0 in `marketplace.json`.

**Deviation:** The `commands/write-prompt.md` command wrapper was not shipped as a standard `Skill()` delegation. A headless probe found that a command shadowing a skill of the same name in the `Skill` namespace returns itself rather than loading the skill, so the wrapper loads `skills/write-prompt/SKILL.md` by path (with a `Glob` fallback) and documents the shadowing reason inline. The two test files assert the by-path contract rather than the presence of a `Skill()` call.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/write-prompt/SKILL.md` | Fifth proposal type wired through all phases | Modified |
| `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` | Proposal prompt template with 11 slots | Created |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Dual-write in Step 6, prompt handoff in Step 8 | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` | Section-to-slot mapping; bare-.md handoff fix | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Step 1b prompt path, dirty-tree exclusion | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Fifth filter chip and status/modified tolerance | Modified |
| `tests/plugins/test-proposal-prompt-pipeline.sh` | End-to-end objective verification test | Created |
| `tests/plugins/test-write-prompt-proposal-type.sh` | Unit coverage for the fifth type | Created |
| `tests/plugins/test-build-proposal.sh` | Checks 10, 11, 14, 15 rewritten to dual-write | Modified |
| `tests/plugins/test-build-skill.sh` | Step 1b assertions updated | Modified |
| `kit/plugins/plan-agent/README.md` | build-proposal and write-prompt sections | Modified |
| `kit/plugins/artifact-tools/README.md` | Prompt-artifact type list | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 6.0.0 entry | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Fifth-chip entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 5.0.0 → 6.0.0; artifact-tools minor bump | Modified |

## How it works

`build-proposal` previously ended by emitting a hand-built one-line `implementation-plan` invocation string. Three places in the codebase warned in prose that passing a bare `.md` path to `implementation-plan` drops it into conversion mode (the plan's headings become the implementation's steps). That was prompt authoring being done by hand, in triplicate.

The `write-prompt` skill is the canonical way to produce a saved prompt, but `disable-model-invocation: true` in its frontmatter blocked programmatic `Skill()` invocation. A command wrapper was the established in-repo fix, but a probe discovered that a command name matching its skill's name in the `Skill` namespace caused the wrapper to return itself — so the wrapper was changed to load `SKILL.md` by path rather than delegating through `Skill()`.

`write-prompt` gained a fifth `proposal` type with a dedicated 11-slot template. Phase 7 gained a `--out <path>` contract: when a caller supplies an explicit output path, `write-prompt` writes to exactly that path and skips its own directory resolution and intent-slug derivation. `build-proposal` Step 6 computes the path once as `docs/prompts/proposal-{slug}.md` (date-free so a multi-day loop resolves to the same file) and passes it via `--out`, so both sides agree by construction rather than independently deriving paths that could diverge.

A `generated-sha:` frontmatter key records what the skill last wrote. A second invocation against the same slug compares the current body hash to the recorded SHA: if the body is unchanged it overwrites silently; if the body was hand-edited it asks before overwriting. This makes the in-place rewrite rule real — an uncommitted previous round does not false-positive.

Tier 0 ideas continue to produce no artifact of either kind and trigger `build`'s "No proposal written" fall-through. Tier 1 ideas produce a prompt with only the short-subset slots populated and no empty slot headings. The dual-write (prompt authoritative, `docs/proposals/` copy carries a deprecation banner) is the 6.0.0 contract; the legacy proposals path is planned for removal in 6.1.0.

## How to use it

Invoke `/plan-agent:build-proposal <idea>` as before. The output in Step 6 is now a saved prompt under `docs/prompts/proposal-{slug}.md` in addition to the legacy proposal doc. Step 8 hands off the prompt path to `implementation-plan`.

To view or filter saved prompts, use `/artifact-tools:prompt-artifact --library` — the gallery now shows a `proposal` filter chip alongside the existing four types.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
