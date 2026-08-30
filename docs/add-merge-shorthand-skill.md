# Formalize the merge? shorthand as a git-agent skill

> Promotes the `merge?` shorthand from a private memory note to a `git-agent` skill with a deterministic `UserPromptSubmit` hook, so typing `merge?` reliably checks PR readiness and merges when green on any machine the plugin is installed.

<!-- generated:start -->

**Status:** Shipped 2026-08-12 **Plan:** [add-merge-shorthand-skill](plans/add-merge-shorthand-skill.md)
**Type:** feature

## What shipped

- New skill `kit/plugins/git-agent/skills/merge/SKILL.md` — PR readiness check, local lint gate, explicit merge approval via `AskUserQuestion`, and `--match-head-commit` merge
- New hook script `kit/plugins/git-agent/hooks/merge-shorthand.py` — anchored `^\s*merge\?\s*$` regex, emits `additionalContext` routing to `git-agent:merge`, silent on every other prompt
- New `kit/plugins/git-agent/hooks.json` wiring the hook under `UserPromptSubmit` via `${CLAUDE_PLUGIN_ROOT}`
- `tests/plugins/test-merge-shorthand.sh` smoke test covering hook trigger/silence behavior, `hooks.json` validity, and SKILL.md contract assertions
- `git-agent` bumped to `4.4.0`; CHANGELOG, README, and CLAUDE.md plugin table updated
- `feedback_merge_behavior` memory note replaced with a pointer to `git-agent:merge`

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Merge-readiness skill — check → merge or ask | Created |
| `kit/plugins/git-agent/hooks/merge-shorthand.py` | `UserPromptSubmit` hook — anchored regex, additionalContext routing | Created |
| `kit/plugins/git-agent/hooks.json` | Hook wiring — `UserPromptSubmit` entry, `${CLAUDE_PLUGIN_ROOT}`, short timeout | Created |
| `tests/plugins/test-merge-shorthand.sh` | Smoke test — hook trigger/silence, hooks.json validity, SKILL.md contract | Created |
| `.claude-plugin/marketplace.json` | `git-agent` 4.3.0 → 4.4.0 | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v4.4.0 entry | Modified |
| `kit/plugins/git-agent/README.md` | `merge` skill and `merge?` shorthand documented | Modified |

## How it works

The `merge?` shorthand previously relied on a memory note (`feedback_merge_behavior`) written 50 days before this plan was authored. Memory recall is model-discretion, machine-local, and invisible to auditors — three properties incompatible with a safety-critical merge gate.

`hooks/merge-shorthand.py` reads the hook JSON from stdin. It matches the prompt against `^\s*merge\?\s*$` case-insensitively (surrounding whitespace tolerated, uppercase `MERGE?` accepted) and emits `additionalContext` instructing Claude to run `git-agent:merge`. Every other prompt — including `merge` without a `?`, `please merge?`, `merge? now`, and prose containing "merge?" mid-sentence — receives no output. The anchored regex is what makes the trigger deterministic rather than heuristic.

`hooks.json` registers the script under `UserPromptSubmit`, mirroring the `plan-agent/hooks.json` wiring precedent. The script path is expressed as `${CLAUDE_PLUGIN_ROOT}/hooks/merge-shorthand.py` so the hook resolves correctly regardless of where the plugin is loaded from.

`skills/merge/SKILL.md` holds the safety logic. The skill queries `gh pr view --json state,mergeable,statusCheckRollup` and surfaces status when anything is pending, failing, or ambiguous. When the PR is `MERGEABLE` and required checks pass, the skill detects the project's lint script — the first non-`fix`, non-`watch` script matching `lint*` — and runs it. No lint script found means the step is skipped with a one-line note. Lint failure stops the merge and surfaces failures without auto-applying `--fix`, which would alter the PR head. With checks green and lint clean, the skill presents a summary and asks for explicit merge approval via `AskUserQuestion` — green signals alone never authorize a merge. On approval the merge runs as `gh pr merge --squash --match-head-commit <headRefOid>`, pinned to the verified commit SHA so a race-condition push cannot land. `--delete-branch` is never passed; branch deletion is a separate decision.

The smoke test asserts all three trigger variants (exact, whitespace-padded, uppercase), all six negative cases (no `?`, leading text, trailing text, mid-sentence), `hooks.json` validity, and key SKILL.md contract words (MERGEABLE gate, lint gate, no `--delete-branch`, ask-when-not-ready).

## How to use it

Type `merge?` as a standalone prompt (with the plugin loaded) to trigger the readiness check. The hook routes the prompt to `/git-agent:merge` without you typing the full command. Explicit invocation works too:

```text
/git-agent:merge
```

Both paths run the same skill: `gh pr view`, optional lint, explicit approval prompt, then `gh pr merge --squash --match-head-commit <headRefOid>`.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `df49b6d` | 2026-08-12 | feat(settings-sync): restore onto a new machine via clone URL (1.1.0) (#548) |

<!-- generated:end -->

## References

- Plan: [add-merge-shorthand-skill](plans/add-merge-shorthand-skill.md)
- Proposal: `docs/proposals/formalize-merge-shorthand.md`
- Changelog: `kit/plugins/git-agent/CHANGELOG.md` — v4.4.0
