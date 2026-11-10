# Formalize the merge? shorthand as a git-agent skill + prompt hook

> Promotes the `merge?` shorthand from a private memory note to a deterministic `git-agent:merge` skill and `UserPromptSubmit` hook, making PR readiness checks reliable on any machine with the plugin installed.

<!-- generated:start -->

**Status:** Shipped 2026-08-03 **Plan:** [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/skills/merge/SKILL.md` — PR readiness gate with guards, `gh pr checks --required`, and explicit user approval before merge
- Created `kit/plugins/git-agent/hooks/merge-shorthand.py` — `UserPromptSubmit` hook with anchored regex `^\s*merge\?\s*$` (case-insensitive), silent on all non-matching prompts
- Created `kit/plugins/git-agent/hooks.json` — wires the hook via `${CLAUDE_PLUGIN_ROOT}` under `UserPromptSubmit`, mirrors `plan-agent` precedent
- Added `tests/plugins/test-merge-shorthand.sh` — smoke test for hook trigger behavior (exact match, whitespace, uppercase) and safety contract (MERGEABLE gate, no `--delete-branch`, ask-when-not-ready)
- Bumped `git-agent` to `4.4.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry
- Documented the skill and shorthand in `kit/plugins/git-agent/README.md`
- Retired `feedback_merge_behavior.md` memory note to a pointer at `git-agent:merge`

**Note:** The plan specified a lint gate before merging. Commit `58ae32d` (2026-08-12) subsequently removed the lint gate from the merge skill (`refactor(git-agent): remove the lint gate from the merge skill (4.15.0)`). The current merge skill does not run a lint check before merging.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Merge readiness skill — guards, readiness gate, approval, merge command | Created |
| `kit/plugins/git-agent/hooks/merge-shorthand.py` | UserPromptSubmit hook — anchored `merge?` regex, silent otherwise | Created |
| `kit/plugins/git-agent/hooks.json` | Hook wiring — registers the UserPromptSubmit and PreToolUse hooks | Created |
| `tests/plugins/test-merge-shorthand.sh` | Smoke test — trigger cases, near-miss silence, SKILL.md contract | Created |
| `.claude-plugin/marketplace.json` | Plugin version registry — git-agent bumped to `4.4.0` | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Changelog — v4.4.0 entry describing skill, hook, and test | Modified |
| `kit/plugins/git-agent/README.md` | Plugin docs — merge skill and `merge?` shorthand documented | Modified |

## How it works

Before this change, typing `merge?` worked through a memory note (`feedback_merge_behavior.md`) that required the model to recall a 50-day-old entry on model discretion. This was invisible to other machines, unverifiable, and could silently fail.

The fix has two parts: a skill that holds the logic and a hook that holds the routing.

The `merge-shorthand.py` hook reads the full prompt from stdin as JSON and tests it against the anchored pattern `^\s*merge\?\s*$` with `re.IGNORECASE`. If the pattern matches, it emits a routing instruction to Claude to run `git-agent:merge`. On every other prompt — including prompts that merely contain the word "merge" — it exits 0 silently. The anchoring is critical: `please merge?`, `merge? now`, and `can you merge this?` all produce no output. Only the exact six characters `merge?` (with optional surrounding whitespace or case variation) trigger the routing.

The `hooks.json` wires this script under `UserPromptSubmit` using `${CLAUDE_PLUGIN_ROOT}` so the path resolves correctly on any installation. It also wires two `PreToolUse` hooks (`lint-before-commit.py` and `scope-guard.py`) that were already present in the plugin.

The `merge` skill (`skills/merge/SKILL.md`) runs a gated sequence. Step 0 handles plan-mode exit. Step 0.5 runs three guards before touching the PR: detached HEAD check (hard stop, with an exception when a PR was named explicitly), GitHub CLI auth check (hard stop), and dirty working tree check (ask, not stop — the merge is server-side so local edits cannot corrupt it, but the user should be aware they are not shipping those edits).

Step 1 finds the PR using `gh pr view --json url,number,state,mergeable,mergeStateStatus,reviewDecision,headRefOid`. Step 2 runs the readiness gate using `gh pr checks --required` rather than `statusCheckRollup` — the rollup mixes `CheckRun` and `StatusContext` node types with different field shapes, causing silent false-positive green reads for pending checks. The gate requires `mergeable: MERGEABLE`, `mergeStateStatus: CLEAN/UNSTABLE/HAS_HOOKS`, all required checks `SUCCESS` or `SKIPPED`, and `reviewDecision` not `CHANGES_REQUESTED`.

Even when all gates pass, the skill asks for explicit user approval before merging. The merge command pins to the verified commit: `gh pr merge --squash --match-head-commit <headRefOid>`. This non-interactive form fails rather than landing commits that arrived after the verification step. The skill never runs `--delete-branch` — branch deletion is a separate operation requiring its own explicit yes.

## How to use it

```bash
# Install the plugin
claude --plugin-dir ./kit/plugins/git-agent

# Run directly as a skill
/git-agent:merge

# Or use the 6-character shorthand (triggers via the UserPromptSubmit hook)
merge?
```

The skill reports the PR URL, check summary, review decision, and unresolved thread count before asking for approval. If anything is not green, it reports status and asks rather than proceeding.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a21acfb` | 2026-08-14 | Verify before asserting: merge guards, measured contrast ratios, review-finding reproduction (#552) |
| `58ae32d` | 2026-08-12 | refactor(git-agent): remove the lint gate from the merge skill (4.15.0) (#545) |
| `c071dac` | 2026-08-10 | fix(git-agent): make the commit lint gate trustworthy in every repo (4.14.0) (#544) |
| `dab833c` | 2026-08-05 | feat(git-agent): severity filter in Step 6c, mergeStateStatus in the merge gate (4.13.0) (#527) |
| `4a01a79` | 2026-08-03 | fix: replace eight unrunnable ${CLAUDE_PLUGIN_ROOT} Bash commands with bin/ wrappers (#520) |

<!-- generated:end -->

## References

- Plan: [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
- Proposal: `docs/proposals/formalize-merge-shorthand.md`
- Related docs: `kit/plugins/git-agent/skills/merge/SKILL.md`, `kit/plugins/git-agent/hooks/merge-shorthand.py`, `kit/plugins/git-agent/hooks.json`
