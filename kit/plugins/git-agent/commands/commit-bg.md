---
description: Fire off the agent-commit subagent in the background to stage and commit the working tree, then return control immediately
argument-hint: "[optional commit hint, e.g. 'fix typo in readme']"
allowed-tools: Agent
---

# Background Commit

Dispatch the `agent-commit` subagent in the background. The user wants the
commit to happen while they keep working — do not wait for it to finish.

## Instructions

1. Invoke the `Agent` tool with:
   - `subagent_type: "git-agent:agent-commit"`
   - `run_in_background: true`
   - `description: "Background commit"`
   - `prompt`: A self-contained instruction telling the agent to stage all
     working-tree changes and create a single conventional commit. If
     `$ARGUMENTS` is non-empty, include it in the prompt as a hint about the
     intent of the changes (e.g. "Hint from user: <ARGUMENTS>"). The agent
     already has its full workflow defined in its frontmatter — keep the
     prompt brief.

2. As soon as the agent is dispatched, return control to the user with a
   single-line acknowledgement like "Commit dispatched in background — I'll
   notify you when it's done." Do not poll, sleep, or check progress. The
   user will be notified automatically when the agent completes.

3. Do **not** run any git commands yourself. Do **not** do anything else.
