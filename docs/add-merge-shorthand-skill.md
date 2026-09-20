# Formalize the merge? shorthand as a git-agent skill + prompt hook

> The "merge?" shorthand currently lives only in a private memory note that may or may not fire. This plan promotes it into a git-agent skill with a determinis...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
**Type:** feature

## What shipped

- Create `kit/plugins/git-agent/skills/merge/SKILL.md` with frontmatter matching sibling skills (`name: merge`, three-part description ≤200 chars with trigger phrases like "merge?" and "is this ready to merge", `allowed-tools: Bash(git *), Bash(gh *), Bash(glab *), Read, Grep, Glob, ToolSearch, ExitPlanMode`). Logic from the retired memory note: run `gh pr view --json state,mergeable,statusCheckRollup` (or `gh pr list` when no PR for the branch); if the PR is MERGEABLE and required checks pass, run a local lint gate before merging — detect the project's first non-`fix`, non-`watch` `lint*` script (the `ship-autonomous` Step 2.5 precedent) and run it; no script found → skip with a one-line note; lint fails → do not merge, print the failures and ask (never auto-`--fix` — fixed files would change the PR head). Lint green → show the check summary, review decision, and unresolved-thread count, and ask for explicit merge approval via `AskUserQuestion` (green checks alone never authorize a merge — the `ship-autonomous` Step 8 precedent). On approval, pin the merge to the verified commit: `gh pr merge --squash --match-head-commit <headRefOid>` — non-interactive, and it fails rather than landing commits that arrived after verification. Never `--delete-branch`; branch deletion needs its own separate yes. If checks are pending, failing, or anything is ambiguous, print the status summary and ask before acting. Include a Step 0 ExitPlanMode self-bootstrap like sibling skills.
- Create `kit/plugins/git-agent/hooks/merge-shorthand.py` — read the hook JSON from stdin, and only when the prompt matches `^\s*merge\?\s*$` (case-insensitive) emit `additionalContext` instructing Claude to run the `git-agent:merge` skill; exit 0 silently on every other prompt. Wire it in a new `kit/plugins/git-agent/hooks.json` with a `UserPromptSubmit` entry using `${CLAUDE_PLUGIN_ROOT}` and a short timeout, mirroring `kit/plugins/plan-agent/hooks.json` structure.
- Add `tests/plugins/test-merge-shorthand.sh` following the existing `tests/plugins/test-*.sh` conventions: assert the hook script fires on `merge?`, ` merge? ` (surrounding whitespace), and `MERGE?` (case-insensitive), and stays silent on every near-miss — `merge` (no `?`), `please merge?`, `merge? now`, and prose containing "merge?" mid-sentence — asserts hooks.json is valid JSON referencing the script, and greps SKILL.md for the readiness-check contract (MERGEABLE gate, lint gate before merge with no auto-fix, no `--delete-branch`, ask-when-not-ready).
- Bump `git-agent` to `4.4.0` in `.claude-plugin/marketplace.json` (new skill + hook = MINOR), add a v4.4.0 entry to `kit/plugins/git-agent/CHANGELOG.md` describing the skill, hook, and test, and document the `merge` skill and `merge?` shorthand in `kit/plugins/git-agent/README.md` and the plugin table row in `CLAUDE.md`.
- Retire the memory note `~/.claude/projects/-Users-shawnsandy-devbox-agentics/memory/feedback_merge_behavior.md` by replacing its body with a one-line pointer to the shipped skill (keep the frontmatter, note the behavior now lives in `git-agent:merge`), and update the corresponding line in `MEMORY.md`.

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

Typing `merge?` works today only through a 50-day-old memory note (`feedback-merge-behavior`) — model-discretion recall, invisible to other machines, unverifiable. The proposal at `docs/proposals/formalize-merge-shorthand.md` locked the activation decision: skill + prompt hook. The skill holds the logic and is explicitly invocable as

