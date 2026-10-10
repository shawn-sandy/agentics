# Make build-proposal converge on a saved prompt authored by write-prompt

> Wires build-proposal to delegate its final output to write-prompt, producing a saved proposal prompt under docs/prompts/ as the authoritative artifact while dual-writing a legacy docs/proposals/ copy with a deprecation banner, shipped as plan-agent 6.0.0.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
**Type:** refactor

## What shipped

- Added `kit/plugins/plan-agent/commands/write-prompt.md` — a command wrapper that loads `skills/write-prompt/SKILL.md` by path, unblocking programmatic invocation around the `disable-model-invocation: true` constraint
- Added `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` with 11 placeholder slots for proposal-shaped prompts
- Extended `write-prompt/SKILL.md` with a fifth `proposal` type across all phases, a caller-supplied `--out <path>` contract, `status:`/`modified:`/`generated-sha:` frontmatter, an in-place rewrite rule with drift detection, and a pre-gathered-answers bypass token
- Updated `build-proposal/SKILL.md` to dual-write in Step 6 (invoke write-prompt with an explicit `--out` path; write the legacy proposals copy with a deprecation banner) and hand off the prompts path in Step 8
- Fixed `build-proposal/references/artifact-shape.md` line 102 to remove the bare-`.md` handoff that taught the conversion-mode trap
- Updated `build/SKILL.md` Step 1b to reference the prompt path rather than the proposal path
- Added a `proposal` filter chip to `artifact-tools/skills/prompt-artifact/SKILL.md`
- Added `tests/plugins/test-proposal-prompt-pipeline.sh` and `tests/plugins/test-write-prompt-proposal-type.sh`
- Updated `tests/plugins/test-build-proposal.sh` and `tests/plugins/test-build-skill.sh`
- Bumped plan-agent from 5.0.0 to 6.0.0 and artifact-tools to a minor bump

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/commands/write-prompt.md` | Command wrapper enabling programmatic invocation | Missing (may have been superseded) |
| `kit/plugins/plan-agent/skills/write-prompt/SKILL.md` | Fifth proposal type, --out contract, drift check | Missing (may have been superseded) |
| `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` | Proposal prompt template with 11 slots | Missing (may have been superseded) |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Dual-write in Step 6, prompt handoff in Step 8 | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` | Slot mapping table; bare-.md handoff fix | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Step 1b prompt path, dirty-tree exclusion | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Fifth filter chip; status/modified frontmatter tolerance | Modified |
| `tests/plugins/test-proposal-prompt-pipeline.sh` | Objective-verification test for the whole wiring | Created |
| `tests/plugins/test-write-prompt-proposal-type.sh` | Unit coverage for the fifth type | Created |
| `tests/plugins/test-build-proposal.sh` | Dual-write contract assertions | Modified |
| `tests/plugins/test-build-skill.sh` | Step 1b assertions | Modified |
| `kit/plugins/plan-agent/README.md` | Build-proposal and write-prompt sections | Modified |
| `kit/plugins/artifact-tools/README.md` | Prompt-artifact type list | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 6.0.0 entry | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Fifth-chip entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 5.0.0 → 6.0.0, artifact-tools minor bump | Modified |

## How it works

`build-proposal` previously ended by emitting a hand-built one-line invocation string for `implementation-plan`. The skill's own docs, plus references in `operating-principles.md` and `build/SKILL.md`, warned in triplicate that getting this string's grammar wrong silently dropped `implementation-plan` into conversion mode. This refactor replaces that hand-authored string with a proper saved prompt file under `docs/prompts/`, authored by delegating to the `write-prompt` skill.

The main blocker was mechanical: `disable-model-invocation: true` in `write-prompt/SKILL.md` blocks programmatic `Skill` invocation. The fix follows the established in-repo pattern — a thin command wrapper at `commands/write-prompt.md` loads the skill file by absolute path (via `Glob` fallback) rather than calling `Skill()`, because a wrapper whose body is `Skill(skill: "plan-agent:write-prompt", ...)` shadows the skill of the same name in the namespace and returns itself, loading zero phases into context. Both new test files assert the by-path contract explicitly.

The `proposal` type was threaded through all five phases of `write-prompt/SKILL.md`: the type table, the technique matrix, the XML layer mapping, the template-selection entry, and Phase 7's output rules. Phase 7 accepts a caller-supplied `--out <path>` that overrides its own directory resolution and intent-slug derivation entirely — this is necessary because `Skill()` has no documented return value, so the caller must dictate the path rather than both sides independently deriving one that would disagree. The filename is `proposal-{slug}.md` with no date, so a multi-day loop resolves to the same file rather than creating a `-2` variant.

`build-proposal` Step 6 computes the target path once as `{resolved-prompts-dir}/proposal-{verb-target-slug}.md` and passes it to `write-prompt` via `--out`. It additionally writes a legacy `docs/proposals/<slug>.md` carrying a deprecation banner naming the prompt as authoritative. Step 8 hands off the prompts path and leads with objective text rather than a bare `.md` token. Tier 0 ideas continue to write no artifact of either kind.

An in-place rewrite rule in `write-prompt` detects hand-edits before overwriting via a `generated-sha:` frontmatter key that records what the skill last wrote. An uncommitted previous round and a hand-edited file are distinguished correctly: only a body whose hash diverges from `generated-sha:` triggers a confirmation prompt.

The Completion Report noted one material deviation: the self-delegating wrapper shape was proven defective by a headless probe (0 `## Phase` headings loaded vs. 7 when the skill was read by path), and the test files were updated to require the by-path contract. `commands/deep-grill.md` and `commands/documenting-plans.md` carry the same defective shape and were flagged for a follow-up task.

## How to use it

After loading the plugin, invoke `/plan-agent:build-proposal <idea>`. A decision-complete run will produce a file under `docs/prompts/proposal-<slug>.md` with `type: proposal`, `status:`, and `modified:` frontmatter, plus a legacy copy at `docs/proposals/<slug>.md` carrying a deprecation notice. Re-running the same idea on a subsequent day overwrites the same file in place; the prompt is the living document.

To browse saved proposal prompts in the gallery, run `/artifact-tools:prompt-artifact --library`. The gallery offers five filter chips including `proposal`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
- Decision record: [docs/proposals/replace-proposal-doc-with-prompt.md](proposals/replace-proposal-doc-with-prompt.md)
