---
type: proposal
intent: Add a git-agent skill that gates post-merge branch and worktree removal on an orphaned-file check
techniques: Long-context grounding, XML structure, Comparison tables, Positive framing, Output format
created: 2026-08-15
status: converged
modified: 2026-08-15
generated-sha: 63f59bd4420a7a62317961eec4a32580a2380a24301c53ffb4d8725424ee7819
repo-name: agentics
---

# Proposal: Add Post-Merge Cleanup

> This is a proposal for review, not an execution plan. It carries the
> grounded research and the decisions already made; the final instruction
> below hands off to drafting an execution plan from it.

<tldr>
The nearest existing tool, `commit-commands:clean_gone`, runs
`git worktree remove --force` and `git branch -D` in one unattended loop with no
user gate — which against agentics on 2026-08-15 would silently destroy 16
untracked files across 9 of 19 worktrees. This proposes a new git-agent skill,
`post-merge-cleanup`, that inverts the order: inspect the branch's worktree for
uncommitted work first, report and ask, and only then remove the worktree and
branch using unforced git commands. Selection takes either signal — commit
ancestry or a merged pull request — because git-agent squash-merges and
`git branch --merged` structurally cannot see squash-merged branches: 85 are
ancestry-merged here and a further 51 are invisible to that test, every one of
them with a MERGED PR. Single-branch by default, with a repo-wide sweep behind a
flag. The 3 unregistered worktree directories on disk (~7.3M) that
`git worktree prune` cannot see are detected and removed only on explicit
per-directory approval.
</tldr>

<correction>
Revised 2026-08-15 after the plan interview. The first draft claimed
`clean_gone` would "force-delete 51 branches that never landed on main." That is
false: all 51 were verified to have MERGED pull requests, and were invisible to
`git branch --merged` only because a squash merge rewrites commits under new
SHAs. `clean_gone`'s `[gone]`-based branch selection is therefore reasonable for
this workflow — its actual defect is the missing user gate and the `--force`,
not the selector. The correction also inverted this proposal's own selection
decision: ancestry alone would have missed 51 of 136 real candidates, and
`git branch -d` would have refused them, so `-d` cannot serve as the safety
check on its own.
</correction>

<context>
git-agent 4.18.0 ships `branch-agent`, `commit-agent`, `create-issue`, `merge`,
`pr-agent`, `ship`, and `ship-autonomous`. There is no cleanup skill. The gap is
deliberate and documented: `kit/plugins/git-agent/skills/merge/SKILL.md:183`
states "Never pass `--delete-branch`. Branch deletion is a separate destructive
action that needs its own explicit yes." Nothing fills that seam today.

The maintainer's global `CLAUDE.md` already prescribes the exact procedure this
skill would encode: "To clean up a worktree, `cd` out of it first, then
`git worktree remove` + `git branch -d` — never `rm -rf`." It also forbids
deleting a branch or running `rm` without explicit approval.

The nearest existing tool is external to this marketplace:
`commit-commands:clean_gone`, at
`~/.claude/plugins/marketplaces/claude-plugins-official/plugins/commit-commands/commands/clean_gone.md`.
It runs one unattended loop over `[gone]` branches executing
`git worktree remove --force` followed by `git branch -D`.

Measured state of agentics, 2026-08-15:

- 395 local branches; 85 ancestry-merged into `origin/main`; 53 with a `[gone]`
  upstream; only 2 in both sets. The 51 `[gone]`-only branches were each checked
  against the GitHub API: all 51 have MERGED pull requests, so they landed via
  squash merge and are invisible to `git branch --merged` by construction.
  Cleanable candidates across both signals: 136.
- 19 registered worktrees. 3 merged branches still hold one, including the
  worktree this proposal was authored in.
- 9 of 19 worktrees carry untracked files: 16 files total, 0 staged, 0 unstaged
  *today*. The gate keys on any non-empty `git status --porcelain` rather than on
  untracked alone, since a clean staged/unstaged column is a snapshot, not a
  guarantee, and uncommitted tracked edits are worth more than screenshots.
- Those 16 files sort into 11 verification screenshots, 3 copies of
  `.claude/launch.json`, and 3 content files (a plan `.md`, a session log, one
  social-card `.html`). None of these classes is gitignored, so plain
  `git status --porcelain` detects them.
- 20 directories on disk under `.claude/worktrees/` vs 17 registered:
  `charming-gauss-0a0c8c` (3.4M) and `social-post-auto-mode` (3.9M) carry
  dangling `.git` files whose admin directories no longer exist;
  `claude-config-sharing-480f6e` (4K) was never a worktree.
