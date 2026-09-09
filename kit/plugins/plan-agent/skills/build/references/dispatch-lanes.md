# Dispatch lanes

Loaded from Step 2, and **only** when the spec carries two or more
`### Lane:` headings, `workflow:` is not `never`, and `--sequential` was not
passed. Everything else — fewer than two lanes, `workflow: never`,
`--sequential` — takes the sequential Step 2 and never reads this file.

The split is the plan's, not yours. `implementation-plan` authored the lanes,
the human confirmed them in Align, and the renderer rejected every overlap.
This file dispatches against that split and **never re-splits**: a worker
brief derived from anything but the spec would drift from what the human
approved.

## 1. Read the lanes

```bash
plan-agent-render "<stem>.md" --check
plan-agent-render "<stem>.md" --lanes
```

`--check` exits 1 naming the lane on any ownership rule; fix the **spec** and
re-run, never dispatch around it. `--lanes` prints every lane as JSON —
`name`, `owns`, `after`, `firstStep`, `lastStep`, and `steps` (each with `n`,
`action`, `why`, `verify`, `done`). That table is the whole dispatch input;
do not parse the Markdown by hand. A lane whose every step is already `done`
is skipped as merged (a resumed run).

## 2. Guards

Both guards from `references/resolve-plan.md` Step 1 run again here, because
this path forks branches from the current tree:

- **Staleness** — `git log HEAD..<base>` non-zero → report the count and ask
  whether to update first. Subagent worktrees fork from the default branch
  and lane branches fork from the plan branch, so a plan branch behind its
  base forks every lane from a stale base.
- **Dirty tree** — any modified tracked file other than the plan's own spec
  and rendered HTML → report the files and stop. Uncommitted work never
  travels into a worktree (the `build-fleet` rule).

## 3. Commit the spec

Set `status: in-progress`, re-render, then commit on the plan branch:

```bash
git add "<stem>.md" "<stem>.html"
git commit -m "chore(plan): start <verb-target>"
```

The `<stem>.html` argument is present only when a sibling exists; an
artifact plan commits the spec alone. This commit is not optional: a subagent
worktree shares the repository's `.git` but forks from **committed** state
only, so the lane branch `git checkout -b <plan-branch>--<lane> <plan-branch>`
in every brief resolves to this commit. Confirm the plan branch is not
`main`/`master` before committing; on a protected branch, stop and ask for a
branch name.

Record `<plan-branch>` (`git branch --show-current`) — every brief below
substitutes it.

## 4. The permission warning (once)

In manual permission mode, print exactly once, before the first `Agent`
call:

```text
Worker permission prompts will bubble to this session; the docs recommend pre-approving tools before a laned build.
```

Then dispatch anyway. Never fall back to sequential on permission mode alone
— the user asked for a laned build, and a silent downgrade is the one thing
they cannot see.

## 5. The wave loop

A lane is **ready** when it is not `lead`, is not merged, is not dispatched,
and every lane in its `after:` is merged. Repeat until every non-`lead` lane
is merged:

1. Collect the ready lanes. Dispatch up to `--max` of them (default 3, hard
   cap 5 — a larger `--max` is clamped and said so) **in one message**, one
   `Agent` call each, so they run concurrently. `lead` is never dispatched;
   it runs once, in this session, at step 7.
2. Return control and wait. Do not poll or sleep — the harness notifies you
   as each worker finishes.
3. On each completion, run step 6 for that lane, then return to 1: a merged
   lane may have unblocked others.

Each `Agent` call:

| input | value |
|---|---|
| `subagent_type` | `"general-purpose"` |
| `isolation` | `"worktree"` — the harness creates and removes the worktree; never `git worktree add` by hand |
| `run_in_background` | `true` |
| `model` | `"sonnet"`, or the `--worker-model` alias |
| `description` | `"Lane <lane>"` |
| `prompt` | the lane's brief, below, with `<plan-branch>` substituted |

