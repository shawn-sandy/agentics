# Context guard

Step 0's detail. The guard exists because `ship-autonomous` spends session
context it never reads.

## Why the context is pure cost

Every input the pipeline uses comes from `git` and `gh` — `git status`,
`git log`, `gh pr checks`, `gh run view`. **No step reads the conversation.**

Step 5 ends the turn and waits. Each PR event that wakes the session re-sends
the whole transcript as input, so the cost is paid per event, not per run — it
multiplies by how many times CI fails.

## When to run it

Only when the session is already long: unrelated work preceded this invocation,
or many turns have accumulated. **Skip it on a short session, or one started for
this ship** — the guard catches an expensive default, it is not a prompt on
every run.

## The three routes

Offer them with **AskUserQuestion**.

| Route | What happens |
|---|---|
| `clear` | The user runs `/clear`, then re-invokes. Nothing is lost — the pipeline re-derives its state from git. |
| `background` | Dispatch `/git-agent:ship-bg`. Each subagent gets its own context window and this session stays free. |
| `continue` | Run the pipeline in this session anyway. |

**`clear` is a hard STOP.** You cannot clear your own context; trying and
silently failing would run the whole pipeline inside the very session the user
asked to escape. End the turn and let the user re-invoke.

**`background` is two dispatches, not one.** `/git-agent:ship-bg` returns as soon as it dispatches, so the PR does not exist yet — and `/git-agent:ship-ci-bg` stops immediately when the branch has no PR. Wait for ship-bg to report the PR URL, then dispatch `/git-agent:ship-ci-bg` to watch its checks.

**`background` still returns here for the merge.** A subagent has no user to ask
for merge approval, so Step 8 runs in the foreground — here, or via
`/git-agent:merge-bg`.
