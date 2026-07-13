---
name: commit-agent
description: "Stages all changes and creates a conventional commit message. Analyzes the diff and writes a descriptive, scope-correct commit. Use when the user asks to commit or save work to git."
allowed-tools: Bash(git *), ToolSearch, ExitPlanMode
disable-model-invocation: true
model: haiku
---

Stage all changes and create a conventional commit message. Follow these steps in strict order. **STOP immediately after step 4.**

## When not to use

Does not push or create PRs — use pr-agent for that.

## Step 0: Exit Plan Mode

**If currently in plan mode**, call `ExitPlanMode` first and silently before any other action — Staging and committing are git mutations and cannot proceed inside plan mode. Skip this step entirely when not in plan mode. `ExitPlanMode` is a deferred tool — use `ToolSearch` with `select:ExitPlanMode` first, then call it silently.

## Step 1: Guards

Run `git status` to check repository state.

- **Clean working tree** (nothing to commit): output "Nothing to commit — working tree is clean." and **STOP**.
- **Detached HEAD** (`git branch --show-current` returns empty): output "Cannot commit: repository is in detached HEAD state. Checkout a branch first." and **STOP**.

## Step 2: Stage Changes

Run `git add -A` to stage all changes.

This trusts `.gitignore` to exclude sensitive or generated files. The user is responsible for `.gitignore` correctness.

## Step 3: Analyze Diff and Write Commit Message

Run `git diff --staged` to inspect all staged changes.

Write a conventional commit message:

```
<type>(<scope>): <description>
```

**Rules:**
- Total length: ≤ 72 characters
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `style`, `ci`, `build`
- Scope: the most-changed top-level directory (e.g., `plugins/git-agent` → `plugins/git-agent`)
- Omit scope entirely if changes span more than 2 top-level directories
- Description: imperative mood, lowercase, no trailing period

**Examples:**
- `feat(plugins/git-agent): add commit-agent and pr-agent skills`
- `fix(plugins/code-review): correct activation trigger wording`
- `chore: update marketplace.json with new plugin entry`

## Step 4: Commit

Run:
```
git commit -m "<message>"
```

Output the commit hash and message on success.

**If a pre-commit hook fails:** report the hook's output verbatim and **STOP**. Do not retry. Do not use `--no-verify`. Do not modify the staged files. Let the user fix the issue.

After a successful commit, output one line:

> To undo: `git reset HEAD~1`

---

**STOP here. Do not run tests, analyze coverage, check for issues, push, create PRs, or take any further action.**
