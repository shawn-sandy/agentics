---
status: completed
modified: 2026-05-28
type: fix
created: 2026-05-28
repo-name: agentics
---

# Plan: Fix branch-agent checkout conflict on dirty working tree

## Context

`branch-agent` creates a branch with `git checkout -b <branch> --no-track
origin/<default>` (Step 5 of
`kit/plugins/git-agent/skills/branch-agent/SKILL.md`). When the working tree
has **tracked, modified** files that also differ between `HEAD` and
`origin/<default>`, git refuses the checkout to avoid silently discarding the
changes, aborting with:

> error: Your local changes to the following files would be overwritten by
> checkout: .claude-plugin/marketplace.json — Please commit your changes or
> stash them before you switch branches. Aborting

This is exactly the failure hit this session: the source branch had committed
edits to `marketplace.json`, and the working tree had *further* uncommitted
edits to the same file. `git checkout -b` would have had to roll
`marketplace.json` back to the `origin/main` state, conflicting with the
uncommitted edits.

The skill's current behaviour is to report the raw git error at Step 5 and
STOP — leaving the user to manually stash, checkout, and pop. The manual
recovery (`git stash push` → `git checkout -b` → `git stash pop`) worked
cleanly. The fix teaches `branch-agent` to detect this exact condition and
perform that recovery automatically.

Note: `git checkout -b` already carries uncommitted changes **forward**
to the new branch when there is no conflict. The conflict arises **only** when
a tracked-modified file also differs between `HEAD` and `origin/<default>`.
Untracked files (`??`) never conflict. So the fix must stash **only** when the
true conflict set is non-empty, preserving the normal carry-forward behaviour
otherwise.

## Objective

Add a pre-checkout conflict detection step to `branch-agent` that auto-stashes
the conflicting tracked changes, creates the branch, then restores them via
`git stash pop` — falling back to a clear report-and-STOP if the pop conflicts.

## Steps

1. **Insert a new "Step 4.5: Detect Checkout Conflicts" section** into
   `kit/plugins/git-agent/skills/branch-agent/SKILL.md`, between Step 4 (Fetch)
   and Step 5 (Create Branch). It computes the conflict set as the intersection
   of (a) tracked files modified vs `HEAD` and (b) files that differ between
   `HEAD` and `origin/<default>`:
   ```bash
   comm -12 \
     <(git diff --name-only HEAD | sort -u) \
     <(git diff --name-only HEAD origin/<default> | sort -u)
   ```
   - If empty → set "no stash needed"; uncommitted changes carry forward
     normally.
   - If non-empty → set "stash needed" and record the conflicting paths.
   - *Why:* The detection must run **after** Step 4's fetch (it depends on the
     freshly-updated `origin/<default>` ref) and **before** Step 5's checkout.
     `git diff --name-only HEAD` is the precise set of tracked modifications
     (excludes untracked `??` files, which never block checkout), so the
     intersection exactly reproduces git's own abort condition — no
     false-positive stashing.
   - *Verify:* Re-read the file; a `## Step 4.5: Detect Checkout Conflicts`
     heading exists between Step 4 and Step 5, contains the `comm -12`
     intersection command, and explicitly states the empty vs non-empty
     branches.

2. **Rewrite "Step 5: Create Branch" to branch on the stash flag.** When stash
   is needed:
   ```bash
   git stash push -m "branch-agent auto-stash <branch>"
   git checkout -b <branch> --no-track origin/<default>
   git stash pop
   ```
   When not needed, run the existing single `git checkout -b` unchanged.
   - On `git stash pop` conflict: report the git error verbatim, tell the user
     the changes are safe in the stash, show recovery steps (`git stash list`,
     resolve conflicts, `git checkout --theirs/--ours`), and **STOP** — do not
     retry, do not drop the stash.
   - On `git checkout -b` failure while stash is held: report the error, note
     that the stash is preserved, instruct `git stash pop` to restore, and
     **STOP**.
   - Keep the existing `--no-track` rationale and the "branch already exists /
     do not retry / do not force" guidance.
   - *Why:* Stashing only the genuinely-conflicting case keeps the common path
     (clean carry-forward) untouched. Preserving the stash on every failure
     path guarantees no uncommitted work is ever lost.
   - *Verify:* Re-read Step 5; it shows the three-command stash sequence gated
     on "stash needed", retains the plain checkout for the no-stash path, and
     documents both the pop-conflict and checkout-failure recovery paths with
     the stash preserved.