### The worker brief

The renderer already derived one brief per worker lane — the "Copy worker
brief — lane <name>" rows in the plan's More-ways drawer, built from the
`--lanes` table. Use that text verbatim and substitute the one placeholder
it leaves, `<plan-branch>`. A cold worktree resolves nothing, so a brief that
reaches a worker with any placeholder left in it is a dead run. Its shape:

```text
You are implementing lane "renderer" of the plan at docs/plans/add-lanes.md — Make the plan the dispatch contract.
You own ONLY these paths: scripts/lib/plan-spec.mjs, scripts/build-plan-html.mjs, tests/plan-lanes.test.mjs. Do not create, edit, or delete any file outside them; if a step needs one, stop and report it.

1. git checkout -b add-lanes-2026-09-09--renderer add-lanes-2026-09-09
2. Implement these steps in order, exactly as written:
   1. Parse `### Lane:` headings into sections.lanes. Why: … Verify: `node tests/plan-lanes.test.mjs` exits 0.
   2. Add the --check rules. Why: … Verify: …
3. After each step run its Verify command and record pass or fail.
4. Commit on your branch after the last step. Do not push. Do not edit docs/plans/add-lanes.md.
5. End with exactly this block:

LANE REPORT
lane: renderer
branch: add-lanes-2026-09-09--renderer
steps_done: <comma-separated step numbers>
verify: <N: pass|fail, one per step>
files_changed: <paths>
blocked: <none | what and why>
```

Four properties of that brief are load-bearing and must survive any edit:
the **owns-only file boundary**, the **ordered steps** verbatim from the
spec, **per-step Verify** with a recorded result, and **commit, never push,
never edit the spec** — N lane branches each editing the spec would conflict
on every merge, so the lead is the spec's only writer.

## 6. On each completion

1. **Verify the LANE REPORT against git.** The report is self-reported; the
   repository is the evidence.

   ```bash
   git log --oneline "<plan-branch>..<plan-branch>--<lane>"
   ```

   Zero commits, a missing branch, a `steps_done` that omits a step in the
   lane, any `verify: N: fail`, or a non-`none` `blocked:` → the lane
   **failed**; go to *A failed lane*. A report the branch contradicts is
   marked **unverified — reported by worker**, never green.
2. **Audit ownership.**

   ```bash
   git diff --name-only "<plan-branch>...<plan-branch>--<lane>"
   ```

   Every path must match one of the lane's `owns:` entries — literally, or
   as a glob (`**` spans directories, the same rule `--check` applies). Any
   path outside → **stop** naming the file and the lane, and ask whether to
   widen that lane's `owns:` in the spec and re-run, or discard the branch.
   Never merge it: the boundary the whole model depends on cannot rest on
   worker discipline alone.
3. **Merge.**

   ```bash
   git merge --no-ff "<plan-branch>--<lane>" -m "merge(lane): <lane>"
   ```

   A conflict on a disjoint-ownership plan is a plan bug, not a merge
   problem: abort the merge, name the two lanes and the file, and ask whether
   to resolve by hand or fix the lanes and re-run. Never auto-resolve outside
   the repo's registered merge drivers (`marketplace.json`, gallery
   `index.html`), which git applies on its own.
4. **Tick the lane's steps** (`[x]` after each step number), re-render, and
   commit the spec on the plan branch.
5. **Print the running table**, then return to the wave loop.

### The progress table

One row per lane, reprinted after every merge so a multi-worker run stays
legible:

```text
| lane        | steps | verify           | branch                          | state   |
|-------------|-------|------------------|---------------------------------|---------|
| renderer    | 1-2   | 1 pass, 2 pass   | add-lanes-2026-09-09--renderer  | merged  |
| build-skill | 3     | —                | add-lanes-2026-09-09--build-skill | running |
| lead        | 4     | —                | (main session)                  | pending |
```

`state` is one of `pending`, `running`, `merged`, `failed`, or
`unverified`.

## 7. The lead lane

When every other lane is merged, run the `lead` lane's steps here, in this
session, sequentially — the same walk as the sequential Step 2. It owns the
shared files, so nothing else may be running while it does.

## 8. Gates

Run Steps 3-5 (`references/completion-gates.md`) **once**, on the merged
tree. Workers ran only their steps' `Verify:` lines; the acceptance criteria,
end-to-end verification, and completion checklist are the lead's and are not
delegated. Then report per Step 6 — the tree is committed on the plan branch,
unpushed.

## A failed lane

A worker that died, a `Verify:` that failed, or a `blocked:` report. The
other lanes' merged work is kept — never unwind a merge because a sibling
failed. Ask via `AskUserQuestion` with exactly these options:

- **Re-dispatch the lane** — delete its branch and fork fresh:

  ```bash
  git branch -D "<plan-branch>--<lane>"
  ```

  then dispatch it again from the *current* plan branch. A retry never
  resumes half-done state its own report flagged as failed.
- **Run it here, in the lead** — walk its steps sequentially in this session.
- **Stop** — report the table and leave the tree committed as it stands.

Headless: take **Stop** and report the table; re-dispatching or running a
failed lane without a user is guessing at what went wrong.

## Workflow engine (escalation)

Everything above runs the wave loop on the `Agent` tool, one lane per call.
This section is the escalation: the same wave loop run inside a single
`Workflow` tool invocation, for the callers who ask for it.

### Selection

The Workflow engine is selected only on a spec with 2 or more `### Lane:`
headings, and only by `workflow: always` in the frontmatter, the `--workflow`
flag, or the spec carrying 6 or more lanes. Fewer than 2 lanes never reaches
this section at all: it takes the sequential Step 2 and only emits the
`/workflows` prompt, whatever the frontmatter says.

