# The repo-wide sweep

Reached with `--all`. Same per-branch logic as the single-branch flow, applied
across every cleanable branch — but the report comes first, and approval is
never a single blanket yes.

## Why the report comes first

A sweep can cover hundreds of branches. One approval spanning all of them is a
gate that gets clicked through, which turns a safety prompt into a formality.
The report exists to make the blast radius legible **before** the question is
asked, so the user is answering about something they have actually seen.

## The inventory table

Print this before touching anything:

| Branch | Signal | Worktree | Dirty | Action |
|---|---|---|---|---|
| `claude/some-feature` | ancestry | `.claude/worktrees/some-feature` | 0 | ready |
| `claude/other-thing` | merged PR #412 | `.claude/worktrees/other-thing` | 3 | **blocked** |
| `claude/no-worktree` | ancestry | — | — | ready (branch only) |

Column rules:

- **Signal** — name which one qualified it, and the PR number when it was
  Signal 2. This is what decides `-d` versus `-D`, so it belongs in the report
  rather than buried in the run.
- **Dirty** — the line count from `git status --porcelain`. Zero is the only
  value that permits removal.
- **Action** — `ready`, `blocked`, or `ready (branch only)` for a cleanable
  branch with no worktree.

Follow the table with a one-line summary: how many are ready, how many blocked,
and how many branches carry no worktree at all.

## Blocked items are listed, never skipped silently

Every blocked worktree gets its file list printed under the table:

```
blocked: .claude/worktrees/other-thing (3 files)
  ?? screenshot-before.png
  ?? screenshot-after.png
   M docs/notes.md
```

A worktree that is quietly omitted reads as "nothing to do here", which is the
opposite of the truth. Blocked is a reportable outcome, not an error.

## Approval

Ask per item by default. Batch approval is a **separate, deliberate answer** —
never the default option, and never pre-selected:

- `Approve each one` — step through the ready items individually.
- `Approve all N ready items` — one answer covering the whole ready set. Offer
  this only after the table has been printed, and state N explicitly in the
  label so the count is in front of the user as they answer.
- `Cancel` — do nothing.

Blocked items are never included in a batch approval, whatever the user picks.
Unblocking one means dealing with its files first, which is a separate decision
about specific work.

## Execution order

Work the ready list in order, and for each item follow the single-branch flow's
removal steps exactly — including the self-deletion refusal, which still applies
inside a sweep. If the user is standing in one of the worktrees being swept,
that item is skipped with a note, and the rest of the sweep continues.

Print each command and its result as it runs. A sweep that reports only a
summary at the end gives no way to tell which item a failure belongs to.

## Failure handling

A failed removal stops that item, not the sweep. Collect failures and report
them together at the end with the branch, the command, and the error. Never
retry with `--force` or `-D` to get past a failure — the flags are governed by
the safety contract, not by whether the unforced command worked.
