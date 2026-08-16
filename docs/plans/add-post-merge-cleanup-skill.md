---
status: completed
type: feature
created: 2026-08-15
effort: high
issue: https://github.com/shawn-sandy/agentics/issues/564
glance: Merged branches pile up with their worktrees, and the existing tool for clearing them force-removes whatever uncommitted work is sitting inside. This adds a skill that looks first and deletes second, so nothing gets destroyed without someone saying yes. We will know it worked when a worktree holding an uncommitted file survives a cleanup run untouched.
---

# Plan: Look inside the worktree before deleting it

## Objective

Add a `post-merge-cleanup` skill to git-agent that removes merged branches and
their worktrees only after inspecting each worktree for uncommitted work,
detects squash-merged branches that commit-ancestry cannot see, and reports
unregistered leftover directories instead of ignoring them.

## Context

`kit/plugins/git-agent/skills/merge/SKILL.md:183` deliberately declines branch
deletion — "Never pass `--delete-branch`. Branch deletion is a separate
destructive action that needs its own explicit yes." Nothing has ever filled
that seam, so the job falls to `commit-commands:clean_gone`, an external command
that runs `git worktree remove --force` plus `git branch -D` in one unattended
loop with no user gate. Measured against this repo on 2026-08-15, that would
destroy 16 untracked files across 9 of 19 worktrees, because `--force` exists
precisely to defeat the dirty-tree refusal `git worktree remove` performs by
default.

That default refusal is the design hinge: because an unforced
`git worktree remove` already fails on a dirty tree, checking for uncommitted
work *first* lets this skill delegate its central safety property to git rather
than reimplementing it.

**Selection cannot rely on commit ancestry.** git-agent squash-merges, and a
squash merge replays a branch's changes as one new commit with a different SHA,
so the branch's own commits never become ancestors of `main`.
`git branch --merged origin/main` therefore cannot see squash-merged branches at
all. Measured here across 395 local branches: **84** are ancestry-merged, while
**318** have a merged pull request — **296** of those invisible to the ancestry
test. The union is **380 cleanable branches**, so selecting on ancestry alone
would find 84 of 380 and miss 78% of the real backlog. `git branch -d` would
also refuse those 296 even when deleting is correct, because `-d` performs the
same ancestry check. Selection therefore takes either signal, and `-D` is
permitted only where a merged PR supplies positive evidence.

The grounded proposal is at `docs/prompts/proposal-add-post-merge-cleanup.md`.
Note that its "51 branches that never landed" claim was disproved during this
plan's interview and has been corrected there.

Risks carried into this plan:

- **Recursive delete inside a skill.** Step 6 gives the skill an `rm -rf` for
  unregistered directories, which have no git registration to remove them by,
  and whose dangling `.git` files mean `git status` cannot vouch for their
  contents. Mitigated by printing size, file count, and recently modified files,
  requiring a per-directory confirmation, checking containment against the
  worktrees root, and refusing any path detection did not itself produce.
- **`-D` is now reachable.** Squash-merged branches require it. Mitigated by
  gating `-D` behind a confirmed merged PR; without that evidence the skill uses
  `-d` and accepts git's refusal.
- **Self-deletion.** The skill can run inside the worktree it is asked to
  remove. Mitigated by an explicit cwd check in Step 3.
- **Version guard.** Any edit under `kit/plugins/git-agent/` fails CI without a
  `marketplace.json` version bump. Step 7 does it; nothing else may.

## Files

- `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` (new) — activation, the safety contract, and the default single-branch flow
- `kit/plugins/git-agent/skills/post-merge-cleanup/references/detection.md` (new) — dual-signal selection, the degraded mode, and the read-only inventory
- `kit/plugins/git-agent/skills/post-merge-cleanup/references/sweep.md` (new) — the repo-wide sweep report and its gates
- `kit/plugins/git-agent/skills/post-merge-cleanup/references/stale-directories.md` (new) — unregistered-directory evidence rules and removal rails
- `tests/plugins/test-post-merge-cleanup.sh` (new) — fixture-repo objective test plus contract greps
- `.github/workflows/check-plugin-versions.yml` (modified) — run the new test in CI
- `kit/plugins/git-agent/README.md` (modified) — add the skill to the Skills table
- `kit/plugins/git-agent/CHANGELOG.md` (modified) — v4.19.0 entry
- `.claude-plugin/marketplace.json` (modified) — bump git-agent 4.18.0 to 4.19.0
- `README.md` (modified) — Plugin Reference Table, regenerated via the canonical generator, never hand-edited