3. **Confirm `allowed-tools` already covers the new commands.** The frontmatter
   declares `Bash(git *)`, which permits `git stash push`, `git stash pop`, and
   `git diff`. No frontmatter change required; confirm and leave as-is.
   - *Why:* Avoid an unnecessary edit; `Bash(git *)` is a wildcard over all git
     subcommands.
   - *Verify:* Line 4 of the SKILL.md still reads
     `allowed-tools: Bash(git *), Bash(date *), ToolSearch, AskUserQuestion, ExitPlanMode`.

4. **Bump the `git-agent` version (PATCH) and add a CHANGELOG entry.** In
   `.claude-plugin/marketplace.json` change the `git-agent` entry `version`
   `3.9.0` → `3.9.1`. Add a `## v3.9.1` entry to
   `kit/plugins/git-agent/CHANGELOG.md` describing the auto-stash conflict fix.
   - *Why:* This is a bug fix (skill aborted on a legitimate dirty-tree
     scenario), which is a PATCH per `.claude/rules/marketplace.md`. Repo
     convention sets the plugin version only in `marketplace.json`, never in
     `plugin.json`.
   - *Verify:* `python3 -m json.tool .claude-plugin/marketplace.json` parses;
     the `git-agent` entry reads `"version": "3.9.1"`; the CHANGELOG has a
     `v3.9.1` entry at the top.

## Acceptance Criteria

- [ ] `branch-agent/SKILL.md` has a Step 4.5 that computes the conflict set via
      the `HEAD` ∩ `HEAD..origin/<default>` intersection and only flags a stash
      when that set is non-empty.
- [ ] Step 5 auto-stashes → checks out → pops when a conflict is detected, and
      runs the plain checkout (carry-forward) when not.
- [ ] Every failure path (pop conflict, checkout failure) preserves the stash
      and STOPs with verbatim error + recovery instructions — no work is lost,
      no retry, no force.
- [ ] Untracked-only working trees (e.g. only `??` files) do **not** trigger a
      stash.
- [ ] `git-agent` is at `3.9.1` in `marketplace.json` with a matching CHANGELOG
      entry; `marketplace.json` parses cleanly.

## Verification

End-to-end, after implementation:

1. **Reproduce the original failure scenario:** on a branch whose committed
   state differs from `origin/main` in `marketplace.json`, make a further
   uncommitted edit to `marketplace.json`, then run
   `/git-agent:branch-agent`. Confirm it now auto-stashes, creates the branch,
   pops the stash, and the uncommitted edit survives on the new branch (verify
   with `git status` + `git diff`).
2. **Clean carry-forward (no stash):** with only untracked new files in the
   tree, run the skill and confirm **no** stash is created (`git stash list`
   stays empty) and the untracked files carry to the new branch.
3. **No regression on clean tree:** with a fully clean tree and an explicit
   branch name argument, confirm the skill behaves exactly as before.
4. **JSON integrity:** `python3 -m json.tool .claude-plugin/marketplace.json`
   exits 0 (the `.claude/settings.json` auto-validator also runs on save).
5. **Reload and re-test:** `/reload-plugins` (or reload the `git-agent`
   plugin-dir) so the edited SKILL.md is picked up before the live test in (1).

## Next Steps *(optional)*

- Mirror the fix into the background `agent-commit`/branch agents if any share
  the checkout logic:
  ```text
  Audit kit/plugins/git-agent/agents/ for any agent that runs
  `git checkout -b ... origin/<default>` against a dirty working tree. If found,
  apply the same Step 4.5 conflict-detection + auto-stash/pop pattern used in
  the branch-agent skill (intersection of `git diff --name-only HEAD` and
  `git diff --name-only HEAD origin/<default>`; stash only when non-empty;
  preserve the stash on every failure path). Bump the git-agent PATCH version
  and update the CHANGELOG.
  ```
