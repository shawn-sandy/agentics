# Formalize the merge? shorthand as a git-agent skill + prompt hook

> The "merge?" shorthand currently lives only in a private memory note that may or may not fire. This plan promotes it into a git-agent skill with a determinis...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
**Type:** feature

## What shipped

- Create `kit/plugins/git-agent/skills/merge/SKILL.md` with frontmatter matching sibling skills (`name: merge`, three-p...
- Create `kit/plugins/git-agent/hooks/merge-shorthand.py` — read the hook JSON from stdin, and only when the prompt mat...
- Add `tests/plugins/test-merge-shorthand.sh` following the existing `tests/plugins/test-*.sh` conventions: assert the...
- Bump `git-agent` to `4.4.0` in `.claude-plugin/marketplace.json` (new skill + hook = MINOR), add a v4.4.0 entry to `k...
- Retire the memory note `~/.claude/projects/-Users-shawnsandy-devbox-agentics/memory/feedback_merge_behavior.md` by re...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | merge-readiness skill: check → merge or ask | Created |
| `kit/plugins/git-agent/hooks/merge-shorthand.py` | UserPromptSubmit script, anchored match on `merge?` | Created |
| `kit/plugins/git-agent/hooks.json` | hook wiring, mirrors plan-agent precedent | Created |
| `tests/plugins/test-merge-shorthand.sh` | smoke test for hook + skill contract | Created |
| `.claude-plugin/marketplace.json` | git-agent 4.3.0 → 4.4.0 | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v4.4.0 entry | Modified |
| `kit/plugins/git-agent/README.md` | document the merge skill and shorthand | Modified |

## How it works

Add a `merge` skill to the `git-agent` plugin (check PR readiness → merge if green, otherwise surface status and ask) and a `UserPromptSubmit` hook that deterministically routes the literal prompt `merge?` to that skill.

Typing `merge?` works today only through a 50-day-old memory note (`feedback-merge-behavior`) — model-discretion recall, invisible to other machines, unverifiable. The proposal at `docs/proposals/formalize-merge-shorthand.md` locked the activation decision:

The implementation proceeded through these steps: Create `kit/plugins/git-agent/skills/merge/SKILL.md` with frontmatter matching sibling skills (`name: merge`, three-p...; Create `kit/plugins/git-agent/hooks/merge-shorthand.py` — read the hook JSON from stdin, and only when the prompt mat...; Add `tests/plugins/test-merge-shorthand.sh` following the existing `tests/plugins/test-*.sh` conventions: assert the ...; Bump `git-agent` to `4.4.0` in `.claude-plugin/marketplace.json` (new skill + hook = MINOR), add a v4.4.0 entry to `k...; Retire the memory note `~/.claude/projects/-Users-shawnsandy-devbox-agentics/memory/feedback_merge_behavior.md` by re....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
- Issue: https://github.com/shawn-sandy/agentics/issues/436
