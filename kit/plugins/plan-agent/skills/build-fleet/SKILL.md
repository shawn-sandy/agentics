---
name: build-fleet
description: "Ships a backlog of plans in parallel, one isolated worktree agent per plan. Each agent builds its plan, opens a PR, and watches CI. Use when asked to implement a plan backlog in parallel."
allowed-tools: Agent, Bash(git *), Bash(gh *), Glob, Grep, Read, AskUserQuestion, TodoWrite, ToolSearch, ExitPlanMode
argument-hint: "[<plan.md> ...] [--dir <path>] [--max N]"
---

# Plan Agent — Build Fleet

## Overview

Turns the plans directory into a queue you feed instead of a loop you babysit.
One subagent per plan, each in its own git worktree, each running the same
`build` → `ship-autonomous` chain a solo run would.

**This skill dispatches. It does not implement.** Every step of the actual
work — the completion gates, the browser verification, the commit, the PR, the
CI autofix, the review triage — belongs to `plan-agent:build` and
`git-agent:ship-autonomous` and is not restated here. If those change, this
skill inherits the change.

Seam against its siblings: `build` ships one plan on the current branch;
`build-fleet` ships N plans on N branches. One plan in the backlog → just call
`build`, and say so rather than spawning a fleet of one.

## Guardrails

- **Never dispatch without the Step 2 confirmation.** N agents open N pull
  requests against a shared remote. That is outward-facing and not undoable by
  editing a file.
- **`--max` defaults to 3.** More than 3 concurrent agents on one repo means
  more merge conflicts than saved wall-clock, and the subagent pool queues past
  the concurrency cap anyway.
- **`status: completed` plans are never candidates**, even when named
  explicitly — confirm with the user first.
- **The fleet stops at green.** Merging is yours; see *Merging* below.
- A dirty working tree stops the run: report the files and ask. Worktrees fork
  from `origin/main`, so uncommitted work in the parent tree silently does not
  travel with them.

## Step 0 — Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Step 1 — Collect candidates

Resolve the plans directory exactly as `build` does — see
`../build/references/resolve-plan.md` ("Resolve the plans directory the way
sibling skills do").

Non-flag tokens in `$ARGUMENTS` are an explicit plan list; resolve each as a
path, then by basename under the plans directory, and stop naming every path
tried if one misses. With no tokens, discover: every `*.md` spec in the plans
directory tree whose frontmatter is `status: todo`, excluding `archive/` and
`artifacts/`.

Read only the frontmatter — the fleet agents read the bodies.

```bash
git fetch origin
```

No candidates → say so and stop. Do not fall back to authoring a plan; that is
`build`'s no-plan chain, and a backlog run is not the place to start one.

## Step 2 — Confirm the fleet (mandatory)

Show the candidate list — plan name, `type:`, and one-line objective — then
`AskUserQuestion`: dispatch all, dispatch a subset, or cancel. Name the number
of PRs that will open.

Headless (no `AskUserQuestion`): **cancel**. Print the list and the command to
re-run interactively. Opening pull requests is not a defaultable decision.

## Step 3 — Dispatch

Seed a `TodoWrite` checklist, one entry per plan. Then one `Agent` call per
confirmed plan, all in a single message so they run concurrently:

- `subagent_type: "general-purpose"`
- `isolation: "worktree"` — the harness creates the worktree and removes it if
  the agent leaves it unchanged. Never `git worktree add` by hand here.
- `run_in_background: true`
- `description`: `"Ship <plan-stem>"`
- `prompt`: self-contained, embedding the **absolute** spec path:

  ```
  Branch off origin/main, then implement and ship this plan end to end.

  1. git checkout -b <verb-target-YYYY-MM-DD> origin/main
  2. Skill(skill: "plan-agent:build", args: "<abs-path>")
  3. Skill(skill: "git-agent:ship-autonomous")

  Both skills carry their own gates and guardrails — follow them as written.
  Stop at a green PR: do not merge, do not delete a branch.
  Report the plan name, the branch, the PR URL, and any gate you could not
  clear.
  ```

Return control with a one-line ack per dispatched plan. Do not poll, sleep, or
`--watch` — `ship-autonomous` subscribes to PR events, and the harness notifies
you when each agent finishes.

## Step 4 — Report

When the agents report back, print one table: plan, branch, PR, status,
blocked-on. Tick the checklist. Then stop.

## Merging

The fleet deliberately ends at green PRs rather than merging in dependency
order. A background agent cannot answer `ship-autonomous`'s merge gate, and
auto-merging N sibling PRs is the one step in this chain with no cheap undo.

Merge them yourself with `/git-agent:merge`, oldest first. In this repo the two
registered merge drivers already resolve the conflicts a fleet actually
produces — `marketplace.json` keeps the higher semver, gallery `index.html`
files union their cards — so sibling PRs touching those files rebase cleanly.
A PR that goes `BEHIND` or `CONFLICTING` on anything else needs a rebase before
its gate re-runs.

## Usage

```bash
/plan-agent:build-fleet                                  # every todo plan, max 3
/plan-agent:build-fleet --max 5
/plan-agent:build-fleet docs/plans/add-foo.md docs/plans/add-bar.md
/plan-agent:build-fleet --dir tmp/plans
```
