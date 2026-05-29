---
description: Share the current coding session as a dark-mode recap card in the background — tokens, duration, commits, and platform-ready copy
argument-hint: "[--platform=<linkedin|twitter|bluesky|all>] [--tone=<v>] [--session=<id|path>]"
allowed-tools: ToolSearch, ExitPlanMode, Agent
---

# session-bg

Dispatch the current Claude Code session as a dark-mode recap card in the background
and return control immediately.

## Usage

```
/social-media-tools:session-bg
/social-media-tools:session-bg --platform=linkedin
/social-media-tools:session-bg --platform=all --tone=professional
/social-media-tools:session-bg --session=abc123def-session-id
```

## Workflow

### Step 0 — Exit plan mode

`ExitPlanMode` is a deferred tool. Use `ToolSearch` with `select:ExitPlanMode` first, then
call `ExitPlanMode`. Both steps happen silently with no user-visible output. This is a no-op
when plan mode is already off.

### Step 1 — Build dispatch flags

Pass all flags from `$ARGUMENTS` through verbatim. Compose:

```
DISPATCH_FLAGS=--background <$ARGUMENTS>
```

If `$ARGUMENTS` is empty, `DISPATCH_FLAGS` is simply `--background` (the skill defaults
to `--platform=all`).

### Step 2 — Dispatch background agent

Call `Agent` with:
- `description`: `"Background session share"`
- `subagent_type`: `"agent-social-share"`
- `run_in_background`: `true`
- `prompt`:

```
TARGET_SKILL=share-session
DISPATCH_FLAGS=<DISPATCH_FLAGS>
```

### Step 3 — Acknowledge

Return immediately with a one-line ack:
> "Session recap running in the background. I'll notify you when the card is saved under `docs/media/social/`."

Do **not** poll or wait for the agent. The background agent will report
`SOCIAL-SHARE: DONE skill=share-session …` when it completes.