## Steps

1. [x] Create `kit/plugins/git-agent/skills/post-merge-cleanup/SKILL.md` with frontmatter (`name`, `description`, `allowed-tools`) and a Safety Contract section stating the four absolutes: never `git worktree remove --force`, never remove a worktree whose `git status --porcelain` is non-empty, never `git branch -D` without a confirmed merged PR, and never `rm` a path outside the worktrees root. Why: the contract is the whole point of the skill, so it belongs where a reader and a model both hit it first. Verify: `python3 tests/plugins/measure_description_budget.py` reports the description at 200 characters or fewer with a first sentence of 80 or fewer, and `find kit/plugins/git-agent/skills/post-merge-cleanup -maxdepth 1 -name '*.md' | wc -l` returns 1.

2. [x] Write `references/detection.md` defining dual-signal selection: a branch is cleanable when `git branch --merged origin/<default>` lists it **or** `gh pr list --head <branch> --state merged` returns a PR. Resolve the default branch via `git symbolic-ref refs/remotes/origin/HEAD`, falling back to `gh repo view --json defaultBranchRef`. When `gh` is absent, unauthenticated, or the remote is not GitHub, degrade to the ancestry test alone and state in the report that squash-merged branches cannot be detected in this mode, so the list is known-incomplete. Why: ancestry alone finds only 84 of this repo's 380 real candidates, and a silently-narrow list is far more dangerous than an openly-narrow one. Verify: running the documented commands against this repo yields 84 ancestry-merged, 318 with merged PRs, and 380 cleanable in the union, and the documented degraded-mode probe reports `full` here while a `gh`-less environment reports `degraded`.

3. [x] Add the default single-branch flow to `SKILL.md`: confirm the branch is cleanable by either signal, refuse when the current working directory is inside the target worktree, inspect with `git status --porcelain` and stop with the file list when output is non-empty for any reason — untracked, staged, or unstaged — then on approval run `git worktree remove <path>` from outside the worktree, followed by `git branch -d`, escalating to `-D` only when a merged PR was the qualifying signal. Why: this is the path users hit by default; gating on any dirty state rather than untracked-only means uncommitted tracked edits are reported clearly instead of hitting git's refusal as a confusing failure. Verify: the Step 6 fixture test's dirty-worktree cases (untracked, staged, and unstaged variants) each exit without removing the worktree, with the file still present.

4. [x] Write `references/sweep.md` defining the repo-wide sweep behind an explicit flag: emit one table of branch, qualifying signal, worktree path, and dirty-file count before any action; list dirty worktrees as blocked alongside their file lists; require per-item approval, with batch approval as a separate deliberate answer rather than a default. Why: one yes covering 136 branches is a gate that gets clicked through, so the report has to make the blast radius legible before the question is asked. Verify: the reference documents a blocked-item row format including the file list, names the qualifying signal per row, and states that batch approval is never the default option.

5. [x] Write `references/stale-directories.md`: a directory is unregistered only when it is absent from `git worktree list`, has no admin directory under `.git/worktrees/<name>`, and its `.git` file is dangling or missing. Because a dangling `.git` means `git status` cannot inspect it, removal requires printing the directory's size, file count, and most recently modified files, then a per-directory confirmation, a check that the resolved path is inside the worktrees root, and refusal of any path not produced by detection. Why: this is the one recursive delete in the skill, git can vouch for none of these directories, and each condition rules out a different way of deleting something live. Verify: the Step 6 containment cases confirm a path outside the worktrees root, a still-registered path, and a path retaining its admin directory are each rejected.

6. [x] Add `tests/plugins/test-post-merge-cleanup.sh` following the shape of `tests/plugins/test-scope-guard.sh`: build a throwaway fixture repo under `mktemp -d`, create both an ancestry-merged and a squash-merged branch each with a worktree, leave one worktree holding an uncommitted file, assert the documented flow leaves that worktree and its file intact, assert the clean worktree is removed, assert the squash-merged branch is detected as cleanable, assert paths outside the worktrees root are rejected, assert no forbidden flag appears inside a fenced code block in the skill sources (a prose prohibition naming the flag is correct and must not fail), and remove the temp directory on exit via `trap`. Why: the ordering guarantee is the objective, and an assertion that the uncommitted file survives is the only check that fails if the ordering ever regresses. Verify: `bash tests/plugins/test-post-merge-cleanup.sh` exits 0, and re-running it leaves no directory behind under `$TMPDIR`.

