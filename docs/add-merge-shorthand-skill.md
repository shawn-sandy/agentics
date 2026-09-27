# Formalize the merge? shorthand as a git-agent skill + prompt hook

> Promotes the `merge?` shorthand from an unreliable private memory note to a deterministic `UserPromptSubmit` hook that routes `merge?` to a new `git-agent:merge` skill — portable to any machine with the plugin installed.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/skills/merge/SKILL.md` — checks PR readiness (MERGEABLE, required checks passing, no CHANGES_REQUESTED), runs the project's lint script before merging, shows status when anything is ambiguous, and asks for explicit approval before merging with `--match-head-commit`.
- Created `kit/plugins/git-agent/hooks/merge-shorthand.py` — a `UserPromptSubmit` script that emits routing context only when the prompt matches `^\s*merge\?\s*$` (case-insensitive), staying silent on every other prompt.
- Created `kit/plugins/git-agent/hooks.json` — wires `merge-shorthand.py` under `UserPromptSubmit`, mirroring the `plan-agent` precedent.
- Added `tests/plugins/test-merge-shorthand.sh` — asserts hook fires on exact matches (`merge?`, surrounding whitespace, `MERGE?`), stays silent on near-misses (`merge`, `please merge?`, `merge? now`, prose containing "merge?"), and verifies the SKILL.md readiness-check contract.
- Bumped git-agent to 4.4.0, added CHANGELOG entry, updated README.
- Retired the `feedback_merge_behavior` memory note to a one-line pointer at `git-agent:merge`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Merge readiness skill | Created |
| `kit/plugins/git-agent/hooks/merge-shorthand.py` | UserPromptSubmit hook script | Created |
| `kit/plugins/git-agent/hooks.json` | Hook wiring file | Created |
| `tests/plugins/test-merge-shorthand.sh` | Smoke test for hook + skill contract | Created |
| `.claude-plugin/marketplace.json` | git-agent bumped to 4.4.0 | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v4.4.0 entry | Modified |
| `kit/plugins/git-agent/README.md` | Merge skill and shorthand documented | Modified |

## How it works

**The hook is the ergonomics layer.** `merge-shorthand.py` reads the hook JSON from stdin and applies an anchored regex `^\s*merge\?\s*$` (case-insensitive). Only an exact match (possibly with surrounding whitespace) emits `additionalContext` that instructs Claude to run the `git-agent:merge` skill. Every other prompt — including prompts that merely contain "merge?" — exits 0 silently. This anchored match prevents the hook from firing on ordinary sentences about merging.

**The skill is the logic layer.** `git-agent:merge` runs a structured readiness gate before touching anything: detached HEAD check, GitHub CLI availability, dirty working tree (ask, not stop). It queries `gh pr view` for `mergeable`, `mergeStateStatus`, `reviewDecision`, and `headRefOid`, then reads required checks with `gh pr checks --required`. Merge requires `mergeable == MERGEABLE`, all required checks `SUCCESS` or `SKIPPED`, and `reviewDecision` not `CHANGES_REQUESTED`.

**Lint runs before the merge decision.** The skill detects the project's first non-`fix`, non-`watch` lint script and runs it. No lint script found → skip with a note. Lint fails → stop and ask, never auto-fix, because fixed files would change the PR head after verification.

**Approval is always explicit.** Even when everything is green, the skill shows the check summary, review decision, and unresolved-thread count and asks via `AskUserQuestion` before merging. It then pins to the verified commit: `gh pr merge --squash --match-head-commit <headRefOid>`. This fails rather than landing commits that arrived after verification. Branch deletion is never included — it is a separate decision.

**The hook keeps 6-character ergonomics.** Typing `merge?` in any session with the plugin loaded triggers the full readiness check deterministically, replacing the 50-day-old memory note that fired only through model discretion.

## How to use it

Type `merge?` in a session with git-agent loaded — the hook routes it to the skill automatically.

Or invoke directly:
```
/git-agent:merge
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
