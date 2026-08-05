---
description: Fire off the agent-merge subagent in the background to run the PR readiness gate and merge if green, then return control immediately
argument-hint: "[optional PR url or number]"
allowed-tools: Agent
---

# Background Merge

Dispatch the `agent-merge` subagent in the background. The user wants the merge
check to run while they keep working — do not wait for it to finish.

## Instructions

1. Invoke the `Agent` tool with:
   - `subagent_type: "git-agent:agent-merge"`
   - `run_in_background: true`
   - `description: "Background merge"`
   - `prompt`: A brief self-contained instruction telling the agent to run the
     merge readiness gate and squash-merge only if everything is green,
     reporting otherwise. If `$ARGUMENTS` is non-empty it is the **PR to act
     on**, not a summary hint — pass it through as such (e.g. "Check PR
     <ARGUMENTS>") and say it takes precedence over the checked-out branch.
     Otherwise tell it to resolve the PR from the current branch. The agent already has its full workflow
     in its frontmatter — keep the prompt brief.

2. As soon as the agent is dispatched, return control with a single-line
   acknowledgement like "Merge check dispatched in background — I'll notify you
   with the result." Do not poll, sleep, or check progress. The user is
   notified automatically when the agent completes.

3. Do **not** run any git or gh commands yourself. Do **not** do anything else.

## What the dispatch authorizes

Running this command is the approval for **one squash merge of a fully green
PR** — it replaces the `merge` skill's `AskUserQuestion` prompt, which a
background agent cannot show. Anything else — a **required** check pending or
failing, conflicts, `CHANGES_REQUESTED`, a `mergeStateStatus` outside
`CLEAN` / `UNSTABLE` / `HAS_HOOKS`, a failing lint gate — comes back as a
report, not a merge. A *non-required* check that is pending or failing is
reported alongside the merge, not treated as a block. The agent never passes
`--delete-branch`.

If you want to review the status yourself before merging, type `merge?` or run
the `merge` skill in the foreground instead.
