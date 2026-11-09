# Formalize the merge? shorthand as a git-agent skill and prompt hook

> Promotes the `merge?` shorthand from a private memory note into a `git-agent` skill with a deterministic `UserPromptSubmit` hook, so typing `merge?` reliably checks PR readiness and merges when green — on any machine the plugin is installed.

<!-- generated:start -->

**Status:** Shipped 2026-07-20  **Plan:** [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/skills/merge/SKILL.md` with a merge-readiness workflow: check PR state via `gh pr view`, run the project's lint script (non-`fix`, non-`watch`) before merging, ask for explicit approval even when everything is green, and merge with `--match-head-commit <headRefOid>` to pin the verified commit.
- The skill never deletes the branch (`--delete-branch` is explicitly forbidden), never auto-fixes lint failures, and always asks rather than merging automatically.
- Created `kit/plugins/git-agent/hooks/merge-shorthand.py` — a `UserPromptSubmit` hook that matches the anchored regex `^\s*merge\?\s*$` (case-insensitive) and emits `additionalContext` routing to the `git-agent:merge` skill; all other prompts produce no output.
- Created `kit/plugins/git-agent/hooks.json` wiring the hook via `${CLAUDE_PLUGIN_ROOT}`, mirroring the `plan-agent/hooks.json` precedent.
- Added `tests/plugins/test-merge-shorthand.sh` asserting the hook fires on `merge?`, ` merge? ` (whitespace), and `MERGE?` (case), stays silent on near-misses (`merge`, `please merge?`, `merge? now`, prose containing "merge?" mid-sentence), validates the hooks.json wiring, and greps SKILL.md for the safety contract.
- Bumped `git-agent` to `4.4.0` in `.claude-plugin/marketplace.json` (new skill + hook = MINOR), added a `v4.4.0` CHANGELOG entry, documented the skill in the README and root `CLAUDE.md` plugin table.
- Retired the `~/.claude/projects/-Users-shawnsandy-devbox-agentics/memory/feedback_merge_behavior.md` memory note — replaced its body with a pointer to `git-agent:merge`.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Skill instructions | Created |
| `kit/plugins/git-agent/hooks/merge-shorthand.py` | UserPromptSubmit hook | Created |
| `kit/plugins/git-agent/hooks.json` | Hook wiring | Created |
| `tests/plugins/test-merge-shorthand.sh` | Smoke test | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Changelog | Modified |
| `kit/plugins/git-agent/README.md` | Plugin README | Modified |

## How it works

Before this change, typing `merge?` triggered behavior only through a 50-day-old memory note (`feedback-merge-behavior`), which is model-discretion recall: invisible to other machines, unverifiable, and silently lost when the context window doesn't include it. The proposal at `docs/proposals/formalize-merge-shorthand.md` locked the activation decision: a skill holds the logic and a prompt hook provides the ergonomic shorthand.

`merge-shorthand.py` reads the hook JSON from stdin and checks the prompt against `^\s*merge\?\s*$`. This regex is deliberately anchored — it matches only when `merge?` is the entire prompt (with optional surrounding whitespace, case-insensitive). Prompts that merely *contain* `merge?` mid-sentence emit nothing, so ordinary conversation about merge processes doesn't accidentally trigger the skill.

`SKILL.md` contains the merge-readiness logic: first call `gh pr view --json state,mergeable,statusCheckRollup` to check the PR state; if MERGEABLE with passing required checks, detect and run the project's first non-`fix`, non-`watch` lint script; if lint passes, show the check summary, review decision, and unresolved-thread count and ask for explicit merge approval via `AskUserQuestion`; on approval merge with `--match-head-commit <headRefOid>` — non-interactive and it fails rather than landing commits that arrived after verification. Branch deletion is explicitly excluded: it requires its own separate yes.

The `--match-head-commit` flag is critical: it pins the merge to the commit that was verified, so a push that arrives between the readiness check and the merge is rejected rather than silently merged.

The hooks.json file mirrors the `plan-agent/hooks.json` precedent exactly: a `UserPromptSubmit` entry referencing the Python script via `${CLAUDE_PLUGIN_ROOT}` with a short timeout.

## How to use it

Type `merge?` as a complete prompt (the slash command `/git-agent:merge` also works directly):

```text
merge?
```

The hook routes the prompt to the `git-agent:merge` skill, which checks the open PR for the current branch and either merges it (after explicit approval) or reports what's blocking it.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `0fd7b67` | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
