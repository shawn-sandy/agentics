---
type: proposal
intent: Add a git-agent skill that gates post-merge branch and worktree removal on an orphaned-file check
techniques: Long-context grounding, XML structure, Comparison tables, Positive framing, Output format
created: 2026-08-15
status: converged
modified: 2026-08-15
generated-sha: edcc5622ae702ca8d86b0b670e9ecb0d28f4f3c2336f452ce8e2cf31af02124d
repo-name: agentics
---

# Proposal: Add Post-Merge Cleanup

> This is a proposal for review, not an execution plan. It carries the
> grounded research and the decisions already made; the final instruction
> below hands off to drafting an execution plan from it.

<tldr>
The nearest existing tool, `commit-commands:clean_gone`, selects branches on the
wrong signal and forces past the only safety check that matters. Measured against
agentics on 2026-08-15 it would force-delete 51 branches that never landed on
main and silently destroy 16 untracked files across 9 worktrees. This proposes a
new git-agent skill, `post-merge-cleanup`, that inverts the order: inspect the
merged branch's worktree for untracked files first, report and ask, and only then
remove the worktree and branch using unforced git commands. Selection is
merged-into-`origin/main` only, which makes `git branch -d` the safety check
rather than a policy the skill has to enforce itself. Single-branch by default,
with a repo-wide sweep behind a flag. The 3 unregistered worktree directories on
disk (~7.3M) that `git worktree prune` cannot see are detected and removed only
on explicit per-directory approval.
</tldr>

<context>
git-agent 4.11.0 ships `branch-agent`, `commit-agent`, `create-issue`, `merge`,
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

- 395 local branches; 85 merged into `origin/main`; 53 with a `[gone]` upstream;
  only 2 in both sets (51 gone-only, 83 merged-only).
- 19 registered worktrees. 3 merged branches still hold one, including the
  worktree this proposal was authored in.
- 9 of 19 worktrees carry untracked files: 16 files total, 0 staged, 0 unstaged.
  In practice "orphaned" means untracked only.
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
The existing cleanup path selects on the wrong signal and forces past the only
safety check that matters: `clean_gone` targets `[gone]` upstreams — 53 branches
here, of which just 2 are actually merged into `origin/main` — then runs
`git worktree remove --force` and `git branch -D` unattended, which against
agentics today would force-delete 51 branches that never landed and silently
destroy 16 untracked files across 9 worktrees.
</finding>

<comparison>
| Dimension | Proposed `post-merge-cleanup` | `commit-commands:clean_gone` (existing) |
|---|---|---|
| Selection signal | merged into default branch — 85 branches here | `[gone]` upstream — 53 branches, only 2 of them merged |
| Orphaned-file check | gates everything; `git status --porcelain` per worktree before any removal | none |
| Worktree removal | `git worktree remove` unforced; a dirty tree stops the run and asks | `git worktree remove --force` — destroys untracked work |
| Branch deletion | `git branch -d` — git itself refuses anything unmerged | `git branch -D` — no merge check at all |
| User interaction | notify, ask, or recommend at every destructive step | none; one unattended loop |
| Unregistered dirs on disk | detected and reported; removed only on per-directory approval | invisible |
| Blast radius on agentics today | 3 merged branches with worktrees, each individually confirmed | 51 unmerged branches force-deleted, 16 untracked files destroyed |
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

2. **Selection is merged-into-default-branch only.** The 51 `[gone]`-but-unmerged
   branches are explicitly out of scope and are not reported as cleanable.
   Consequence: every branch deletion uses `git branch -d`, never `-D`, so git's
   own merge check is the safety mechanism rather than a policy the skill must
   implement and could get wrong. Propagates to Workstreams A, B, C.
3. **Run scope is single-branch by default, with a repo-wide sweep behind an
   explicit flag.** Consequence: two report shapes and two approval gates must be
   specified, not one. Propagates to Workstreams B and C, and splits the roadmap
   into separate phases 2 and 3.
4. **Untracked files always stop the run and ask.** The skill never auto-deletes
   them and never passes `--force`. Consequence: no file-classification engine
   and no rescue automation are in scope — the skill reports the file list and
   asks. This materially shrinks the skill and removes the tuning burden of
   classification rules. Propagates to Workstreams A and B, and removes the
   classification appendix a "smart defaults" answer would have required.
5. **Unregistered directories on disk are detected and removed by the skill, but
   only on explicit per-directory approval.** Consequence: this is the single
   place a recursive delete lands inside a skill, and the per-directory gate is
   what makes it compatible with the global rule forbidding `rm` without explicit
   approval. It requires hard rails (see Workstream D and Risks). Propagates to
   Workstream D and roadmap phase 4.
</decisions>

<workstreams>
**A — Detection and inventory (read-only).** Resolve the default branch and its
remote form. Enumerate branches merged into it, worktrees registered to those
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
`.claude-plugin/marketplace.json` (4.11.0 is current; a version bump is required
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
| 5 | Workstream E — packaging: registration, version bump to 4.12.0, README and CHANGELOG | S | 2, 3, 4 |
</roadmap>

<appendices>
**Appendix A — Measured inventory, agentics, 2026-08-15.**

| Metric | Value |
|---|---|
| Local branches | 395 |
| Merged into `origin/main` | 85 |
| `[gone]` upstream | 53 |
| In both sets | 2 |
| Gone-only (unmerged) | 51 |
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
| List merged branches with worktrees | `git branch --merged origin/<default> --format='%(refname:short)\|%(worktreepath)'` |
| Inspect a worktree | `git -C <path> status --porcelain` |
| Remove a worktree | `git worktree remove <path>` — never `-f` |
| Delete a branch | `git branch -d <name>` — never `-D` |
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