- `git worktree prune --dry-run --verbose` reports nothing, because prune scans
  admin directories and these have none. The built-in does not cover this case.
- `git worktree remove -h` confirms `-f` means "force removal even if worktree is
  dirty or locked" — so an unforced remove already refuses a dirty tree. That is
  the mechanical reason the orphan check belongs before removal, not after.
- `kit/plugins/git-agent/hooks/scope-guard.py` deliberately excludes `rm` and
  `git reset --hard` from blocking, so no existing hook would catch a bad
  cleanup.
</context>

<finding>
Commit ancestry is the wrong test for a squash-merge workflow, and the existing
cleanup path forces past the only safety check that survives it: 51 of this
repo's 136 cleanable branches are invisible to `git branch --merged` despite
every one having a MERGED pull request, while `clean_gone` runs
`git worktree remove --force` and `git branch -D` unattended — destroying, on
agentics today, 16 untracked files across 9 worktrees that an unforced
`git worktree remove` would have refused to touch.
</finding>

<comparison>
| Dimension | Proposed `post-merge-cleanup` | `commit-commands:clean_gone` (existing) |
|---|---|---|
| Selection signal | ancestry **or** merged PR — 136 candidates here | `[gone]` upstream — 53 branches; a reasonable proxy, not the defect |
| Squash-merged branches | detected via the PR signal — 51 here | detected incidentally, since merged branches usually go `[gone]` |
| Uncommitted-work check | gates everything; any non-empty `git status --porcelain` stops the run | none |
| Worktree removal | `git worktree remove` unforced; a dirty tree stops the run and asks | `git worktree remove --force` — destroys uncommitted work |
| Branch deletion | `-d` by default; `-D` only where a merged PR is positive evidence | `git branch -D` unconditionally |
| User interaction | notify, ask, or recommend at every destructive step | none; one unattended loop |
| Unregistered dirs on disk | detected and reported; removed only on per-directory approval | invisible |
| Blast radius on agentics today | 3 branches with worktrees, each individually confirmed | 16 untracked files destroyed across 9 worktrees |
| Degraded mode | without `gh`, falls back to ancestry and says the list is incomplete | n/a |
</comparison>

<decisions>
Locked and resolved — treat these as settled; do not reopen them:

Settled before this draft:

1. **Placement is a new skill inside `kit/plugins/git-agent/`,** not an extension
   of the `merge` skill. Grounded in `merge/SKILL.md:183`, which names branch
   deletion a separate action needing its own explicit yes, and in the global
   rule that treats branch deletion as separately authorized. Propagates to
   Workstream E and the packaging phase of the roadmap.

Resolved in the 2026-08-15 review:

2. **Selection takes either signal: commit ancestry or a merged pull request.**
   *(Revised 2026-08-15 — the original "merged-into-default only" wording was
   overturned by the squash-merge finding.)* A branch is cleanable when
   `git branch --merged origin/<default>` lists it, or when
   `gh pr list --head <branch> --state merged` returns a PR. Ancestry alone would
   miss 51 of 136 candidates here. Consequence: `git branch -d` can no longer
   serve as the safety check on its own — it applies the same ancestry test and
   refuses squash-merged branches — so `-D` is permitted, gated on a confirmed
   merged PR as positive evidence. Without `gh`, the skill degrades to ancestry
   and states that the list is incomplete. Propagates to Workstreams A, B, C.
3. **Run scope is single-branch by default, with a repo-wide sweep behind an
   explicit flag.** Consequence: two report shapes and two approval gates must be
   specified, not one. Propagates to Workstreams B and C, and splits the roadmap
   into separate phases 2 and 3.
4. **Any uncommitted work always stops the run and asks.** The gate fires on a
   non-empty `git status --porcelain` — untracked, staged, or unstaged. The skill
   never auto-deletes and never passes `--force`. Consequence: no file-classification engine
   and no rescue automation are in scope — the skill reports the file list and
   asks. This materially shrinks the skill and removes the tuning burden of
   classification rules. Propagates to Workstreams A and B, and removes the
   classification appendix a "smart defaults" answer would have required.
5. **Unregistered directories on disk are detected and removed by the skill, but
   only on explicit per-directory approval.** Consequence: this is the single
   place a recursive delete lands inside a skill, and the per-directory gate is
   what makes it compatible with the global rule forbidding `rm` without explicit
   approval. Because a dangling `.git` means `git status` cannot inspect these
   directories, the skill must first print size, file count, and most recently
   modified files — the human is the only available check. It requires hard rails (see Workstream D and Risks). Propagates to
   Workstream D and roadmap phase 4.
