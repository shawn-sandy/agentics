---
description: Run the plan-agent review team in the background. Pass the plan path as argument.
allowed-tools: Agent, Bash
---

# Background Plan Review

Dispatch the `agent-review-plan` subagent in the background. The user wants
the full ten-reviewer Agent Team to run while they keep working —
do not wait for it to finish.

## Workflow

### Step 1 — Validate arguments and resolve path

1. If `$ARGUMENTS` is empty, or if `$ARGUMENTS` contains only flag tokens
   (tokens starting with `--`) and no non-flag token, output:

   ```
   Background mode requires a plan path. Usage: /plan-agent:review-plan-bg <path>
   ```

   Stop. Do not dispatch the agent.

2. Extract the first non-flag token from `$ARGUMENTS` as the plan path.
   Resolve it to an absolute canonical path using `realpath`. If `realpath`
   fails (file does not exist), output:

   ```
   Plan file not found: <path>
   ```

   Stop. Do not dispatch the agent.

   Store the resolved absolute path as `<resolved-path>`.

### Step 2 — Dispatch background agent

1. Invoke the `Agent` tool with:
   - `subagent_type: "agent-review-plan"`
   - `run_in_background: true`
   - `description: "Background plan review"`
   - `prompt`: A self-contained instruction embedding only the resolved path:

     ```
     Run the plan-agent review team on "<resolved-path>" in background mode.
     Invoke Skill(skill: "plan-agent:review-plan", args: "<resolved-path> --background")
     and report the path updated in place when done.
     ```

2. As soon as the agent is dispatched, return control with a single-line ack:

   ```
   Background plan review started: <resolved-path>
   ```

   Do not poll, sleep, or check progress. The user will be notified
   automatically when the agent completes.