7. [x] Wire the test into `.github/workflows/check-plugin-versions.yml` as its own step matching the existing `run: bash tests/plugins/test-<name>.sh` entries, then update `kit/plugins/git-agent/README.md`'s Skills table and add a `## v4.19.0` CHANGELOG entry, and bump git-agent from `4.18.0` to `4.19.0` in `.claude-plugin/marketplace.json`. Why: the version guard fails the PR without the bump, and a test that is not named in the workflow never runs. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0, and `grep -c test-post-merge-cleanup .github/workflows/check-plugin-versions.yml` returns 1 or more.

8. [x] Regenerate the root `README.md` Plugin Reference Table with `node scripts/build-readme-table.mjs`. Why: the table is generated output and hand-editing it is what the repo's generated-files rule exists to prevent. Verify: running the generator a second time produces no further diff — `node scripts/build-readme-table.mjs && git diff --exit-code README.md` exits 0.

## Tests

Tier 1 — This plan changes application code

- Objective: a cleanable branch's worktree holding an uncommitted file survives a cleanup run with the file intact, proving the dirty-state check gates removal rather than trailing it. File: `tests/plugins/test-post-merge-cleanup.sh`; Type: smoke; Asserts: after running the documented flow against a fixture repo whose worktree contains one uncommitted file, the worktree directory still exists, the file is byte-identical, and the branch is still present; Run: `bash tests/plugins/test-post-merge-cleanup.sh`
- Unit: dual-signal selection. File: `tests/plugins/test-post-merge-cleanup.sh`; Targets: the selection rule in `references/detection.md`; Key cases: an ancestry-merged branch qualifies; a squash-merged branch with a merged PR qualifies despite failing the ancestry test; a branch with neither signal does not qualify; with `gh` unavailable the run degrades to ancestry only and emits the incompleteness warning
- Unit: the dirty-state gate covers every porcelain status. File: `tests/plugins/test-post-merge-cleanup.sh`; Targets: the Step 3 flow; Key cases: untracked-only blocks; staged-only blocks; unstaged-only blocks; a genuinely clean worktree is removed, proving the gate blocks dirty trees specifically rather than blocking everything
- Unit: the containment rule for unregistered-directory removal. File: `tests/plugins/test-post-merge-cleanup.sh`; Targets: the path checks in `references/stale-directories.md`; Key cases: a path inside the worktrees root is accepted; a sibling path outside it is rejected; a path still present in `git worktree list` is rejected; a path whose `.git/worktrees/<name>` admin directory still exists is rejected
- Unit: documented commands are portable. File: `tests/plugins/test-post-merge-cleanup.sh`; Targets: fenced code blocks under `skills/post-merge-cleanup/`; Key cases: no GNU-only `find -newermt '<relative>'` form, which BSD `find` rejects and `bfs` errors on; the documented `find -mtime -90` form actually executes on the host. Added after the GNU-only form failed during end-to-end verification.
- Unit: the forbidden-flag contract. File: `tests/plugins/test-post-merge-cleanup.sh`; Targets: fenced code blocks in every `.md` under `kit/plugins/git-agent/skills/post-merge-cleanup/`; Key cases: no `worktree remove --force` or `-f` inside a fenced code block; no bare `branch -D` inside a fenced code block; the safety contract's prose prohibitions naming those flags do **not** fail the test, since a rule that forbids a flag must be able to name it

## Acceptance Criteria

- [x] A worktree with any non-empty `git status --porcelain` output is never removed and never force-removed; the fixture test proves the file survives
- [x] No fenced code block under `skills/post-merge-cleanup/` invokes `worktree remove --force` or `-f`; prose prohibitions naming the flag are permitted and expected
- [x] `branch -D` never appears as a bare command in a fenced code block; it is reachable only via prose stating its merged-PR precondition, and ancestry-merged branches use `branch -d`
- [x] Squash-merged branches are detected as cleanable despite failing the ancestry test
- [x] With `gh` unavailable the skill still runs, degrades to ancestry only, and states that the list is incomplete
- [x] The skill refuses to remove the worktree it is currently running inside
- [x] Unregistered-directory removal prints size, file count, and recent files, then requires a per-directory confirmation and rejects any path outside the worktrees root
- [x] `bash tests/plugins/test-post-merge-cleanup.sh` exits 0 and leaves no temp directory behind
- [x] The test is named in `.github/workflows/check-plugin-versions.yml`
- [x] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 with git-agent at 4.19.0
- [x] The root README table was produced by `scripts/build-readme-table.mjs`, not hand-edited
- [x] The skill description passes the 200-character budget

