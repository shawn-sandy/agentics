# Harden plan-documenter completion guard

> Tightens the completion gate in the plan-documenter agent and documenting-plans skill against edge cases in frontmatter parsing, casing, and fixed read-window size.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [harden-plan-documenter-completion-guard.md](plans/harden-plan-documenter-completion-guard.md)
**Type:** fix

## What shipped

- Switched `plan-documenter.md` Step 2 from a fixed 10-line read to delimiter-based frontmatter reading (read until the closing `---`)
- Added explicit frontmatter-boundary and casing rules: parse only between `---` delimiters, require lowercase `status: completed`, skip files without frontmatter delimiters
- Added edge-case documentation to `plan-documenter.md`: no YAML frontmatter → skip, non-standard casing → skip, `status` appearing in body text → ignore
- Added frontmatter-boundary clarification to `documenting-plans/SKILL.md` Step 2 to align with the agent's explicit rules
- Removed the undocumented `--overwrite` flag from the agent's skill invocation (the agent already pre-filters existing docs in Step 3)

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/agents/plan-documenter.md` | Batch agent — delimiter-based read, casing rule, edge-case section, removed `--overwrite` flag | Modified |
| `kit/plugins/plan-agent/skills/documenting-plans/SKILL.md` | Single-plan skill — frontmatter-boundary clarification in Step 2 | Modified |

## How it works

Both components — the `plan-documenter` batch agent and the `documenting-plans` single-plan skill — already gated on `status: completed` before this change. No completed-plan-only violations existed in the tree. The plan addressed four minor ambiguities that made the gate fragile against edge cases without changing the overall double-gate design.

The first ambiguity was the fixed line count. The agent read "the first 10 lines" to extract frontmatter. Any plan with more than roughly seven frontmatter fields would have its `status:` line fall outside the read window, causing a completed plan to be silently skipped. Switching to delimiter-based reading — "read until the closing `---`" — handles any frontmatter length without requiring a magic number to be maintained.

The second ambiguity was the absence of a boundary rule. Without an explicit instruction to parse only between the `---` delimiters, a model could legitimately match `status: completed` appearing in a plan's body text (for example, in a table column or a quoted block) and incorrectly identify the plan as completed. The added rule explicitly scopes the parse to the YAML frontmatter block and instructs the agent to skip files that have no opening `---` delimiter at all.

The third ambiguity was casing. The check was a string match against `status: completed` but the rule did not say so explicitly. The added one-sentence casing rule prevents `Status: Completed` (title case) or `STATUS: COMPLETED` (all-caps) from passing the gate, keeping the check aligned with the canonical frontmatter convention used everywhere in this repo.

The `--overwrite` flag cleanup removed a documentation mismatch. The agent was passing `--overwrite` to `documenting-plans`, which does not define that argument. The skill likely ignored the unknown argument, so there was no functional defect — the agent's own Step 3 pre-filters existing docs before calling the skill, making the flag redundant. Removing it eliminates the confusion about what the agent actually controls.

The design decision confirmed during the plan interview was to use silent skips for all edge cases in the batch agent, with no `plan-status` fallback for files missing frontmatter. Plans without frontmatter that are actually completed will remain undocumented until someone manually runs `plan-status` on them. This is the accepted trade-off: the batch agent is a sweep tool and adding interactive fallbacks would break its silent-by-default contract.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [harden-plan-documenter-completion-guard.md](plans/harden-plan-documenter-completion-guard.md)
