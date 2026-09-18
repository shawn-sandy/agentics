# Lint Gate Block at a commit-agent Commit

Applies to every commit this skill delegates to `git-agent:commit-agent`: Step 3,
a 6c review fix, and 6d. On a block, commit-agent reports "Lint gate blocked the commit. Nothing
committed; changes are still staged." followed by the hook's output, which starts
with ``Blocked: `<check>` failed, so this commit was not created.``, and stops.
git-agent's own lint hook stopped the commit, not a git hook, so the pre-commit
hook guardrail does not apply.

Never switch the gate off to get past it: do not create `.claude/no-lint-gate`
or edit `.claude/lint-gate.json`, even though the block message offers the
first. That is the user's call.

Use **AskUserQuestion** with the header `Lint gate`, the question "The lint gate
blocked this commit. Fix the reported failures and retry?", and two options:

- **Fix and retry**: follow the fix loop below.
- **Stop**: output "Nothing committed. Changes are still staged." and **STOP**.

## Fix loop

Fix only failures in files listed by `git diff --staged --name-only`, with the
smallest `Edit` that clears each one, changing nothing else. Never run a `--fix`
script; the guardrails forbid one before a commit. A reported failure in a file
this commit does not touch is not this commit's to fix: report the block output
verbatim and **STOP** without editing. Otherwise re-invoke
**`git-agent:commit-agent`** (delegated, no prompt).

Ask once and fix at most twice; if the gate blocks a third time, report its
latest output verbatim and **STOP**. Once the commit lands, list the files the
fix edited and carry on from where the commit was made: Step 4 after Step 3,
`git push` after 6c or 6d.