## Verification

Build a throwaway repo under `mktemp -d` with a `main` branch and three feature
branches: one merged with a merge commit, one squash-merged, one never merged.
Give each a worktree. Leave an uncommitted file in the first worktree and leave
the second clean. Run the documented flow from the repo root.

The first worktree must be reported as blocked, its file named in the report,
and left on disk unchanged with its branch undeleted. The second must be removed
and its branch deleted. The squash-merged branch must be recognized as cleanable
even though `git branch --merged` does not list it, and its deletion must use
`-D` only after its merged PR is confirmed. The never-merged branch must not
appear as cleanable at all. Re-run with `gh` unavailable and confirm the run
completes, covers only the ancestry-merged branch, and says the list is
incomplete.

Then create a directory under the worktrees root with no git registration and
confirm the skill reports its size, file count, and recent files and takes no
action without a per-directory yes. Finally, `cd` into a worktree and invoke the
flow against that same worktree — it must refuse rather than delete the
directory it is running in.

Remove the temp repo afterward. Then confirm the packaging half:
`BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0, and
`node scripts/build-readme-table.mjs && git diff --exit-code README.md` exits 0.

## Unresolved Questions

- **Sweep flag naming.** `--all`, `--sweep`, or a separate
  `/git-agent:cleanup-sweep` command. A separate command is more discoverable
  but adds a second entry point to maintain.
- **Invocation model.** Manual-invoke only, matching every other git-agent
  skill, or a prompt hook that offers cleanup after `/git-agent:merge` reports a
  successful merge. The hook is more useful and more intrusive.
- **Rate limiting the PR lookup.** Dual-signal selection calls `gh` once per
  candidate branch, which is 395 lookups on a full sweep of this repo. Whether
  to batch via a single `gh pr list --state merged --limit N` and match locally,
  or accept the per-branch cost, is unresolved — it did not surface until the
  squash-merge finding made `gh` part of selection.

## Next Steps

- Document the divergence from `commit-commands:clean_gone` in the git-agent README
  The dangerous path stays one command away for anyone who has that plugin installed, and a short note naming the difference is the only mitigation available short of removing it.
  ```text
  Add a short subsection to kit/plugins/git-agent/README.md, under the post-merge-cleanup skill entry, explaining how it differs from the external commit-commands:clean_gone command: clean_gone runs `git worktree remove --force` plus `git branch -D` unattended with no user gate, so it destroys uncommitted work in worktrees without asking. Note that its [gone]-based branch selection is actually reasonable for a squash-merge workflow — the danger is the missing gate, not the selection. Keep it to about four sentences and do not disable or modify the external plugin.
  ```

- Clear the existing backlog once the skill ships
  This repo currently carries 380 cleanable branches, 3 of them still holding worktrees, and 3 unregistered directories worth roughly 7.3M — the sweep exists for exactly this, but running it is a separate decision from building it.
  ```text
  Using the /git-agent:post-merge-cleanup skill's repo-wide sweep, produce the inventory report for this repo without deleting anything: cleanable branches with their qualifying signal (ancestry-merged or merged PR), which still hold worktrees, which worktrees carry uncommitted files with the file lists, and the unregistered directories under .claude/worktrees/ with their sizes and evidence. Present the report and stop — do not remove anything until I have read it and said which items to act on.
  ```

## Resources

- `docs/prompts/proposal-add-post-merge-cleanup.md` — the grounded proposal this plan executes; its ancestry-based selection was corrected after the squash-merge finding
- `kit/plugins/git-agent/skills/merge/SKILL.md:183` — the existing refusal to delete branches, which defines the seam this skill fills
- `~/.claude/plugins/marketplaces/claude-plugins-official/plugins/commit-commands/commands/clean_gone.md` — the external command whose missing user gate this skill is deliberately not copying
- `kit/plugins/git-agent/skills/ship/references/` — the progressive-disclosure precedent: a lean SKILL.md with detail in references/
