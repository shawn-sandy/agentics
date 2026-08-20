---
name: ship-autonomous
description: "Runs the full ship pipeline with verification, CI polling, and bounded autofix. Chains tests, preview, commit, PR, CI poll, and gated merge. Use when asked to autonomously ship or watch CI."
allowed-tools: Bash(git *), Bash(gh *), Bash(npm *), Bash(pnpm *), Bash(yarn *), Bash(jq *), Skill, Read, Edit, Grep, Glob, TodoWrite, AskUserQuestion, ToolSearch, ExitPlanMode, mcp__Claude_Browser__preview_start, mcp__Claude_Browser__preview_logs, mcp__Claude_Browser__read_console_messages, mcp__Claude_Browser__resize_window, mcp__Claude_Browser__computer
---

Branch, commit, open a PR, then watch it and autofix failures.

**Step 5 subscribes to PR events and ends the turn.** Steps 6–8 are standing
policy applied whenever an event wakes the session, not a loop in one turn.

## Guardrails

Hard stops.

- Tests or lint fail: report verbatim and **STOP** — do not commit a red tree.
  Never start a watch-mode script; no `--fix` pre-commit.
- **Any console or server error blocks the pipeline.**
- Pre-commit hook failure: propagate it verbatim, **STOP**. Do not retry. Do not
  use `--no-verify`.
- After subscribing, **end your turn — no polling, sleeping, or `--watch`**;
  never re-poll.
- Cap autofix at **3 attempts per failing check**; the 4th escalates via
  AskUserQuestion.
- Never introduce `any`, `as unknown`, `// @ts-ignore`, or `// @ts-expect-error`,
  and never loosen a type.
- Never guess: unrecognized failures and ambiguous comments →
  **AskUserQuestion**.
- Do not narrate routine investigation; skip duplicate or no-op events.
- A finding that is wrong, non-blocking (nit, style), or re-fired: one reply,
  resolve, **no commit** — no no-op fixes, no batching into a blocking one, no
  follow-on polishing.
- **Never dismiss a review on your own initiative**; never merge around a
  standing change request.
- **Never merge on anything but green.** AskUserQuestion gates it; pin it
  with `--match-head-commit`.
- **Branch deletion requires its own explicit approval** — never pass
  `--delete-branch` on the strength of a merge approval.

## Step 0: Exit Plan Mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Step 1: Pre-flight Guards

Run every check in `references/preflight-and-verify.md` first.

## Step 2: Branch

On the default branch (detection in `references/preflight-and-verify.md`),
invoke the `git-agent:branch-agent` skill (no arguments).

## Step 2.5: Verify Before Committing

Tests, lint, then browser preview — commands in
`references/preflight-and-verify.md`.

## Step 3: Commit

Invoke **`git-agent:commit-agent`** (delegated, no prompt); Step 4 pushes.

## Step 4: Open PR

Invoke **`git-agent:pr-agent`**; its Step 4.7 runs the adversarial pre-PR
review. Capture the PR URL it prints.

## Step 5: Subscribe to PR Activity (preferred) or Poll CI (fallback)

Per `references/pr-events.md`: subscribe, seed the
checklist, post one update, end the turn. No subscribe tool → poll
`gh pr checks` (`state`, not `conclusion`).

## Step 6: Handle Each PR Event

**Refresh the TodoWrite checklist on every event**; post a concise update per
change.

### 6a: Triage

Per `references/pr-events.md`: failing check → 6b; review → 6c; green → Step 7;
else skip.

### 6b: CI failures — classify, then autofix the allow-listed classes

Classify against the table in `references/ci-autofix.md`; autofix only `lint`,
`typecheck`, `peer-deps`.

### 6c: Review comments

Classify severity first, then apply, reply, refute, or escalate per
`references/pr-events.md`.

### 6d: Commit and let the next event drive

Commit via **`git-agent:commit-agent`** (delegated, no prompt), `git push`, then
await events or resume polling.

## Step 7: Green / Done

Per `references/merge-gate.md`: ready the PR, comment CI is green, refresh the
checklist, post status. Fallback stops after Step 8; subscription keeps
handling events until merge, close, or stop.

## Step 8: Merge (only on green, only with approval)

Per `references/merge-gate.md`: re-confirm checks and review state
(`CHANGES_REQUESTED` or an unresolved thread → Step 6), confirm via
**AskUserQuestion**, squash-merge pinned to `headRefOid`, ask about
the branch separately, post the URL, **STOP**.
