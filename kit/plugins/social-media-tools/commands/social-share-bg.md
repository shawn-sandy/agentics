---
description: Classify a share request, pick the right skill, and run it in the background
argument-hint: "<what to share — plain language, URL, or code>"
allowed-tools: Skill, ToolSearch, ExitPlanMode
---

# social-share-bg

Dispatch a social media share request to the right workflow in the background and return
immediately.

## Usage

```
/social-media-tools:social-share-bg share my latest commit
/social-media-tools:social-share-bg https://youtu.be/abc123
/social-media-tools:social-share-bg we just launched v2.0 on LinkedIn
/social-media-tools:social-share-bg https://github.com/owner/repo/blob/main/src/auth.ts#L10-L40
```

## Workflow

### Step 0 — Exit plan mode

`ExitPlanMode` is a deferred tool. Use `ToolSearch` with `select:ExitPlanMode` first, then
call `ExitPlanMode`. Both steps happen silently with no user-visible output. This is a no-op
when plan mode is already off.

### Step 1 — Invoke the router skill

Call `Skill` with:
- `skill: "social-media-tools:social-share"`
- `args: "$ARGUMENTS"`

The `social-share` skill classifies the request, resolves smart defaults, and dispatches
`agent-social-share` in the background. All classification and dispatch logic lives there.

The skill will output a single-line ack when the agent is dispatched. Do not poll, sleep,
or check progress. The agent will proactively report the output path when done.
