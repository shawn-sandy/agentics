# Refactor build-proposal to emit a saved prompt

> build-proposal ended by hand-writing a one-line handoff string, while write-prompt — the skill that exists to author prompts properly — could not be called at all. This wires the two together so a proposal converges on a real saved prompt.

<!-- generated:start -->

**Status:** Shipped 2026-07-29 **Plan:** [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/plan-agent/commands/write-prompt.md`: a command wrapper that loads `write-prompt/SKILL.md` by path (bypassing the `disable-model-invocation` flag that blocked programmatic invocation); explains the skill-shadows-command naming conflict inline.
- Added `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md`: a fifth prompt template with 11 slots (`{{TLDR}}`, `{{CONTEXT}}`, `{{CORE_FINDING}}`, `{{COMPARISON_TABLE}}`, `{{LOCKED_DECISIONS}}`, `{{WORKSTREAMS}}`, `{{RISKS}}`, `{{OPEN_QUESTIONS}}`, `{{ROADMAP}}`, `{{APPENDICES}}`, `{{CORE_INSTRUCTION}}`).
- Updated `skills/write-prompt/SKILL.md`: wired the `proposal` type through Phases 1–4 and 7; added a `--out <path>` caller-supplied output path contract; added `status:`/`modified:`/`generated-sha:` frontmatter; replaced the `-2`/`-3` uniqueness guard with an in-place rewrite rule gated by `generated-sha:` drift detection; added a pre-gathered-answers bypass to Phase 2.
- Updated `skills/build-proposal/SKILL.md`: Step 6 dual-writes — invokes `write-prompt` with the bypass token and passes an explicit `--out docs/prompts/proposal-{slug}.md` path, plus writes a legacy `docs/proposals/<slug>.md` with a deprecation banner; Step 8 handoff names the prompts path and leads with objective text; `--dir` retargeted to the prompts directory.
- Updated `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md`: added `proposal` as a fifth filter chip; tolerates `status:` and `modified:` frontmatter.
- Updated `skills/build/SKILL.md` Step 1b to reference the prompt path as the returned artifact.
- Fixed `skills/build-proposal/references/artifact-shape.md` line 102: replaced bare-`.md` handoff with objective-led text.
- Added `tests/plugins/test-proposal-prompt-pipeline.sh` and `tests/plugins/test-write-prompt-proposal-type.sh`; updated `test-build-proposal.sh` and `test-build-skill.sh`.
- Bumped plan-agent to 6.0.0 and artifact-tools to a minor version.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/commands/write-prompt.md` | Invocable wrapper | Created |
| `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` | Fifth template | Created |
| `kit/plugins/plan-agent/skills/write-prompt/SKILL.md` | Proposal type + --out + generated-sha | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/SKILL.md` | Dual-write + --out handoff | Modified |
| `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` | Bare-.md fix | Modified |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Step 1b prompt path | Modified |
| `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` | Fifth chip + tolerant reader | Modified |
| `tests/plugins/test-proposal-prompt-pipeline.sh` | End-to-end pipeline test | Created |
| `tests/plugins/test-write-prompt-proposal-type.sh` | Fifth-type unit coverage | Created |
| `tests/plugins/test-build-proposal.sh` | Dual-write assertions | Modified |
| `tests/plugins/test-build-skill.sh` | Step 1b assertions | Modified |
| `.claude-plugin/marketplace.json` | plan-agent 6.0.0, artifact-tools minor | Modified |

## How it works

**Invocation blocker**: `disable-model-invocation: true` in `write-prompt/SKILL.md` blocked `Skill` calls from other skills. The command wrapper loads the skill file by path (via `Read` or `Glob`), bypassing the flag while keeping the ambient-activation suppression that the flag was placed there for.

**Explicit path contract**: `write-prompt`'s Phase 7 would independently derive its own directory and slug, disagreeing with what `build-proposal` computed. The `--out <path>` contract lets `build-proposal` compute the path once (`docs/prompts/proposal-{slug}.md`, date-free so multi-day loops don't create duplicates) and pass it explicitly.

**generated-sha drift detection**: A second pass now overwrites the same file in place. The `generated-sha:` frontmatter key records the hash of the last-generated body; if the body was hand-edited between runs, the skill asks before overwriting.

**Dual-write in 6.0.0**: Both `docs/prompts/proposal-{slug}.md` (authoritative) and `docs/proposals/<slug>.md` (deprecated, with banner) are written. The 6.1.0 plan removes the deprecated path after the deprecation window closes.

## How to use it

```
/plan-agent:build-proposal "My feature idea"
```

The proposal process continues as before; at Step 6 the skill now writes a saved prompt under `docs/prompts/` and a deprecated copy under `docs/proposals/`. The Step 8 handoff hands the prompt path to `build`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-07-29 | refactor(plan-agent): build-proposal converges on a saved prompt via write-prompt — proposal type, --out, dual-write (6.0.0) |

<!-- generated:end -->

## References

- Plan: [refactor-build-proposal-to-emit-prompt.md](plans/refactor-build-proposal-to-emit-prompt.md)