</decisions>

<workstreams>
**A — Detection and inventory (read-only).** Resolve the default branch and its
remote form. Enumerate cleanable branches by either signal — ancestry or merged
PR, degrading to ancestry with a stated warning when `gh` is unavailable — worktrees registered to those
branches, and each such worktree's `git status --porcelain` output. Enumerate
directories under the worktrees root and diff them against registered worktree
paths to find unregistered leftovers. Nothing here mutates state, which makes it
independently shippable and independently testable.

**B — Single-branch cleanup path (the default).** Given the current branch,
confirm it is merged into the default branch. Inspect its worktree for untracked
files; if any exist, print the file list and stop for a decision rather than
proceeding. On a clean worktree and explicit approval, `cd` out of the worktree,
run `git worktree remove` unforced, then `git branch -d`. Report each command and
its result.

**C — Repo-wide sweep (behind a flag).** The same per-item logic as B applied
across every merged branch, but presented as one inventory table first: branch,
worktree path, untracked-file count. Worktrees with untracked files are listed as
blocked with their file lists, never silently skipped. Approval is per item or
explicitly per batch — the report must make the blast radius legible before any
yes.

**D — Unregistered directory handling.** Report each leftover directory with its
size and the evidence that it is genuinely unregistered: absent from
`git worktree list`, no admin directory under `.git/worktrees/`, and a dangling
or absent `.git` file. Removal requires a per-directory yes, must verify the
resolved path is inside the worktrees root before acting, and must never accept a
path supplied by anything other than this detection step.

**E — Packaging.** Register the skill in the plugin, bump git-agent's version in
`.claude-plugin/marketplace.json` (4.18.0 is current; a version bump is required
by the CI guard for any change under `kit/plugins/git-agent/`), and update the
plugin README skill table and CHANGELOG. Regenerate the root README Plugin
Reference Table with the repo's canonical generator rather than hand-editing.
</workstreams>

<risks>
**A recursive delete now lives inside a skill (Workstream D).** This is the one
genuine hazard, and it exists because the alternative — printing a command for
the user to paste — was explicitly declined. Mitigation: per-directory approval,
a path containment check against the worktrees root, refusal on any path still
registered or still holding an admin directory, and no acceptance of user- or
file-supplied paths.

**Self-deletion.** The skill can be invoked from inside the very worktree it is
asked to remove — true right now, since this proposal was authored on a merged
branch in `.claude/worktrees/lucid-haslett-a66e8b`. It must detect that its cwd
is inside the target and refuse, or relocate first, per the global rule to `cd`
out before removing.

**Sweep blast radius.** One approval covering 85 branches is exactly the kind of
gate that gets clicked through. The sweep report must be legible per item, and
batch approval must be a separate deliberate answer rather than the default.

**Gate friction.** 9 of 19 worktrees carry untracked files, so the stop-and-ask
path is the common case, not the exception. Decision 4 accepts that cost
knowingly; if it proves intolerable, the answer is a classification pass, which
was considered and declined for this version.

**Default-branch resolution.** `git branch --merged origin/main` and
`--merged main` can disagree when local main lags the remote. The skill must
resolve the default branch explicitly and prefer the remote-tracking ref, or it
will misreport what is merged.

**`clean_gone` remains installed and unchanged.** This skill does not disable it,
so the dangerous path stays one command away. Documenting the difference in the
README is the only available mitigation.
</risks>

<open-questions>
Decisions still owned by the human — surface them, do not answer them:

- **Sweep flag naming.** `--all`, `--sweep`, or a separate command such as
  `/git-agent:cleanup-sweep`. A separate command is more discoverable but adds a
  second entry point to maintain.
- **Invocation model.** Manual-invoke only, matching every other git-agent skill,
  or a prompt hook that offers cleanup after `/git-agent:merge` reports a
  successful merge. The hook is more useful and more intrusive; git-agent's
  existing skills are all manual-invoke, which argues for consistency.
</open-questions>

<roadmap>
| Phase | Work | Size | Depends on |
|---|---|---|---|
| 1 | Workstream A — detection and inventory, read-only, with tests against a fixture repo | S | — |
| 2 | Workstream B — single-branch cleanup with the orphan gate | M | 1 |
| 3 | Workstream C — repo-wide sweep behind the flag | M | 2 |
| 4 | Workstream D — unregistered directory detection and gated removal | S | 1 |
| 5 | Workstream E — packaging: registration, version bump to 4.19.0, README and CHANGELOG | S | 2, 3, 4 |
</roadmap>

