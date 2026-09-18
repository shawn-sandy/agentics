---
name: commit-agent
description: "Stages all changes and creates a conventional commit message. Analyzes the diff, writes a scope-correct commit, then asks whether to push. Use when the user asks to commit or save work to git."
allowed-tools: Bash(git *), Read, Edit, AskUserQuestion, ToolSearch, ExitPlanMode
disable-model-invocation: true
model: haiku
---

Stage all changes, create a conventional commit message, then ask whether to push. Follow these steps in strict order. **STOP immediately after step 6.**

## When not to use

Does not create PRs — use pr-agent for that. Never pushes without the Step 6 approval.

## Delegated invocation

Steps 5 and 6 exist for a user who invoked this skill directly. **When another skill or agent invokes this skill as a sub-step, stop after Step 4** — skip the probe and the push question entirely.

The caller owns the push in that case (`ship-autonomous` Step 4 delegates to `pr-agent`; its Step 6d pushes directly), so asking would stall an unattended run, and a "Don't push" answer would not stop the caller from pushing anyway. A prompt that cannot honor its own answer is worse than no prompt.

## Step 0: Exit Plan Mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Step 1: Guards

Run `git status --porcelain` to check repository state.

- **Clean working tree** (empty output): output "Nothing to commit — working tree is clean." and **STOP**.
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

**If the lint gate blocks the commit** (the output starts with ``Blocked: `<check>` failed, so this commit was not created.``), git-agent's own lint hook stopped it, not a git hook. Nothing was committed and the changes are still staged. Never switch the gate off to get past it: do not create `.claude/no-lint-gate` or edit `.claude/lint-gate.json`, even though the block message offers the first. That is the user's call.

- **Delegated invocation:** report "Lint gate blocked the commit. Nothing committed; changes are still staged." followed by the block output verbatim, and **STOP**. The caller owns the fix.
- **Direct invocation:** use **AskUserQuestion** with the header `Lint gate`, the question "The lint gate blocked this commit. Fix the reported failures and retry?", and two options:
  - **Fix and retry**: follow the fix loop below.
  - **Stop**: output "Nothing committed. Changes are still staged." and **STOP**.

Fix loop: fix only failures in files listed by `git diff --staged --name-only`, with the smallest edit that clears each one, changing nothing else. A reported failure in a file this commit does not touch is not this commit's to fix: report the block output verbatim and **STOP** without editing. Otherwise stage only the files the fix edited, with `git add -- <file>...` (not `-A`, which would sweep in anything saved since Step 2), and re-run the commit above with the same message. Ask once and fix at most twice; if the gate blocks a third time, report its latest output verbatim and **STOP**. Once the commit lands, list the files the fix edited.

After a successful commit, output one line:

> To undo: `git reset HEAD~1`

## Step 5: Resolve the Push Command

Determine which push the next step would run, so the question can name it. This step only reads state — it pushes nothing.

Run:
```
git rev-parse --abbrev-ref --symbolic-full-name @{u}
```

- Exits non-zero (no upstream tracking ref) → the push command is `git push -u origin <current-branch>`
- Exits zero (upstream exists) → the push command is `git push`

## Step 6: Ask Whether to Push

Always ask — never push on your own initiative, and never skip the question because the commit looked routine.

Use **AskUserQuestion** with the header `Push`, the question "Commit created. Push `<current-branch>` to the remote?", and two options:

- **Push** — run `<push command from Step 5>`
- **Don't push** — leave the commit local

**If the answer is "Don't push"** (or the question is dismissed), output "Commit left local." and **STOP**.

**If the answer is "Push"**, run the command resolved in Step 5 and report the result.

**If the push fails** (rejected, no remote, auth failure, pre-push hook), report the error verbatim and **STOP**. Do not retry. Do not force. Do not pull, fetch, rebase, or merge to make the push succeed — a rejected push means the branch diverged, and reconciling it is the user's call.

---

**STOP here. Do not run tests, analyze coverage, check for issues, create PRs, or take any further action.**
