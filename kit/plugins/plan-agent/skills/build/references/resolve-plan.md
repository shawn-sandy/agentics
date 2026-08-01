# Exit plan mode and resolve the plan

Loaded at the start of a run. Covers Step 0 and Step 1 — the pre-flight
dirty-tree guard, the `AskUserQuestion`-unavailable rule, plans-directory
resolution, the discovery offer, and the preconditions.

## Step 0 — Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

Produce no plan document — execute the workflow directly.

## Step 1 — Resolve the plan

**Pre-flight guard — runs before anything else, chain included:**

- Dirty working tree → report the uncommitted files and ask whether to
  proceed, so the plan's changes stay separable from pre-existing work. This
  runs **ahead of Step 1b**, not after it: a chained run crosses a proposal loop
  and a plan interview before it writes a line of source, and asking about
  uncommitted files at the end of that is the worst possible moment.
  `git-agent:ship-autonomous` runs every pre-flight guard before any mutation;
  this matches.
- **Plan artifacts are never pre-existing work.** Exclude the resolved plan's
  own spec and rendered HTML, and any artifact this chain's proposal stage wrote
  — the saved proposal prompt under the prompts directory **and** the deprecated
  legacy copy under the proposals directory — from the dirty report. Without that exclusion the Step 8 `Implement now` callback re-enters
  this skill with the just-authored plan sitting uncommitted, so the guard fires
  at exactly the post-interview moment the hoist exists to avoid — and in a
  headless run the unavailable-question rule below would stop the chain
  outright. When those artifacts are the only changes, the tree is clean for
  this purpose: proceed silently.

**When `AskUserQuestion` is unavailable** — a headless or otherwise
non-interactive run — every gate in this skill **stops and reports the choice it
would have offered**, listing the options. This covers the discovery offer, the
objective prompt, the proposal-versus-direct gate, and the preconditions.
**Never resolve a gate by picking for the user.** A lone discovery candidate
adopted because it was the only one is exactly the silent pickup the offer
exists to prevent, and a proposal-versus-direct gate answered by default commits
the user to an authoring branch they never chose.

Resolve the plans directory the way sibling skills do: `--dir` if given, else
the `planAgent.plansDirectory` / `plansDirectory` setting (project-local
`.claude/settings.local.json` → project `.claude/settings.json` →
`~/.claude/settings.json`), else `docs/plans/`.

1. `$ARGUMENTS` names a path → use it **as given** if that file exists
   (absolute paths and `--dir tmp/plans` plans resolve here). Otherwise retry
   its basename under the resolved plans directory. Still nothing → say which
   paths were tried, add the misparse note above when the token was a
   slash-bearing objective, and **stop**. Do not fall through to discovery and
   implement a different plan, and do not enter Step 1b: chaining on a mistyped
   filename would author a whole plan because of a typo.
2. No path argument → **the only branch that reaches Step 1b.**
   - **An objective was supplied** → skip discovery entirely and go to
     Step 1b. The user has already said what they want, so unrelated `todo`
     specs are noise: discovery selects on `status:` alone with no notion of
     subject, and offering a dozen unrelated plans in answer to "a todo app"
     is worse than not asking.
   - **No objective** → discovery, and it is an **offer, never a silent
     pickup**: list `.md` specs in the resolved plans directory whose
     frontmatter `status:` is `todo` or `in-progress`, newest `created:` first
     (missing or tied `created:` → fall back to file mtime). **Never descend
     into `archive/`.** Present **at most the top three** candidates plus
     `None of these — author a new plan` via `AskUserQuestion`, and state how
     many were suppressed when there are more (`AskUserQuestion` caps at four
     options, so an unbounded offer cannot render at all). This holds for a
     single match too — one candidate is still offered, not adopted. No
     candidates at all → go straight to Step 1b. `None of these` → Step 1b.
3. An `.html` argument resolves to its sibling `<stem>.md`. No sibling spec
   (legacy HTML-only plan) → stop and say so; this skill edits specs, not HTML.
   Do not enter Step 1b: a plan exists and needs its spec reconstructed, not a
   new plan authored on top of it.

**Preconditions — check before writing anything:**

- Spec already `status: completed` → stop and ask via `AskUserQuestion`
  whether to re-implement; do not silently redo finished work.
- Steps already carrying `[x]` → resume from the first unmarked step rather
  than re-applying completed ones.

Echo the resolved spec path, `<stem>`, and objective before starting.