<appendices>
**Appendix A — Measured inventory, agentics, 2026-08-15.**

| Metric | Value |
|---|---|
| Local branches | 395 |
| Merged into `origin/main` | 85 |
| `[gone]` upstream | 53 |
| In both sets | 2 |
| Squash-merged, invisible to ancestry (all 51 verified MERGED PRs) | 51 |
| Total cleanable candidates (ancestry OR merged PR) | 136 |
| Merged-only | 83 |
| Registered worktrees | 19 |
| Merged branches holding a worktree | 3 |
| Worktrees with untracked files | 9 of 19 |
| Untracked files total | 16 |
| Staged / unstaged files | 0 / 0 |

The 3 merged branches holding a worktree: `claude/cranky-lichterman-2b6c96`,
`claude/intelligent-dubinsky-b80fde`, `claude/post-merge-cleanup-skill-1a088d`.

**Appendix B — Untracked-file inventory by worktree.**

| Worktree | Untracked files |
|---|---|
| `cool-hypatia-17ee9b` | `docs/media/social/feature-background-mode-review-plan-2026-06-07.html`, the matching `.png`, `docs/plans/fix-version-bump-ruleset-bypass.md` |
| `cranky-lichterman-2b6c96` | `.claude/launch.json` |
| `epic-rosalind-febd43` | `.claude/launch.json` |
| `goofy-mirzakhani-0b5b3d` | `share-react-plan-preview.png`, `share-react-plan-reviewed.png` |
| `magical-murdock-fb7def` | `plan-retrofit-responsive-render.png`, `responsive-after-390px.png`, `responsive-before-390px.png` |
| `practical-northcutt-bc910a` | `.claude/launch.json` |
| `quirky-bartik-15e51a` | `build-proposal-plan-full.png`, `build-proposal-plan-reviewed.png`, `build-proposal-step1-config.png` |
| `serene-kirch-a54d28` | `retrofit-audit-multi-host-390px.png` |
| `skills-dynamic-model-switch-21faf0` | `docs/plans/sessions/2026-07-15-base-directory-for-this-skill-users-038bab2b.md` |

**Appendix C — Unregistered directories, with evidence.**

| Directory | Size | Entries | `.git` file | Admin dir | In `worktree list` |
|---|---|---|---|---|---|
| `charming-gauss-0a0c8c` | 3.4M | 19 | present, dangling | absent | no |
| `social-post-auto-mode` | 3.9M | 21 | present, dangling | absent | no |
| `claude-config-sharing-480f6e` | 4.0K | 1 (`placeholder`) | none | absent | no |

`git worktree prune --dry-run --verbose` produces no output against all three,
confirming prune cannot reach them.

**Appendix D — Command contract, safe forms only.**

| Operation | Command |
|---|---|
| Resolve default branch | `git symbolic-ref refs/remotes/origin/HEAD`, falling back to `gh repo view --json defaultBranchRef` |
| List ancestry-merged branches with worktrees | `git branch --merged origin/<default> --format='%(refname:short)\|%(worktreepath)'` |
| Detect a squash-merged branch | `gh pr list --head <branch> --state merged --limit 1` |
| Inspect a worktree | `git -C <path> status --porcelain` |
| Remove a worktree | `git worktree remove <path>` — never `-f` |
| Delete an ancestry-merged branch | `git branch -d <name>` |
| Delete a squash-merged branch | `git branch -D <name>` — only after its merged PR is confirmed |
| Detect unregistered dirs | diff `ls <worktrees-root>` against paths from `git worktree list --porcelain` |
| Confirm a dir is unregistered | `.git/worktrees/<name>` absent, and any `.git` file in it points at a nonexistent path |
</appendices>

Author an execution plan that delivers Workstreams A through E in roadmap order.
Draft real, actionable steps naming the files each one touches — do not restate
the workstream headings as steps. Treat the locked decisions as settled inputs.
Carry both open questions into the plan's unresolved-questions section rather
than answering them.

The plan's tests are Tier 1: this creates application source under
`kit/plugins/git-agent/`, so it needs the mandatory objective-verification test
plus whatever unit coverage the steps warrant. The objective to verify is the
ordering guarantee itself — that a worktree holding untracked files is never
removed and never forced — which is testable against a throwaway fixture repo
built in a temp directory and cleaned up afterward.
