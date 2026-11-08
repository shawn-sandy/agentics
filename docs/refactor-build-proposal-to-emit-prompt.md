# Make build-proposal converge on a saved prompt authored by write-prompt

> Refactor build-proposal so its decision-complete output is a saved, copy-pasteable prompt under docs/prompts/ authored by delegating to write-prompt, while dual-writing the legacy docs/proposals/ document for one deprecation release.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
**Type:** refactor

## What shipped

- Added a command wrapper at `kit/plugins/plan-agent/commands/write-prompt.md` that loads `skills/write-prompt/SKILL.md` by path (not via `Skill()` — the command-shadows-skill naming conflict required reading the file directly).
- Added a fifth `proposal` prompt type to `write-prompt/SKILL.md`, wired through all five phases, backed by a new `references/proposal-prompt-template.md` with eleven placeholder slots.
- Added a caller-supplied `--out <path>` contract to `write-prompt` Phase 7, allowing callers to dictate the output path rather than having both sides independently derive one.
- Added `status:` (`gathering`/`converged`), `modified:`, and `generated-sha:` frontmatter keys; `generated-sha:` enables an in-place rewrite drift check.
- Added a pre-gathered-answers bypass to Phase 2 so `build-proposal` can skip re-interviewing.
- Updated `build-proposal/SKILL.md` Steps 6 and 8 to dual-write: a prompt at `docs/prompts/proposal-{slug}.md` (authoritative, date-free filename) plus a legacy `docs/proposals/<slug>.md` with a deprecation banner.
- Updated `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` with a fifth `proposal` filter chip.
- Shipped four test files; bumped plan-agent to `6.0.0`.

> See [CHANGELOG v6.0.0](../kit/plugins/plan-agent/CHANGELOG.md) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/commands/write-prompt.md` | Command wrapper that unblocks programmatic invocation | Created |
| `kit/plugins/plan-agent/skills/prompt/references/proposal-prompt-template.md` | Fifth template with 11 proposal-shaped slots | Created |
| `kit/plugins/plan-agent/skills/prompt/SKILL.md` | Fifth `proposal` type wired through all phases | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Dual-write in Step 6, prompt handoff in Step 8, `--dir` retargeted | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` | Section-to-slot mapping table; bare-.md handoff bug fixed | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Step 1b prompt path, dirty-tree exclusion, abandonment contract | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Fifth `proposal` filter chip | Modified |
| `tests/plugins/test-proposal-prompt-pipeline.sh` | Objective-verification test for the whole wiring | Created |
| `tests/plugins/test-write-prompt-proposal-type.sh` | Unit coverage for the fifth type | Created |

## How it works

`build-proposal` already ended by emitting a hand-built one-line invocation string for `implementation-plan`. The same string was duplicated in three files and the instructions warned against getting its grammar wrong. `write-prompt` is the skill that exists to author prompts properly — the blocker was mechanical: `disable-model-invocation: true` blocks programmatic `Skill()` invocation, not just ambient auto-activation.

The command wrapper at `commands/write-prompt.md` works around the naming conflict: a command and a skill of the same name cause the `Skill()` call to return the command file (this file) rather than the skill, so the wrapper loads `skills/write-prompt/SKILL.md` by path using `Read` with a `Glob` fallback. Both new test files assert this by-path contract specifically.

The fifth `proposal` type carries eleven placeholder slots (`{{TLDR}}`, `{{CONTEXT}}`, `{{CORE_FINDING}}`, `{{COMPARISON_TABLE}}`, `{{LOCKED_DECISIONS}}`, `{{WORKSTREAMS}}`, `{{RISKS}}`, `{{OPEN_QUESTIONS}}`, `{{ROADMAP}}`, `{{APPENDICES}}`, `{{CORE_INSTRUCTION}}`) matching the section structure of a 326-line proposal. The `task` template's ten slots were too narrow for appendices, roadmap phasing, and risk tables.

The `--out <path>` contract in Phase 7 lets `build-proposal` dictate the exact output path rather than having both sides independently derive one. The filename is `proposal-{slug}.md` with no date — a living document spanning two calendar days would otherwise resolve to a different filename on day two. `created:` and `modified:` carry the dates instead.

`generated-sha:` stores a hash of what `write-prompt` last wrote. On a second run against the same slug, the skill compares the current body's hash against the stored value and asks via `AskUserQuestion` when they differ — distinguishing a hand edit from an uncommitted previous round.

Tier 0 builds continue to write no artifact. Tier 1 builds emit a prompt populated from a short subset of slots with no empty headings. The `build` skill's "No proposal written" fall-through still fires for Tier 0.

## How to use it

`/plan-agent:write-prompt` is now invocable directly:

```
/plan-agent:write-prompt --type proposal "my feature idea"
/plan-agent:write-prompt --type proposal --out docs/prompts/proposal-my-feature.md "my feature idea"
```

`build-proposal` automatically delegates to `write-prompt` and dual-writes both artifacts:
- `docs/prompts/proposal-{slug}.md` — authoritative saved prompt
- `docs/proposals/{slug}.md` — deprecated copy with banner

The prompt library gallery (`/artifact-tools:prompt-artifact --library`) now shows five filter chips including `proposal`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |
| `a2b4016` | 2026-09-13 | feat(plan-agent): build-proposal chooses an approach before it authors (9.18.0) (#634) |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |

<!-- generated:end -->

## References

- Plan: [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
- Decision record: docs/proposals/replace-proposal-doc-with-prompt.md
