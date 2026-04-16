# Create git-agent Plugin with commit-agent and pr-agent Skills

> New `git-agent` plugin with two skills — `commit-agent` (stage and commit with conventional messages) and `pr-agent` (create a pull request with guards) — both with hard STOP boundaries to prevent scope creep.

<!-- generated:start -->

**Status:** Shipped 2026-03-03   **Plan:** [create-git-agent-plugin-commit-pr-skills.md](plans/create-git-agent-plugin-commit-pr-skills.md)   **Type:** standard

## What shipped

- New `git-agent` plugin at `kit/plugins/git-agent/`.
- `commit-agent` skill: 5-step rigid order — guard (clean tree / detached HEAD), `git add -A`, analyze diff and write conventional commit message, `git commit -m`, output with undo note. Hard STOP after step 4.
- `pr-agent` skill: 5-step rigid order — guards (detached HEAD, main/master, `gh auth`), detect base branch, check for existing PR, push if needed, `gh pr create`. Hard STOP after step 5.
- No `--no-verify` bypass: pre-commit hook failures are reported verbatim and stop the flow.
- Existing PR detection: `gh pr view --json url` check prevents duplicate PR creation.
- Plugin registered in `.claude-plugin/marketplace.json` at `v1.0.0`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/git-agent/skills/commit-agent/SKILL.md` | Skill instructions — commit-agent | Created |
| `kit/plugins/git-agent/skills/pr-agent/SKILL.md` | Skill instructions — pr-agent | Created |
| `kit/plugins/git-agent/.claude-plugin/plugin.json` | Plugin manifest v1.0.0 | Created |
| `kit/plugins/git-agent/README.md` | Plugin documentation | Created |
| `kit/plugins/git-agent/CHANGELOG.md` | Version history | Created |
| `.claude-plugin/marketplace.json` | Marketplace registry — new plugin entry | Modified |

## How it works

**commit-agent** enforces a clean workflow with safety rails. Before any mutation it runs `git status` — stopping if the tree is clean (nothing to commit) and `git branch --show-current` — stopping if detached HEAD. Then it stages all changes with `git add -A` (trusting `.gitignore`), analyzes `git diff --staged` to write a conventional commit message (72-char limit, `type(scope): description` format, scope tiebreaker: most-changed directory, omit scope if changes span >2 top-level directories), and runs `git commit`. The output includes a one-line undo note: "To undo: `git reset HEAD~1`". The skill stops unconditionally after the commit — no tests, no further analysis.

**pr-agent** starts with three upfront guards: detached HEAD check, `main`/`master` branch protection, and `gh auth status` verification. After guards pass, it detects the base branch via `git symbolic-ref refs/remotes/origin/HEAD` (falling back to `main` then `master`), then checks `gh pr view` for an existing PR — if one exists, it outputs the URL and stops. If no PR exists, it pushes the branch (`git push -u origin <branch>` if no upstream, `git push` if tracking ref exists) and creates the PR with `gh pr create`.

The hard STOP design at the end of each skill prevents the session from drifting into tangential work (test coverage analysis, dependency audits) after completing the commit or PR.

## How to use it

**Skill activations:**
- "commit my changes", "stage and commit", "commit all changes" → `commit-agent`
- "create a PR", "open a pull request", "make a PR", "push and create PR" → `pr-agent`

```bash
claude --plugin-dir ./kit/plugins/git-agent
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |

<!-- generated:end -->

## References

- Plan: [create-git-agent-plugin-commit-pr-skills.md](plans/create-git-agent-plugin-commit-pr-skills.md)
