# Make build-proposal converge on a saved prompt authored by write-prompt

> Refactors `build-proposal` so its decision-complete output is a saved prompt under `docs/prompts/` authored by delegating to `write-prompt`, adds a fifth `proposal` prompt type, and dual-writes the legacy `docs/proposals/` document for one deprecation release. Ships as plan-agent 6.0.0.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [refactor-build-proposal-to-emit-prompt](plans/refactor-build-proposal-to-emit-prompt.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/plan-agent/commands/write-prompt.md` — a thin wrapper that loads `write-prompt/SKILL.md` by path, unblocking programmatic invocation while `disable-model-invocation: true` remains in the skill's frontmatter
- Added a fifth `proposal` prompt type to `write-prompt/SKILL.md` across Phases 1, 2, 3, 4, and 7
- Created `references/proposal-prompt-template.md` with 11 slots mapping proposal sections to prompt placeholders
- Rewrote `build-proposal` Step 6 to dual-write: invokes `write-prompt` (passing an explicit `--out` path so both sides agree), and also writes the legacy `docs/proposals/` document with a deprecation banner
- Added `--out <path>` caller-supplied override to `write-prompt` Phase 7, `status:`/`modified:`/`generated-sha:` frontmatter, and an in-place rewrite rule with drift detection
- Added `proposal` as a fifth filter chip to `prompt-artifact/SKILL.md`
- Bumped plan-agent to 6.0.0; artifact-tools minor bump
- Created `tests/plugins/test-proposal-prompt-pipeline.sh` and `tests/plugins/test-write-prompt-proposal-type.sh`

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/commands/write-prompt.md` | Command wrapper — by-path skill load | Created |
| `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` | Reference — fifth template | Created |
| `kit/plugins/plan-agent/skills/write-prompt/SKILL.md` | Skill — fifth type, --out contract, drift check | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Skill — dual-write Step 6, prompt handoff Step 8 | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` | Reference — section-to-slot mapping | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill — Step 1b prompt path | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Skill — fifth filter chip | Modified |
| `tests/plugins/test-proposal-prompt-pipeline.sh` | Smoke test — full pipeline | Created |
| `tests/plugins/test-write-prompt-proposal-type.sh` | Smoke test — fifth type wiring | Created |
| `.claude-plugin/marketplace.json` | Plugin registry — plan-agent 6.0.0 | Modified |

## How it works

`build-proposal` ended by emitting a hand-built one-line invocation string for `implementation-plan` — prompt authoring done by hand, in prose, duplicated in three places. `write-prompt` is the skill that exists to author prompts properly, but `disable-model-invocation: true` blocked programmatic `Skill` invocation for skills without a `commands/*.md` wrapper. The wrapper is the fix.

The command wrapper discovered a deeper problem: a wrapper whose body is `Skill(skill: "plan-agent:write-prompt")` returns itself (a command shadows a skill of the same name in the Skill namespace), so `write-prompt/SKILL.md` never loads. The wrapper was redesigned to load the skill file by path, with the reason documented inline.

The `--out` path contract solves the path-agreement problem: `Skill()` has no documented return value, and `write-prompt`'s own Phase 7 would otherwise derive a different directory and a different intent slug than `build-proposal` expects. Passing the path explicitly makes both sides agree by construction. The filename is `proposal-{verb-target-slug}.md` with no date so a multi-day loop keeps resolving to the same file.

The `generated-sha:` frontmatter key makes the drift check real: without a durable record of what the skill last wrote, an uncommitted previous round is indistinguishable from a hand edit. A round-two run checks the current body's hash against the recorded SHA and asks via `AskUserQuestion` only when they differ.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [refactor-build-proposal-to-emit-prompt](plans/refactor-build-proposal-to-emit-prompt.md)
