---
description: Fire off the agent-ship-ci subagent in the background to watch an existing PR's checks, apply deterministic autofixes, and report — then return control immediately
argument-hint: "[optional PR url or number]"
allowed-tools: Agent
---

# Background CI Watch

Dispatch the `agent-ship-ci` subagent in the background. The user wants CI on an
already-open PR watched while they keep working — do not wait for it to finish.

## Instructions

1. Invoke the `Agent` tool with:
   - `subagent_type: "git-agent:agent-ship-ci"`
   - `run_in_background: true`
   - `description: "Background CI watch"`
   - `prompt`: A brief self-contained instruction telling the agent to watch
     the PR's checks, autofix what its allowlist covers, and report. If
     `$ARGUMENTS` is non-empty, pass it through as the PR to watch (e.g.
     "Watch PR <ARGUMENTS>"). Otherwise tell it to resolve the PR from the
     current branch. The agent already has its full workflow in its
     frontmatter — keep the prompt brief.

2. As soon as the agent is dispatched, return control with a single-line
   acknowledgement like "CI watch dispatched in background — I'll notify you
   when checks settle." Do not poll, sleep, or check progress. The user is
   notified automatically when the agent completes.

3. Do **not** run any git or gh commands yourself. Do **not** do anything else.

## If there is no PR yet

The agent stops and says so — it does not create one. Run `/git-agent:ship-bg`
first, then this command.
