# Sync With Base

Procedure for **Step 4.7: Sync With Base** of `ship`. `pr-agent` carries its
own copy inline (a skill bundles only its own directory); change both together.

A branch cut before other PRs merged can describe behavior that no longer
exists, and its CHANGELOG entry conflicts at merge time. Syncing before the push
settles both while the branch is still local.

It runs after Step 4.5, not before: the self-review amends the Step 4 commit,
and after a merge that amend would land on the merge commit instead.

```
git fetch origin <base>
git rev-list --count HEAD..origin/<base>
```

`0` → already current; continue to Step 5.

Otherwise pick by whether this branch was ever pushed:
`git rev-parse --verify --quiet refs/remotes/origin/<branch>`, with `<branch>`
from `git branch --show-current`. Not `@{u}`: a worktree branch cut from
`origin/<base>` tracks it, so `@{u}` succeeds on a branch never pushed.

- **Non-zero exit (never pushed)** → `git rebase origin/<base>`.
- **Zero exit (pushed)** → `git merge --no-edit origin/<base>`.
  Rebasing a pushed branch needs a force-push, which this skill never runs.

## On conflict

List the conflicted files with `git diff --name-only --diff-filter=U`.

- **Every conflicted file is a `CHANGELOG.md`** → keep both sides' entries, this
  branch's on top as the newest, and remove the markers. `git add` those files,
  then `git -c core.editor=true rebase --continue` (rebase) or
  `git commit --no-edit` (merge). A rebase can stop again on a later commit;
  repeat for each stop.
- **Anything else** → `git rebase --abort` or `git merge --abort`, report the
  conflicted files verbatim, and **STOP**. Code conflicts are the user's call.

Report one line: "Synced with origin/<base> (N commits behind)" or "Already
current with origin/<base>".
