# Make build-proposal converge on a saved prompt authored by write-prompt

> Refactors build-proposal so its decision-complete output is a saved, copy-pasteable prompt under docs/prompts/, authored by delegating to write-prompt, while dual-writing the legacy docs/proposals/ document for one deprecation release — shipped as plan-agent 6.0.0.

<!-- generated:start -->

**Status:** Shipped 2026-07-29 **Plan:** [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
**Type:** refactor

## What shipped

- Created the `write-prompt` command wrapper in `kit/plugins/plan-agent/commands/` to unblock programmatic invocation of `write-prompt/SKILL.md` (`disable-model-invocation: true` in its frontmatter blocked `Skill()` calls; the wrapper loads the skill file by path with a Glob fallback rather than via the `Skill` namespace, which would shadow the skill and return itself).
- Added `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` — a fifth prompt template carrying eleven placeholder slots (`{{TLDR}}`, `{{CONTEXT}}`, `{{CORE_FINDING}}`, `{{COMPARISON_TABLE}}`, `{{LOCKED_DECISIONS}}`, `{{WORKSTREAMS}}`, `{{RISKS}}`, `{{OPEN_QUESTIONS}}`, `{{ROADMAP}}`, `{{APPENDICES}}`, `{{CORE_INSTRUCTION}}`).
- Wired the `proposal` type through all five phases of `write-prompt/SKILL.md`: type table, technique matrix, XML layer mapping, template selection, and Phase 7 output — including a caller-supplied `--out <path>` contract, `status:`/`modified:`/`generated-sha:` frontmatter keys, and an in-place rewrite rule with drift detection via `generated-sha:`.
- Updated `build-proposal/SKILL.md` to dual-write in Step 6: invoke `write-prompt` with the proposal content and a pre-gathered-answers bypass token, pass an explicit `--out docs/prompts/proposal-{slug}.md` path (date-free, slug is the identity), and additionally write the legacy `docs/proposals/<slug>.md` with a deprecation banner; Step 8 hands off the `docs/prompts/` path.
- Updated `prompt-artifact/SKILL.md` to offer a fifth `proposal` filter chip and tolerate `status:` and `modified:` frontmatter keys.
- Added `tests/plugins/test-proposal-prompt-pipeline.sh` (objective end-to-end gate) and `tests/plugins/test-write-prompt-proposal-type.sh` (unit coverage for the fifth type); updated `test-build-proposal.sh` and `test-build-skill.sh`.
- Bumped plan-agent from 5.0.0 to 6.0.0 (MAJOR: artifact contract removed) and added an artifact-tools minor bump.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/commands/write-prompt.md` | Command wrapper enabling programmatic invocation | Relocated (renamed to `commands/prompt.md` in 6.1.0) |
| `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` | Fifth prompt template with 11 slots | Relocated (now under `skills/prompt/references/`) |
| `kit/plugins/plan-agent/skills/write-prompt/SKILL.md` | Fifth type wired through all five phases | Relocated (now `skills/prompt/SKILL.md`) |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Dual-write in Step 6, prompt handoff in Step 8 | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` | Slot mapping table; bare-.md handoff fix at line 102 | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Step 1b updated for prompt artifact path | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Fifth filter chip; tolerates new frontmatter keys | Modified |
| `tests/plugins/test-proposal-prompt-pipeline.sh` | Objective-verification test | Created |
| `tests/plugins/test-write-prompt-proposal-type.sh` | Unit coverage for fifth type | Created |
| `tests/plugins/test-build-proposal.sh` | Checks 10, 11, 14, 15 rewritten to dual-write contract | Modified |
| `tests/plugins/test-build-skill.sh` | Step 1b assertions updated | Modified |
| `kit/plugins/plan-agent/README.md` | build-proposal and write-prompt sections | Modified |
| `kit/plugins/artifact-tools/README.md` | prompt-artifact type list | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 6.0.0 entry | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Fifth-chip entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 5.0.0 → 6.0.0; artifact-tools minor bump | Modified |

## How it works

Before this refactor, `build-proposal` ended by emitting a hand-built one-line invocation string for `implementation-plan`. That string's grammar was documented across three files with a paragraph of warning each: getting it wrong drops `implementation-plan` into conversion mode and yields a plan whose steps restate proposal headings. That is prompt authoring done by hand, in prose, in triplicate — `write-prompt` is the skill that exists to do it properly.

The blocker was mechanical: `disable-model-invocation: true` in `write-prompt/SKILL.md`'s frontmatter blocks programmatic `Skill()` invocation, not just ambient auto-activation. The command wrapper is the established in-repo workaround. However, a command wrapper whose body is `Skill(skill: "plan-agent:write-prompt", ...)` shadows the skill of the same name in the `Skill` namespace, so the call returns itself and `SKILL.md` never loads. The shipped wrapper loads the skill file by path — `${CLAUDE_PLUGIN_ROOT}/skills/write-prompt/SKILL.md` — with a Glob fallback, and carries the reason for the deviation inline. This was discovered empirically via a headless probe: the shadowing shape put 0 `## Phase` headings in context; the by-path load put all 7.

Phase 7 of `write-prompt` was extended with a caller-supplied `--out <path>` contract. Without it, `write-prompt` resolves its own directory and derives its own 3-5-word intent slug, guaranteed to disagree with any independently computed path. Passing the path explicitly makes the two sides agree by construction. The filename is `proposal-{slug}.md` with no date, so a multi-day loop keeps resolving to the same file; `created:` and `modified:` carry the dates in frontmatter.

The `generated-sha:` frontmatter key makes the in-place rewrite drift check real. Without a durable record of what the skill last wrote, an uncommitted previous round is indistinguishable from a hand edit, and the check would either warn on every rewrite or silently clobber. With `generated-sha:`, a round-two run hashes the current body against the recorded SHA and asks via `AskUserQuestion` only when they differ.

Step 6's dual-write output — a `docs/prompts/` prompt and a `docs/proposals/` copy carrying a deprecation banner — gives one release cycle for dependents to update before the legacy path is removed in 6.1.0. Tier 0 ideas write nothing in either directory; Tier 1 ideas write a prompt with only the short subset of slots populated.

## How to use it

`/plan-agent:build-proposal <idea>` — the Step 6 output is now a saved prompt under `docs/prompts/proposal-{slug}.md`. Step 8 hands off that path. A `docs/proposals/<slug>.md` copy is also written with a deprecation banner for the 6.0.0 release cycle.

`/plan-agent:write-prompt` — now invocable as a command (the wrapper enables this). Accepts `--out <path>` to override directory resolution and intent-slug derivation. _(Historical 6.0.0 name; renamed to `/plan-agent:prompt` in 6.1.0.)_

`/artifact-tools:prompt-artifact --library` — the rendered gallery now offers five filter chips including `proposal`, and renders `type: proposal` cards.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `786c5c2` | 2026-07-29 | feat(plan-agent): converge build-proposal on a saved prompt authored by write-prompt (#483) |
| `3326586` | 2026-08-01 | refactor(plan-agent): rename write-prompt to prompt and calibrate it for Claude 5 (#509) |
| `14d66fd` | 2026-08-04 | feat(plan-agent): typed build entry points + fix the proposal-path conversion trap (8.5.0) (#523) |
| `301ba37` | 2026-06-18 | feat(plan-agent): add build-proposal skill (2.5.0) (#329) |

<!-- generated:end -->

## References

- Plan: [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
