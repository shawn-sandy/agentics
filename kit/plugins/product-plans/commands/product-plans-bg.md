---
description: Run the product-plans review panel in the background. Pass the plan path as argument.
allowed-tools: Agent
---

# Background Product Plans

Dispatch the `agent-product-plans` subagent in the background. The user wants
the full six-reviewer cross-functional panel to run while they keep working —
do not wait for it to finish.

## Workflow

### Step 1 — Validate arguments

1. If `$ARGUMENTS` is empty, or if `$ARGUMENTS` contains only flag tokens
   (tokens starting with `--`) and no non-flag token, output:

   ```
   Background mode requires a plan path. Usage: /product-plans:product-plans-bg <path>
   ```

   Stop. Do not dispatch the agent.

2. Invoke the `Agent` tool with:
   - `subagent_type: "agent-product-plans"`
   - `run_in_background: true`
   - `description: "Background product-plan panel review"`
   - `prompt`: A self-contained instruction embedding `$ARGUMENTS`. Example:

     ```
     Run the product-plans review panel on $ARGUMENTS in background mode.
     Invoke Skill(skill: "product-plans:plan-review-agents", args: "$ARGUMENTS --background")
     and report the path updated in place when done.
     ```

3. As soon as the agent is dispatched, return control with a single-line ack:

   ```
   Background panel review started: $ARGUMENTS
   ```

   Do not poll, sleep, or check progress. The user will be notified
   automatically when the agent completes.
