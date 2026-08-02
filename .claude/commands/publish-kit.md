---
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion
---

Publish the marketplace to the `agentics-kit` distribution repo on demand, from a chosen ref, after verifying it locally.

Wraps `publish-dist.yml`'s `workflow_dispatch`. The bare form in CLAUDE.md
(`gh workflow run publish-dist.yml --repo shawn-sandy/agentics`) omits `--ref`, so
it publishes the **default branch** no matter which branch you are on — this
command always passes an explicit ref.

`$ARGUMENTS` is the ref to publish. Omit it to use the current branch.

## Steps

1. Resolve the ref. Use `$ARGUMENTS` if given, else `git rev-parse --abbrev-ref HEAD`.
   Abort if it resolves to `HEAD` (detached) — tell the user to check out a branch.

2. Check the ref is pushed and current. The workflow checks out the **remote** copy,
   so anything local and unpushed will not be published:
   ```bash
   git fetch origin --quiet
   git status --porcelain                       # uncommitted work
   git rev-list --left-right --count origin/<ref>...<ref> 2>/dev/null
   ```
   Report each problem and stop if any apply:
   - the ref has no `origin/<ref>` — it was never pushed
   - the counts are non-zero — local and remote have diverged
   - `git status --porcelain` is non-empty — uncommitted changes will not ship

   These are stop conditions, not warnings. Publishing a ref whose remote copy
   differs from what the user is looking at is the failure this command exists to
   prevent.

3. Run the workflow's own gates locally, so a preventable failure does not burn a
   remote run. Read `.github/workflows/publish-dist.yml` and run each step's `run:`
   command in order, stopping at the `Publish to agentics-kit` step. Read the
   workflow rather than hardcoding the list — the gate set changes.

   Report the first failure verbatim and stop.

4. Confirm before dispatching. This pushes to a public distribution repo, so always
   ask, and never skip the question because the gates were green.

   Use **AskUserQuestion**, header `Publish`. State the ref, and when it is not the
   default branch say plainly that unmerged content will reach the public mirror.
   Options: **Publish** (dispatch) and **Cancel** (do nothing).

5. On **Publish**, dispatch and watch:
   ```bash
   gh workflow run publish-dist.yml --repo shawn-sandy/agentics --ref <ref>
   sleep 5 && gh run list --workflow=publish-dist.yml --repo shawn-sandy/agentics --limit 1
   gh run watch <run-id> --repo shawn-sandy/agentics --exit-status
   ```
   Report the final status and the run URL.

   If the dispatch or the run fails, report the error verbatim and stop. Do not
   retry, and do not re-dispatch against a different ref to get a green run.

6. On **Cancel**, output "Publish cancelled." and stop.

## Notes

- The workflow also runs daily at 06:00 UTC; this command is only for publishing
  ahead of that schedule.
- `concurrency: publish-dist` cancels an in-progress run when a new one starts.
- Needs the `DIST_REPO_URL` variable and `DIST_REPO_TOKEN` secret configured on the
  repo; a run that fails immediately on the publish step usually means one is missing.