### Probe before dispatch

Before using the Workflow engine, probe that the `Workflow` tool is callable
in this session — the same way `review-plan` Step 3 probes for it, **never
asserting a version number.** A capability check answers the only question
that matters (is it here right now); a hardcoded minimum version is a guess
that goes stale the moment the tool's availability changes.

When the `Workflow` tool is absent, print exactly:

"`This laned build asked for the Workflow engine, which is not available in this session; re-run without --workflow (or with workflow: auto) to use the Agent dispatcher.`"

and stop. Calling `Workflow` from this skill is authorized by the tool's own
opt-in rule for a skill whose instructions say to call it — these
instructions are that, and no further user confirmation is needed.

### Dispatch

Otherwise, Read `references/implement-workflow.mjs` and pass its contents as
the `Workflow` tool's inline `script` input — never by path, for the same
shell-expansion reason section 1 gives for `plan-agent-render`: a
plugin-root-anchored invocation is unrunnable at any permission level.

Pass `args` as a real object, never a JSON-encoded string:

| key | value |
|---|---|
| `planPath` | the plan's absolute path |
| `planBranch` | the plan branch every lane forks from and merges back to (section 3) |
| `workerModel` | `--worker-model`'s value, default `sonnet` |
| `lanes` | `[{ name, owns, after, brief }]` — one entry per worker lane |

Each `brief` is section 5's "The worker brief" — the renderer's worker brief
for that lane, with `<plan-branch>` substituted — the exact text the Agent
path uses. `lead` is never included in `lanes`: the lead always runs in this
session, after every worker lane here has merged.

### On return

The script returns `{ reports, mergeOrder }`. Merge each lane named in
`mergeOrder`, in that order, following section 6 exactly as the Agent path
does for each one: verify the LANE REPORT against git, audit ownership,
merge `--no-ff`, tick the lane's steps, re-render, and print the progress
table. Once every lane in `mergeOrder` is merged, run the `lead` lane
(section 7) and then Steps 3-5 (section 8).
