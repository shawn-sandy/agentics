# Make build-proposal converge on a saved prompt authored by write-prompt

> build-proposal now delegates its decision-complete output to write-prompt, saving a proper saved prompt under docs/prompts/ while dual-writing the legacy docs/proposals/ document; shipped as plan-agent 6.0.0.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/plan-agent/commands/write-prompt.md` — a command wrapper that unblocks programmatic `Skill` invocation of `write-prompt` (which carries `disable-model-invocation: true`). The wrapper loads `SKILL.md` by path rather than using `Skill()` delegation, because a command shadows a skill of the same name in the `Skill` namespace.
- Added a fifth `proposal` prompt type to `write-prompt/SKILL.md` across all five phases, with a new `references/proposal-prompt-template.md` carrying 11 placeholder slots.
- Extended `write-prompt` Phase 7 with: a caller-supplied `--out <path>` contract, `status:`/`modified:`/`generated-sha:` frontmatter keys, and an in-place rewrite rule that detects hand edits via `generated-sha:` before overwriting.
- Added a pre-gathered-answers bypass to `write-prompt` Phase 2 so callers that have already interviewed the user skip the interview batch.
- Updated `build-proposal/SKILL.md` to dual-write: invoke `write-prompt` with the proposal content and derive a date-free `proposal-{slug}.md` path passed via `--out`, and additionally write a legacy `docs/proposals/` copy with a deprecation banner.
- Updated `build-proposal`'s Step 8 to hand off the `docs/prompts/` path and lead with objective text (not a bare `.md` token).
- Added `proposal` as a fifth filter chip in `artifact-tools/skills/prompt-artifact/SKILL.md`.
- Updated `build/SKILL.md` Step 1b for the new artifact type.
- Added four test scripts: `test-proposal-prompt-pipeline.sh`, `test-write-prompt-proposal-type.sh`, updated `test-build-proposal.sh` and `test-build-skill.sh`.
- Bumped plan-agent to 6.0.0 with a CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/commands/write-prompt.md` | Command wrapper enabling programmatic Skill invocation | Missing (post-plan relocation; wrapper may have been superseded) |
| `kit/plugins/plan-agent/skills/write-prompt/SKILL.md` | Prompt-authoring skill with fifth proposal type | Missing (may have been restructured) |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Build-proposal skill — dual-write and prompt handoff | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 6.0.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 5.0.0 → 6.0.0 | Modified |

## How it works

`build-proposal` already ended by emitting a prompt — a hand-built one-line invocation string for `implementation-plan`. The problem was that prompt authoring was being done by hand, in prose, in triplicate (`SKILL.md`, `references/operating-principles.md`, and `build/SKILL.md`), while `write-prompt` is the skill that exists to do it properly. The blocker was mechanical: `disable-model-invocation: true` in `write-prompt/SKILL.md` blocked programmatic `Skill` invocation, not only ambient auto-activation.

The fix was a command wrapper (`commands/write-prompt.md`) — a 15-line file mirroring `commands/deep-grill.md`. However, the completion notes record a critical finding: a command shadows a skill of the same name in the `Skill` namespace, so the naive `Skill(skill: "plan-agent:write-prompt", ...)` wrapper returned itself and `SKILL.md` never loaded. The shipped wrapper instead loads `SKILL.md` by path (with a Glob fallback) and documents the shadowing reason inline. Both new test files (`test-proposal-prompt-pipeline.sh`, `test-write-prompt-proposal-type.sh`) assert the by-path contract.

The `proposal` type was wired through all five phases of `write-prompt`, with `references/proposal-prompt-template.md` carrying 11 placeholder slots (`{{TLDR}}`, `{{CONTEXT}}`, `{{CORE_FINDING}}`, `{{COMPARISON_TABLE}}`, `{{LOCKED_DECISIONS}}`, `{{WORKSTREAMS}}`, `{{RISKS}}`, `{{OPEN_QUESTIONS}}`, `{{ROADMAP}}`, `{{APPENDICES}}`, `{{CORE_INSTRUCTION}}`). The template maps directly to the proposal's section structure without compressing it into the existing `task` template's 10 slots.

`build-proposal` passes an explicit `--out` path to `write-prompt` (derived as `proposal-{slug}.md` with no date, so a multi-day loop resolves to the same file). This is deliberate: `write-prompt`'s own Phase 7 would otherwise resolve a different directory and slug, disagreeing with what `build-proposal` reports. The date is omitted from the filename for the same reason — `created:` and `modified:` frontmatter carry the dates. The `generated-sha:` key enables drift detection: a hand-edited prompt triggers a confirmation prompt before the next round overwrites it, while an untouched uncommitted file does not.

Tier 0 (`build-proposal` answering directly for very small ideas) continues to write no artifact of either kind. Tier 1 emits a prompt populated from only the short-subset slots, with the remaining slots omitted rather than emitted empty.

## How to use it

```
/plan-agent:build-proposal <idea>              # produces docs/prompts/proposal-<slug>.md
/plan-agent:build-proposal <idea> --dir /path  # retargets the prompts directory
/plan-agent:write-prompt                       # authoring a prompt directly (any type)
```

The `prompt-artifact` skill's gallery now offers five filter chips including `proposal`:

```
/artifact-tools:prompt-artifact --library      # shows all saved prompts with proposal chip
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `43d18eec` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `a2b40163` | 2026-09-13 | feat(plan-agent): build-proposal chooses an approach before it authors (9.18.0) (#634) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
- Decision record: `docs/proposals/replace-proposal-doc-with-prompt.md`
