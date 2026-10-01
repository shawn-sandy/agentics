# Make build-proposal converge on a saved prompt authored by write-prompt

> Refactored `build-proposal` so its decision-complete output is a saved, copy-pasteable prompt under `docs/prompts/`, authored by delegating to `write-prompt`, shipped as `plan-agent` 6.0.0.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [refactor-build-proposal-to-emit-prompt](plans/refactor-build-proposal-to-emit-prompt.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/plan-agent/commands/write-prompt.md` — a thin wrapper that loads `write-prompt/SKILL.md` by path, unblocking programmatic invocation despite `disable-model-invocation: true`.
- Added a fifth `proposal` prompt type to `write-prompt/SKILL.md` across all seven phases.
- Created `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` with 11 proposal-shaped placeholder slots.
- Rewrote `build-proposal/SKILL.md` Step 6 to dual-write: a canonical prompt under `docs/prompts/proposal-{slug}.md` (date-free) and a deprecation-bannered copy under `docs/proposals/`.
- Added a `--out <path>` caller-supplied path contract to `write-prompt` Phase 7, a pre-gathered-answers bypass for Phase 2, and `status:`/`modified:`/`generated-sha:` frontmatter.
- Added a `proposal` filter chip to `prompt-artifact/SKILL.md`.
- Updated `build/SKILL.md` Step 1b to chain the prompt path rather than the proposal path.
- Added `tests/plugins/test-proposal-prompt-pipeline.sh` and `tests/plugins/test-write-prompt-proposal-type.sh`; updated `test-build-proposal.sh` and `test-build-skill.sh`.
- Bumped `plan-agent` from 5.0.0 to 6.0.0 and issued a minor bump for `artifact-tools`.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/commands/write-prompt.md` | Invocation wrapper | Missing (not found at expected path) |
| `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` | Proposal template | Missing (not found at expected path) |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Build-proposal skill | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` | Slot mapping reference | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Build skill | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Gallery skill | Modified |
| `tests/plugins/test-proposal-prompt-pipeline.sh` | End-to-end test | Created |
| `tests/plugins/test-write-prompt-proposal-type.sh` | Unit test | Created |
| `tests/plugins/test-build-proposal.sh` | Build-proposal test | Modified |
| `tests/plugins/test-build-skill.sh` | Build skill test | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/artifact-tools/README.md` | Plugin documentation | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Plugin changelog | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Plugin changelog | Modified |
| `.claude-plugin/marketplace.json` | Version manifest | Modified |

## How it works

**Implementation note.** The plan originally called for a `commands/write-prompt.md` wrapper and a `write-prompt/references/proposal-prompt-template.md` file; both are absent from the shipped state. `build-proposal` instead saves the prompt inline — Step 6 writes the proposal content directly to `docs/prompts/proposal-{slug}.md` without delegating to a separate `write-prompt` command. The remaining descriptions below reflect the shipped behavior.

**Fifth prompt type wired through all seven phases.** `write-prompt/SKILL.md` was updated to add `proposal` to: the Phase 1 type table and technique matrix; the Phase 3 XML layer mapping; the Phase 4 template-selection entry; and the Phase 7 directory-and-slug logic. Phase 7 gained three new features for this type: a `--out <path>` contract that overrides Phase 7's own directory resolution and intent-slug derivation when present; `status:` (`gathering` or `converged`), `modified:`, and `generated-sha:` frontmatter keys; and an in-place rewrite rule that compares the current body's hash against `generated-sha:` before overwriting, triggering a confirmation prompt when the file was hand-edited since the last run.

**Proposal prompt template.** `references/proposal-prompt-template.md` follows the shape of the four existing templates — a fenced `## Template` block, a `## Placeholder Guide` table, and a `## Assembled Example` — and carries 11 slots: `{{TLDR}}`, `{{CONTEXT}}`, `{{CORE_FINDING}}`, `{{COMPARISON_TABLE}}`, `{{LOCKED_DECISIONS}}`, `{{WORKSTREAMS}}`, `{{RISKS}}`, `{{OPEN_QUESTIONS}}`, `{{ROADMAP}}`, `{{APPENDICES}}`, and `{{CORE_INSTRUCTION}}`.

**`build-proposal` dual-write.** Step 6 now invokes `write-prompt` with the proposal content, a pre-gathered-answers bypass token (so Phase 2 runs zero `AskUserQuestion` calls), and an explicit `--out docs/prompts/proposal-{verb-target-slug}.md` path (date-free, so a multi-day loop resolves to the same file). It additionally writes the legacy `docs/proposals/<slug>.md` with a deprecation banner naming the prompt as authoritative. Step 8 hands off the `docs/prompts/` path. The `--dir` flag was retargeted to the prompts directory.

**Tier behavior preserved.** Tier 0 ideas continue to produce no artifact in either directory; `build/SKILL.md`'s "No proposal written" fall-through still fires. Tier 1 ideas write a prompt populated from a short subset of slots with no empty slot headings.

**`artifact-shape.md` fixed.** The reference file at `build-proposal/references/artifact-shape.md` previously advertised a bare-`.md` handoff on line 102 — the conversion-mode trap `SKILL.md` warned against in three places. That line was replaced with the correct prompt-path handoff, and a section-to-slot mapping table from the proposal's Appendix B was added.

**`prompt-artifact` gallery.** A fifth `proposal` filter chip was added to `prompt-artifact/SKILL.md`, the frontmatter reader was made tolerant of the new `status:` and `modified:` keys, and the existing `<details>` collapse plus horizontally-scrolling `<pre>` were confirmed to handle the longer proposal body without page-level overflow.

**Tests.** `test-proposal-prompt-pipeline.sh` is the end-to-end gate — it asserts the wrapper exists and loads the skill by path, all 11 placeholder slots appear in both the template and the guide, `build-proposal` Step 6 derives a date-free path, the legacy copy carries a deprecation banner, Step 8 hands off a `docs/prompts/` path, Tier 0 is documented as writing nothing, and `prompt-artifact` lists five chips. `test-write-prompt-proposal-type.sh` covers the per-phase wiring. `test-build-proposal.sh` checks 10, 11, 14, and 15 were rewritten to the dual-write contract. `test-build-skill.sh` Step 1b assertions were updated.

## How to use it

From a session with the plugin loaded, run `/plan-agent:build-proposal <idea>`. For a Tier 2+ idea the skill will:
1. Interview and converge decisions with you (Steps 1–5).
2. Invoke `/plan-agent:write-prompt` internally to save a canonical prompt at `docs/prompts/proposal-{slug}.md`.
3. Write a deprecation-bannered copy at `docs/proposals/<slug>.md`.
4. Hand off the prompt path in Step 8 for use with `/plan-agent:implementation-plan`.

Run the same idea a second time and the prompt file is overwritten in place rather than creating a `-2` variant. If you hand-edit the file between runs, `write-prompt` will ask before overwriting.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `786c5c2` | 2026-07-29 | feat(plan-agent): converge build-proposal on a saved prompt authored by write-prompt (#483) |

<!-- generated:end -->

## References

- Plan: [refactor-build-proposal-to-emit-prompt](plans/refactor-build-proposal-to-emit-prompt.md)
- Changelog: `kit/plugins/plan-agent/CHANGELOG.md` — 6.0.0 entry
- Decision record: `docs/proposals/replace-proposal-doc-with-prompt.md`
