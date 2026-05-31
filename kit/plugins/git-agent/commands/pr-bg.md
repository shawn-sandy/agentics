---
description: Fire off the agent-pr subagent in the background to push the current branch and open a GitHub PR, then return control immediately
argument-hint: "[optional PR title or context hint]"
allowed-tools: Agent
---

# Background PR

Dispatch the `agent-pr` subagent in the background. The user wants the PR to
be created while they keep working — do not wait for it to finish.

## Instructions

1. Invoke the `Agent` tool with:
   - `subagent_type: "git-agent:agent-pr"`
   - `run_in_background: true`
   - `description: "Background PR creation"`
   - `prompt`: A self-contained instruction telling the agent to push the
     current branch (if needed) and open a GitHub pull request. If
     `$ARGUMENTS` is non-empty, include it in the prompt as a hint for the
     PR title or summary (e.g. "Hint from user: <ARGUMENTS>"). The agent
     already has its full workflow defined in its frontmatter — keep the
     prompt brief.

2. As soon as the agent is dispatched, return control to the user with a
   single-line acknowledgement like "PR dispatched in background — I'll
   notify you when it's done." Do not poll, sleep, or check progress. The
   user will be notified automatically when the agent completes.

3. Do **not** run any git or gh commands yourself. Do **not** do anything else.
