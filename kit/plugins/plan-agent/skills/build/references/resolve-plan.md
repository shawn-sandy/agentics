# Exit plan mode and resolve the plan

Loaded at the start of a run. Covers Step 0 and Step 1 — the pre-flight
dirty-tree guard, plans-directory resolution, the headless defaults, and the
preconditions. The **argument precedence ladder** that decides whether
`$ARGUMENTS` is a path, an objective, or nothing lives in `invocation.md`;
read that first.

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
  at exactly the post-interview moment the hoist exists to avoid. When those
  artifacts are the only changes, the tree is clean for this purpose: proceed
  silently.
- **Stale checkout → stop and ask.** A plan is written against a snapshot of
  the repo. Implementing it from a checkout that predates that snapshot makes
  every premise in it suspect — "this file is unreferenced", "this helper does
  not exist yet", "this API still takes two arguments" — and the result is work
  that is *confidently wrong* rather than obviously broken: it passes its own
  verification and fails only against reality. Count the distance first:

  ```bash
  git fetch origin --quiet
  BASE=$(git symbolic-ref -q --short refs/remotes/origin/HEAD || echo origin/main)
  git log "HEAD..$BASE" --oneline | wc -l
  ```

  Resolve `BASE` rather than hardcoding `origin/main` — the third line dies on
  line 1 in every `master` and `develop` repo otherwise. **Zero** → proceed
  without comment; a guard that narrates itself on every clean run trains the
  user to skip reading it. **Non-zero** → report the count and the base branch
  and ask whether to update or proceed anyway. Never update the checkout on
  your own: a rebase or merge here can conflict with uncommitted work, and
  which to run is the user's call.
- **In a worktree this is the only freshness signal that counts.** A worktree
  can report a clean tree, an up-to-date upstream, and a branch that exists on
  origin while still sitting many commits behind the default branch. A
  SessionStart hook saying "already at origin/main" describes the branch's
  tracking ref, not the distance from the default branch — it is not this
  check and does not substitute for it. Detached HEAD, no `origin`, an
  unresolvable base, or a failed fetch (offline, no auth) → say the check could
  not run and continue. This is a guard, not a gate.

Resolve the plans directory the way sibling skills do: `--dir` if given, else
the `planAgent.plansDirectory` / `plansDirectory` setting (project-local
`.claude/settings.local.json` → project `.claude/settings.json` →
`~/.claude/settings.json`), else `docs/plans/`.

Then classify `$ARGUMENTS` with the precedence ladder in `invocation.md`:

1. **Rule 1 — path.** An existing file wins outright, whitespace included;
   otherwise the shape test applies. Resolve as given, then by basename under
   the plans directory. Neither exists → **stop**, say which paths were tried,
   and add the misparse note when the token was slash-bearing with no
   `.md`/`.html` suffix. **Do not enter Step 1b**: chaining on a mistyped filename would
   author a whole plan because of a typo. An `.html` with no sibling spec stops
   the same way — this skill edits specs, not HTML, and again **do not enter
   Step 1b**.
2. **Rule 2 — objective.** The only branch that reaches Step 1b with something
   to build. Discovery is skipped entirely: the user has already said what they
   want, and discovery selects on `status:` alone with no notion of subject, so
   offering a dozen unrelated `todo` plans in answer to "a todo app" is worse
   than not asking.
3. **Rule 3 — empty.** Discovery, per the table in `invocation.md`: one match
   auto-selects, several are offered, none asks for an objective and enters
   Step 1b.

## When `AskUserQuestion` is unavailable

A headless or otherwise non-interactive run has no way to ask. Each gate below
therefore carries a **named default**: take it, and log it on one line as
`Assumption: <what was chosen> — <why>`. **Never halt merely because
`AskUserQuestion` is unavailable — follow the table.** Some of its defaults are
themselves "report and stop", and taking one of those is following the table,
not halting on the missing tool. An unlogged or improvised default is the real
failure mode: the same missing tool once resolved two opposite ways in two runs
because the fallback was undefined.

| Gate | Default | Why it is the safest |
|------|---------|----------------------|
| Discovery, one candidate | Adopt it | Identical to the interactive path — there is no ambiguity to resolve |
| Discovery, several candidates | Newest `in-progress` spec | Work already underway is the least surprising continuation. **No `in-progress` spec → report the ranked list and stop.** This is the one gate with no safe default: every candidate is equally plausible and picking wrong writes source for a plan the user never chose |
| Discovery, no candidates | Report and stop | There is nothing to build and no default can invent an objective |
| Proposal-versus-direct (Step 1b) | `Straight to plan authoring` | Writes one artifact instead of two and skips a research loop the user did not ask for |
| Spec already `status: completed` | Do not re-implement; report and stop | Redoing finished work is destructive; declining it is not |
| Dirty working tree | Read `git status --porcelain`. Every remaining entry `??` (untracked) → **list them and proceed**. Any tracked file modified, added, renamed, or deleted → report and stop | Deterministic on the status code, so two runs cannot disagree. A modified tracked file is work in progress that the plan's diff would tangle with; stray untracked files are the logs, caches, and editor droppings every real repo carries, and stopping on those halts every headless run for nothing |
| Phase checkpoint (Step 2) | Stop at the boundary | Already the interactive default; `--continue` is the explicit opt-out |

**Preconditions — check before writing anything:**

- Spec already `status: completed` → stop and ask via `AskUserQuestion`
  whether to re-implement; do not silently redo finished work.
- Steps already carrying `[x]` → resume from the first unmarked step rather
  than re-applying completed ones.

Echo the resolved spec path, `<stem>`, and objective before starting.

## Resolution test table

Every row is a real invocation this ladder must handle. `docs/plans/` is the
resolved plans directory unless `--dir` says otherwise.

| # | `$ARGUMENTS` | Rest string | Rule | Outcome |
|---|--------------|-------------|------|---------|
| 1 | `docs/plans/add-auth.md` *(exists)* | `docs/plans/add-auth.md` | 1 — path | Implement it. `<stem>` is `docs/plans/add-auth` |
| 2 | `docs/plans/add-athu.md` *(missing)* | `docs/plans/add-athu.md` | 1 — path | **Stop.** Name both paths tried (as given, then basename under `docs/plans/`). No discovery, no Step 1b |
| 3 | `A/B testing for checkout` | `A/B testing for checkout` | 2 — objective | Whitespace disqualifies the path test. Author a plan for the **whole** string via Step 1b |
| 4 | `--dir tmp/plans` *(1 open spec there)* | *(empty)* | 3 — discovery | Auto-select that spec, echo the path and why. No halt |
| 5 | `--dir tmp/plans` *(4 open specs there)* | *(empty)* | 3 — discovery | Offer the newest three plus `None of these — author a new plan`, stating that 1 was suppressed |
| 6 | *(nothing)* *(no open specs)* | *(empty)* | 3 — discovery | Ask for an objective, then Step 1b |
| 7 | any of rows 4-6, `AskUserQuestion` unavailable | — | 3 — discovery | Take the row's named default from the table above and log `Assumption: …`. Row 5 with no `in-progress` candidate is the sole stop |
| 8 | `my plans/add-foo.md` *(exists; plans dir has a space)* | `my plans/add-foo.md` | 1 — path | Whitespace, but the file **exists**, so test (1) wins and it implements. Shape-testing first would send a real spec to Rule 2, author a new plan into the same directory, and let Step 8's `Implement now` callback misclassify it again — authoring without converging |
