---
status: completed
type: standard
created: 2026-05-28
---

# Plan: Add PR-event watch + autofix to ship-autonomous

## Context

The user wants `ship-autonomous` to keep working a PR after it is opened:
subscribe to the PR's activity events, autofix CI failures and respond to
review comments, and give regular status updates. The skill previously stopped
its watch at a synchronous `gh pr checks --watch` poll loop and only handled CI
failures, escalating-and-stopping on anything it could not classify.

The remote execution environment (Claude Code on the web / GitHub Actions)
exposes `mcp__github__subscribe_pr_activity` and
`mcp__github__unsubscribe_pr_activity`, which deliver CI and comment activity as
`<github-webhook-activity>` events that wake the session. This replaces polling
with an event-driven model. Local installs without the GitHub MCP server keep
the polling path as a fallback.

Decisions confirmed with the user:
- Package the behavior by **extending `ship-autonomous`** (not a new skill).
- On ambiguous review comments or failures outside the safe allowlist
  (`lint`/`typecheck`/`peer-deps`), **ask the user** via `AskUserQuestion`
  rather than guessing.

## Changes

| # | Action | File | Description |
|---|--------|------|-------------|
| 1 | MODIFY | `kit/plugins/git-agent/skills/ship-autonomous/SKILL.md` | Replace poll loop with event subscription; handle review comments; ask-the-user escalation; regular updates; polling fallback |
| 2 | MODIFY | `kit/plugins/git-agent/README.md` | Update Skills line + ship-autonomous section for the watch/autofix lifecycle |
| 3 | MODIFY | `kit/plugins/git-agent/CHANGELOG.md` | Add v3.9.0 entry |
| 4 | MODIFY | `.claude-plugin/marketplace.json` | Bump git-agent 3.8.0 → 3.9.0 (MINOR: new capability) |

## Step 1: SKILL.md

- Frontmatter: add `mcp__github__subscribe_pr_activity` and
  `mcp__github__unsubscribe_pr_activity` to `allowed-tools`; rewrite the
  `description` to cover the watch/autofix lifecycle (≤256 chars, short first
  sentence).
- Intro: describe the event-driven model — run Steps 0–5 in order; Step 5
  subscribes and ends the turn; Steps 6–7 are the standing policy applied per
  event.
- Steps 0–4 unchanged (exit plan mode, guards, branch, commit, open PR).
- **Step 5 (rewritten):** preferred path loads + calls
  `subscribe_pr_activity`, seeds a TodoWrite checklist, posts an initial status
  update, and ends the turn. Fallback path (tool unavailable) polls
  `gh pr checks --watch` synchronously.
- **Step 6 (rewritten):** triage each event. CI failures → classify
  (`lint`/`typecheck`/`peer-deps` autofix; else ask). Review comments → apply
  clear in-scope changes; ask if ambiguous. Cap 3 attempts per check. Refresh
  TodoWrite and post a concise update on each meaningful change.
- **Step 7 (rewritten):** on all-green, mark ready, comment, send final update.
  Fallback mode stops; subscription mode stays subscribed for later review
  comments and unsubscribes only on merge/close or user stop.

## Step 2–4: Docs + version

- README: Skills bullet + detailed section reflect subscription, review-comment
  handling, ask-the-user escalation, and the local polling fallback.
- CHANGELOG: v3.9.0 entry.
- marketplace.json: git-agent `version` 3.8.0 → 3.9.0.

## Verification

1. JSON validity of `marketplace.json` (passes auto-validation hook).
2. Skill description ≤256 chars with a short first sentence.
3. Manual read-through: Steps 0–4 unchanged; Step 5 ends the turn after
   subscribing; fallback polling path intact for local installs.
4. Real end-to-end requires a remote session with a live PR — event delivery
   and autofix cannot be exercised from a static check.

## Next Steps (Out of Scope)

- Mirror the watch/autofix behavior into the `agent-ship` background subagent.
- Configurable autofix allowlist / attempt cap via skill arguments.
