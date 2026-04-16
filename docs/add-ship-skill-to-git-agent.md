# Add `/ship` Skill to git-agent Plugin

> Adds a `ship` skill to `git-agent` that chains commit + push + PR creation into a single flow with unified pre-flight guards, eliminating the need to run `commit-agent` and `pr-agent` separately.

<!-- generated:start -->

**Status:** Shipped 2026-03-12   **Plan:** [add-ship-skill-to-git-agent.md](plans/add-ship-skill-to-git-agent.md)   **Type:** feature

## What shipped

- New `kit/plugins/git-agent/skills/ship/SKILL.md` — 8-step strict-order skill: pre-flight guards, stage, write commit message, commit, push, check existing PR, detect base branch, create PR.
- Pre-flight guards run before any mutation: clean working tree check, detached HEAD detection, `main`/`master` branch protection, `gh` auth check.
- Push happens before the existing-PR check — ensures new commits always reach the remote whether a PR exists or not.
- `git-agent` plugin bumped from `1.0.0` → `1.1.0`.

> See [CHANGELOG §v1.1.0](../kit/plugins/git-agent/CHANGELOG.md#v110----add-ship-skill) for the authoritative feature list.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/git-agent/skills/ship/SKILL.md` | Skill instructions — ship | Created |
| `kit/plugins/git-agent/README.md` | Plugin documentation | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Plugin changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump 1.0.0 → 1.1.0 | Modified |

## How it works

The skill runs eight steps in strict order. **Pre-flight checks** run first: `git status` (stops if clean tree), `git branch --show-current` (stops if detached HEAD), branch name guard (stops if `main` or `master`), and `gh auth status` (stops if not installed or authenticated). All guards must pass before any mutation begins.

**Stage, analyze, and commit**: `git add -A` stages everything (trusting `.gitignore`), `git diff --staged` is analyzed to write a conventional commit message (72-char limit, imperative mood, `type(scope)` format), then `git commit -m` creates the commit. Pre-commit hook failures are reported verbatim and stop the flow — `--no-verify` is never used.

**Push**: the skill checks `git rev-parse --abbrev-ref @{u}` to detect whether an upstream tracking branch exists. No upstream → `git push -u origin <branch>`; has upstream → `git push`.

**PR handling**: after push, `gh pr view --json url` checks for an existing PR on the branch. If one exists, the URL is output and the skill stops — the commit has been pushed to the existing PR's branch. If no PR exists, the base branch is detected from `git symbolic-ref refs/remotes/origin/HEAD` (falling back to `main` then `master`), commit log and diff stat are gathered, and `gh pr create` creates the PR.

## How to use it

**Skill activation** — triggers on "ship it", "commit and create a PR", "ship my changes", "send it", "land my work":

```bash
claude --plugin-dir ./kit/plugins/git-agent
```

Then say: "ship it" or "ship my changes".

The skill outputs a PR URL on success:
```
✓ Committed: feat(api): add rate limiting to user endpoints
✓ Pushed to origin/feature/rate-limiting
✓ PR created: https://github.com/owner/repo/pull/42
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |
| `5287254` | 2026-04-09 | feat(kit/plugins/git-agent): bump version to 3.2.0 |

<!-- generated:end -->

## References

- Plan: [add-ship-skill-to-git-agent.md](plans/add-ship-skill-to-git-agent.md)
- Changelog: [CHANGELOG §v1.1.0](../kit/plugins/git-agent/CHANGELOG.md)
