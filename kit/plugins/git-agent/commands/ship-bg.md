---
description: Fire off the agent-ship subagent in the background to commit, push, and open a PR/MR end-to-end, then return control immediately
argument-hint: "[optional commit/PR hint]"
allowed-tools: Agent
---

# Background Ship

Dispatch the `agent-ship` subagent in the background. The user wants the full
ship pipeline (commit + push + PR/MR) to run while they keep working — do not
wait for it to finish.

## Instructions

1. Invoke the `Agent` tool with:
   - `subagent_type: "git-agent:agent-ship"`
   - `run_in_background: true`
   - `description: "Background ship"`
   - `prompt`: A self-contained instruction telling the agent to stage,
     commit, push, and open a pull/merge request for the current branch. If
     `$ARGUMENTS` is non-empty, include it in the prompt as a hint for the
     commit message or PR summary (e.g. "Hint from user: <ARGUMENTS>"). The
     agent already has its full workflow defined in its frontmatter — keep
     the prompt brief.

2. As soon as the agent is dispatched, return control to the user with a
   single-line acknowledgement like "Ship dispatched in background — I'll
   notify you when it's done." Do not poll, sleep, or check progress. The
   user will be notified automatically when the agent completes.

3. Do **not** run any git, gh, or glab commands yourself. Do **not** do
   anything else.