The implementation proceeded through the following steps: Create `kit/plugins/git-agent/skills/merge/SKILL.md` with frontmatter matching sibling skills (`name: merge`, three-part description ≤200 chars with trigger phrases like "merge?" and "is this ready to merge", `allowed-tools: Bash(git *), Bash(gh *), Bash(glab *), Read, Grep, Glob, ToolSearch, ExitPlanMode`). Logic from the retired memory note: run `gh pr view --json state,mergeable,statusCheckRollup` (or `gh pr list` when no PR for the branch); if the PR is MERGEABLE and required checks pass, run a local lint gate before merging — detect the project's first non-`fix`, non-`watch` `lint*` script (the `ship-autonomous` Step 2.5 precedent) and run it; no script found → skip with a one-line note; lint fails → do not merge, print the failures and ask (never auto-`--fix` — fixed files would change the PR head). Lint green → show the check summary, review decision, and unresolved-thread count, and ask for explicit merge approval via `AskUserQuestion` (green checks alone never authorize a merge — the `ship-autonomous` Step 8 precedent). On approval, pin the merge to the verified commit: `gh pr merge --squash --match-head-commit <headRefOid>` — non-interactive, and it fails rather than landing commits that arrived after verification. Never `--delete-branch`; branch deletion needs its own separate yes. If checks are pending, failing, or anything is ambiguous, print the status summary and ask before acting. Include a Step 0 ExitPlanMode self-bootstrap like sibling skills. Why: the skill is the single reviewable home for the behavior, replacing prose in a private memory file. Verify: file exists, frontmatter parses, description is ≤200 chars (`python3 tests/plugins/measure_description_budget.py` or manual count), and the body forbids `--delete-branch`.; Create `kit/plugins/git-agent/hooks/merge-shorthand.py` — read the hook JSON from stdin, and only when the prompt matches `^\s*merge\?\s*$` (case-insensitive) emit `additionalContext` instructing Claude to run the `git-agent:merge` skill; exit 0 silently on every other prompt. Wire it in a new `kit/plugins/git-agent/hooks.json` with a `UserPromptSubmit` entry using `${CLAUDE_PLUGIN_ROOT}` and a short timeout, mirroring `kit/plugins/plan-agent/hooks.json` structure. Why: the hook makes the 6-char shorthand deterministic instead of best-effort memory recall. Verify: `echo '{"prompt":"merge?"}' | python3 kit/plugins/git-agent/hooks/merge-shorthand.py` emits the routing context, and `echo '{"prompt":"how do merges work"}' | python3 ...` emits nothing; `python3 -m json.tool kit/plugins/git-agent/hooks.json` passes.; Add `tests/plugins/test-merge-shorthand.sh` following the existing `tests/plugins/test-*.sh` conventions: assert the hook script fires on `merge?`, ` merge? ` (surrounding whitespace), and `MERGE?` (case-insensitive), and stays silent on every near-miss — `merge` (no `?`), `please merge?`, `merge? now`, and prose containing "merge?" mid-sentence — asserts hooks.json is valid JSON referencing the script, and greps SKILL.md for the readiness-check contract (MERGEABLE gate, lint gate before merge with no auto-fix, no `--delete-branch`, ask-when-not-ready). Why: the whole point of formalizing is verifiability — the test pins the trigger and the safety rules. Verify: `bash tests/plugins/test-merge-shorthand.sh` exits 0.; Bump `git-agent` to `4.4.0` in `.claude-plugin/marketplace.json` (new skill + hook = MINOR), add a v4.4.0 entry to `kit/plugins/git-agent/CHANGELOG.md` describing the skill, hook, and test, and document the `merge` skill and `merge?` shorthand in `kit/plugins/git-agent/README.md` and the plugin table row in `CLAUDE.md`. Why: repo convention — any plugin change requires a manual marketplace version bump plus changelog/docs. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` passes and `python3 -m json.tool .claude-plugin/marketplace.json` succeeds.; Retire the memory note `~/.claude/projects/-Users-shawnsandy-devbox-agentics/memory/feedback_merge_behavior.md` by replacing its body with a one-line pointer to the shipped skill (keep the frontmatter, note the behavior now lives in `git-agent:merge`), and update the corresponding line in `MEMORY.md`. Why: two sources of truth for the same behavior will drift; the plugin is now canonical. Verify: the memory file body references `git-agent:merge` and no longer carries standalone merge instructions..

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
- Issue: https://github.com/shawn-sandy/agentics/issues/436
