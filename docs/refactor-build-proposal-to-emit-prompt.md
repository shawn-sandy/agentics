# Make build-proposal converge on a saved prompt authored by write-prompt

> build-proposal currently ends by hand-writing a one-line handoff string, and the skill that exists to author prompts properly cannot be called at all. This wires the two together so a proposal converges on a real saved prompt.

<!-- generated:start -->

**Status:** Shipped 2026-07-29  **Plan:** [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/plan-agent/commands/write-prompt.md` — a thin wrapper that loads `skills/write-prompt/SKILL.md` by path (not via `Skill()`, which shadows itself when the command and skill share a name) to unblock programmatic invocation while keeping `disable-model-invocation: true` in the skill's frontmatter.
- Created `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` — a fifth prompt template with 11 placeholder slots (`{{TLDR}}`, `{{CONTEXT}}`, `{{CORE_FINDING}}`, `{{COMPARISON_TABLE}}`, `{{LOCKED_DECISIONS}}`, `{{WORKSTREAMS}}`, `{{RISKS}}`, `{{OPEN_QUESTIONS}}`, `{{ROADMAP}}`, `{{APPENDICES}}`, `{{CORE_INSTRUCTION}}`).
- Extended `write-prompt/SKILL.md` with the `proposal` type across Phases 1–4 and 7: type table row, technique matrix, XML layer mapping, template selection, `--out <path>` caller-supplied output path override, `status:`/`modified:`/`generated-sha:` frontmatter keys, and in-place rewrite with drift detection via `generated-sha:`.
- Added a pre-gathered-answers bypass to Phase 2 so `build-proposal` can skip the interview when decisions are already resolved.
- Rewrote `build-proposal/SKILL.md` Step 6 to dual-write: delegate to `write-prompt` with the `--out` path and bypass token, then additionally write a legacy `docs/proposals/<slug>.md` with a deprecation banner. Step 8 now hands off the `docs/prompts/` path rather than the proposal document.
- Retargeted `build/SKILL.md` Step 1b to the prompt path as the chained artifact.
- Added `proposal` as a fifth filter chip in `artifact-tools/skills/prompt-artifact/SKILL.md`, with tolerance for the new `status:` and `modified:` frontmatter keys.
- Added `tests/plugins/test-proposal-prompt-pipeline.sh` (objective test) and `tests/plugins/test-write-prompt-proposal-type.sh`; updated `tests/plugins/test-build-proposal.sh` and `tests/plugins/test-build-skill.sh`.
- Bumped plan-agent to 6.0.0 (major: removes the proposals artifact contract) and artifact-tools minor version.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/commands/write-prompt.md` | Command wrapper — loads skill by path, unblocks invocation | Missing (deleted post-6.1.0 cleanup or path changed) |
| `kit/plugins/plan-agent/skills/write-prompt/SKILL.md` | Write-prompt skill — fifth type, --out contract, drift detection | Missing (deleted post-6.1.0 cleanup or path changed) |
| `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` | Proposal template — 11 placeholder slots | Missing (deleted post-6.1.0 cleanup or path changed) |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Build-proposal skill — dual-write in Step 6, prompt handoff in Step 8 | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` | Artifact shape reference — slot mapping, bare-.md fix | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Build skill — Step 1b prompt path, abandonment contract | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Prompt artifact skill — fifth filter chip | Modified |
| `tests/plugins/test-proposal-prompt-pipeline.sh` | Objective test — end-to-end wiring assertions | Created |
| `tests/plugins/test-write-prompt-proposal-type.sh` | Unit test — fifth type through all phases | Created |
| `tests/plugins/test-build-proposal.sh` | Integration test — dual-write contract | Modified |
| `tests/plugins/test-build-skill.sh` | Integration test — Step 1b assertions | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin README — build-proposal and write-prompt sections | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 6.0.0 entry | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — plan-agent 5.0.0 → 6.0.0 | Modified |

## How it works

`build-proposal` previously ended by emitting a hand-crafted one-line invocation string for `implementation-plan`. Getting that string's grammar wrong dropped the receiving skill into conversion mode, producing a plan whose steps restated proposal headings rather than implementing it. The skill's own documentation warned against this in three places. The fix replaces that hand-crafted string with a real saved prompt file, authored by delegating to `write-prompt`.

The key blocker was mechanical: `disable-model-invocation: true` in `write-prompt/SKILL.md` blocks not just ambient auto-activation but also programmatic `Skill()` invocation. The two thin wrapper commands for `deep-grill` and `documenting-plans` work because those skills have separate names from their wrappers. `write-prompt` shares its name with the wrapper, which caused `Skill(skill: "plan-agent:write-prompt")` to return itself and never load the skill file. The fix: the wrapper loads `skills/write-prompt/SKILL.md` by filesystem path using a `Read` or `Glob` call, carrying a comment explaining the shadowing. Both new tests assert the by-path contract rather than the `Skill()` call.

The `--out <path>` contract in Phase 7 of `write-prompt/SKILL.md` solves a coordination problem: `write-prompt`'s Phase 7 independently derives a directory and a 3–5-word intent slug for its output path. `build-proposal` would independently compute a `proposal-{slug}.md` path. Without an explicit contract, the two sides derive different paths and no file is where either side expects it. The `--out` override bypasses Phase 7's directory resolution entirely; when it is present, the skill writes to exactly that path.

The proposal filename is deliberately date-free (`proposal-{verb-target-slug}.md`). A living document revised over two calendar days would otherwise resolve to a different filename on the second day.

The `generated-sha:` frontmatter key is what makes the round-two rewrite safe. Without a durable hash of what `write-prompt` last wrote, an uncommitted previous round is indistinguishable from a hand edit. With it, an exact match skips the confirmation prompt and a divergence triggers `AskUserQuestion` before overwriting.

Tier 0 proposals (thin ideas) continue to write no artifact of any kind. Tier 1 proposals emit a prompt populated only from a short subset of slots (`{{CONTEXT}}`, `{{CORE_FINDING}}`, `{{OPEN_QUESTIONS}}`, `{{CORE_INSTRUCTION}}`), with remaining slots omitted — not emitted as empty headings.

## How to use it

From a session with plan-agent loaded:
```text
/plan-agent:build-proposal <idea>
```
On completion, a saved prompt appears under `docs/prompts/proposal-<slug>.md` and a legacy copy under `docs/proposals/<slug>.md` (carrying a deprecation banner). Pass the `docs/prompts/` path to `implementation-plan` to start execution.

The prompt library gallery (via `prompt-artifact --library`) now shows a `proposal` filter chip for browsing proposal prompts.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
