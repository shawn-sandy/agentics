# Lint Gate Block at Step 4

git-agent's own lint hook stopped the commit, not a git hook. Its output starts
with ``Blocked: `<check>` failed, so this commit was not created.`` Nothing was
committed and the changes are still staged.

Never switch the gate off to get past it: do not create `.claude/no-lint-gate`
or edit `.claude/lint-gate.json`, even though the block message offers the
first. That is the user's call.

Use **AskUserQuestion** with the header `Lint gate`, the question "The lint gate
blocked this commit. Fix the reported failures and retry?", and two options:

- **Fix and retry**: follow the fix loop below.
- **Stop**: output "Nothing committed. Changes are still staged." and **STOP**.

## Fix loop

Fix only failures in files listed by `git diff --staged --name-only`, with the
smallest edit that clears each one, changing nothing else. A reported failure in
a file this commit does not touch is not this commit's to fix: report the block
output verbatim and **STOP** without editing. Otherwise stage only the files the
fix edited, with `git add -- <file>...` (not `-A`, which would sweep in anything
saved since Step 2), and re-run the Step 4 commit with the same message.

Ask once and fix at most twice; if the gate blocks a third time, report its
latest output verbatim and **STOP**. Once the commit lands, list the files the
fix edited, then continue to Step 4.5.
