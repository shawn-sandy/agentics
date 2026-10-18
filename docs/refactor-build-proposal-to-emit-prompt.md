# Make build-proposal converge on a saved prompt authored by write-prompt

> Refactors build-proposal so its output is a saved prompt file under docs/prompts/ authored by delegating to write-prompt, with a dual-write deprecation copy, and adds a fifth proposal type across the prompt toolchain.

<!-- generated:start -->

**Status:** Shipped 2026-07-29  **Plan:** [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
**Type:** refactor

## What shipped

- Added `kit/plugins/plan-agent/commands/write-prompt.md` — a command wrapper that loads `skills/write-prompt/SKILL.md` by path (bypassing the `disable-model-invocation: true` flag that blocks programmatic `Skill()` invocation when a command shadows the skill name).
- Added `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` — fifth template with 11 placeholders: `{{TLDR}}`, `{{CONTEXT}}`, `{{CORE_FINDING}}`, `{{COMPARISON_TABLE}}`, `{{LOCKED_DECISIONS}}`, `{{WORKSTREAMS}}`, `{{RISKS}}`, `{{OPEN_QUESTIONS}}`, `{{ROADMAP}}`, `{{APPENDICES}}`, `{{CORE_INSTRUCTION}}`.
- Updated `kit/plugins/plan-agent/skills/write-prompt/SKILL.md` — wired the `proposal` type through Phases 1–4 and Phase 7; added caller-supplied `--out <path>` contract; added `status:`, `modified:`, `generated-sha:` frontmatter keys; added in-place rewrite rule with drift detection via `generated-sha:`; added pre-gathered-answers bypass token; added `proposal` type across the phase table, technique matrix, XML layer mapping, and template-selection entry.
- Updated `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` — Step 6 dual-writes prompt and legacy proposal copy; Step 8 hands off the `docs/prompts/` path; `--dir` retargeted to the prompts directory; Tier 0 writes no artifact; Tier 1 writes a short-subset prompt.
- Updated `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` — section-to-slot mapping table added; bare-`.md` handoff corrected.
- Updated `kit/plugins/plan-agent/skills/build/SKILL.md` Step 1b — prompt path reference, dirty-tree exclusion, abandonment contract updated.
- Updated `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` — fifth `proposal` filter chip; frontmatter reader tolerates `status:` and `modified:` keys.
- Added `tests/plugins/test-proposal-prompt-pipeline.sh` and `tests/plugins/test-write-prompt-proposal-type.sh`.
- Updated `tests/plugins/test-build-proposal.sh` checks 10, 11, 14, 15 and `tests/plugins/test-build-skill.sh` Step 1b assertions.
- Bumped plan-agent to `6.0.0` and artifact-tools to a minor version in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-agent/commands/write-prompt.md` | Command wrapper | Created |
| `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` | Proposal template | Created |
| `kit/plugins/plan-agent/skills/write-prompt/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` | Artifact shape reference | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Skill instructions | Modified |
| `tests/plugins/test-proposal-prompt-pipeline.sh` | Pipeline test | Created |
| `tests/plugins/test-write-prompt-proposal-type.sh` | Type unit test | Created |
| `tests/plugins/test-build-proposal.sh` | Build-proposal test | Modified |
| `tests/plugins/test-build-skill.sh` | Build skill test | Modified |
| `.claude-plugin/marketplace.json` | Marketplace versions | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Release notes | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Release notes | Modified |

## How it works

`build-proposal` previously ended by hand-writing a one-line invocation string for `implementation-plan`. The skill body warned in three separate places that getting the string's grammar wrong would drop `implementation-plan` into conversion mode. The fix delegates to `write-prompt`, the skill that exists to author prompts properly.

The primary mechanical blocker was that `disable-model-invocation: true` in `write-prompt/SKILL.md` blocks programmatic `Skill()` invocation. A `commands/write-prompt.md` wrapper loads the skill file by path (with a `Glob` fallback), bypassing the flag without removing it — ambient triggering on the word "prompt" stays suppressed.

The prompt path is derived deterministically as `{prompts-dir}/proposal-{verb-target-slug}.md` (date-free, slug is the identity) and passed to `write-prompt` via the `--out` contract, ensuring `build-proposal` and `write-prompt` agree on the file location by construction rather than both deriving it independently.

For the 6.0.0 release, `build-proposal` dual-writes: the authoritative prompt goes to `docs/prompts/`, and a legacy copy goes to `docs/proposals/` with a deprecation banner naming the prompt as authoritative. The `generated-sha:` frontmatter key in the prompt file lets the in-place rewrite rule distinguish an uncommitted previous round (silent overwrite) from a hand edit (confirmation prompt).

## How to use it

```
/plan-agent:build-proposal "my feature idea"
# writes docs/prompts/proposal-<slug>.md (authoritative)
# and  docs/proposals/<slug>.md (deprecated copy)
```

The proposal prompt can be viewed in the artifact gallery:
```
/artifact-tools:prompt-artifact --library
# shows five filter chips including "proposal"
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
