# Phase checkpoints

Loaded from Step 2, and **only** when the spec's `## Steps` carries
`### Phase: <name>` headings. A spec with none is one uninterrupted walk from
the first unmarked step to the last — no checkpoints, no offer, no behaviour
change of any kind.

## Why this exists

A plan whose steps must run in order cannot be split across subagents: step
seven depends on a choice made in step two. `workflow` fans out and does
nothing for that shape. Bounding *context* rather than parallelising work is
what a checkpoint buys, and stopping is what makes the bound real.

## The loop

Phases group the same flat numbering, so nothing about the walk changes except
where it pauses. Resume is still "the first step with no `[x]` marker", never
"the start of a phase". For each phase, in order:

1. **Implement its steps** and insert each one's `[x]` marker as you finish it.
2. **Run those steps' `Verify:` lines.** A failure stops here — fix it before
   the boundary. Never carry a broken phase across a checkpoint; the next
   session cannot see what you knew about it.
3. **Append what the phase settled to `## Decisions`** — one `- ` bullet per
   choice, each naming the choice *and its reason*. Create the section after
   `## Objective`/`## Context` if the spec has none. This is the ledger a
   resumed session reads instead of re-deriving; a bullet that records only the
   outcome invites the next context window to re-open the question. Record
   decisions, not a summary of the diff.
4. **Re-render**, then reach the boundary offer.

**With `--continue`, skip the offer** and start the next phase immediately.
After the **last** phase there is no offer either — fall through to Step 3.

## The boundary offer

`AskUserQuestion` with exactly these three options:

- **Compact and continue** *(recommended)* — print the `/compact` command below
  and **stop** so the user can run it. `/compact` is a CLI built-in the user
  types, not a tool this skill can call; offering to run it would be a promise
  that cannot be kept.
- **Stop here — resume later** — print the resume command and stop.
- **Continue without compacting** — start the next phase in this session.

```text
/compact Keep: the plan spec at <spec path>, the Decisions ledger, and that phase "<finished phase>" is complete. Then run: /plan-agent:build <spec path>
```

Substitute the real spec path and the name of the phase just finished — a
focus instruction that names neither leaves the summariser guessing at what
the next phase needs.

The resume command for either stopping branch is:

```text
/plan-agent:build <spec path>
```

Compaction is safe mid-plan **because the durable state is not in the
conversation**: step `[x]` markers, `status:`, and the Decisions ledger all
live in the spec, so a lossy summary of the conversation costs the next phase
nothing. That is the whole reason this offer exists here and nowhere else in
this skill.

**Headless (no user to ask):** report the three options and stop at the
boundary. Do not pick one — the same `AskUserQuestion`-unavailable rule
`resolve-plan.md` states for every other gate in this skill.

## Completion

`finalize-plan` will not set `status: completed` while any phase still holds an
unmarked step; it names each unfinished phase in the `## Completion Report`
instead. Keep the two consistent when either changes.
