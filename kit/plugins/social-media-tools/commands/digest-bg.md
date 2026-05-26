---
description: Run the git history or codebase scan in the background and write the digest while you keep working
argument-hint: "[--days=7] [--base=main] [--max=20] | --codebase <path>"
allowed-tools: Agent, ToolSearch, ExitPlanMode
---

# digest-bg

Dispatch the digest scan to a background agent and return immediately.

## Usage

```
/code-share:digest-bg                          # scan last 7 days of git history in background
/code-share:digest-bg --days=14               # scan last 14 days
/code-share:digest-bg --codebase src/         # scan a codebase path
```

## Workflow

### Step 0 — Exit plan mode

`ExitPlanMode` is a deferred tool. Use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode`. Both steps happen silently with no user-visible output. This is a no-op when plan mode is already off.

### Step 1 — Dispatch background agent

Invoke the `Agent` tool with:
- `subagent_type: "code-share:agent-digest"`
- `run_in_background: true`
- `description: "Background code digest scan"`
- `prompt`: A self-contained instruction embedding `$ARGUMENTS`. Example:

  ```
  Run the digest scan with these arguments: $ARGUMENTS
  Invoke Skill(skill: "code-share:scan-for-shares", args: "$ARGUMENTS --background")
  and write the digest to .claude/digests/. Report the output path when done.
  ```

### Step 2 — Return immediately

As soon as the agent is dispatched, output a single-line ack:

```
Background digest started. You will be notified when .claude/digests/ is ready.
```

Do not poll, sleep, or check progress. The agent will proactively report the output path when done.
