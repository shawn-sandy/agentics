# Refactor build-proposal to emit prompts to docs/prompts/

> Moves build-proposal output from in-session prose to `docs/prompts/` files, adds a write-prompt skill type for proposals, and uses a date-free slug for stable multi-day loops — making proposals durable artifacts rather than transient session output.

<!-- generated:start -->

**Status:** Shipped 2026-07-29 **Plan:** [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
**Type:** refactor

## What shipped

- `build-proposal` output now writes to `docs/prompts/<slug>.md` (fifth write-prompt type).
- Added a `commands/write-prompt.md` wrapper that loads the skill by path, bypassing the `disable-model-invocation` limitation.
- Added `--out <path>` contract for caller-specified output path.
- Implemented dual-write during deprecation (writes both new and old locations).
- Date-free slug `proposal-<description>` for stable multi-day implementation loops.
- Bumped plan-agent to 6.0.0 in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Proposal skill | Modified |
| `kit/plugins/plan-agent/commands/write-prompt.md` | Command wrapper | Created |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Plugin registry | Modified |

## How it works

Previously, `build-proposal` wrote its output as session prose that the user had to copy. After this change, the proposal is a proper `docs/prompts/` file with a stable slug that survives session restarts and can be referenced by later build invocations.

The `write-prompt.md` wrapper exists to work around a quirk: the `Skill()` tool returns itself when a skill calls `Skill(skill: "plan-agent:write-prompt")` — a self-shadowing bug where the wrapper returned without loading `SKILL.md`. The fix is to have the wrapper load the skill file by path using `Read` rather than re-invoking it as a skill.

The date-free slug (`proposal-add-dark-mode-toggle`, not `proposal-2026-07-29-add-dark-mode-toggle`) means the same proposal can be referenced consistently across multiple days of implementation work without renaming.

The dual-write during deprecation lets existing workflows continue to see output in the old location while the new path becomes the canonical one — the old write is removed in a later cleanup pass.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
