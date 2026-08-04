# The no-plan chain

Loaded only when Step 1's no-path branch routes here. Covers Step 1b in full.

## Step 1b — Author a plan first (the no-plan chain)

Reached only from Step 1's no-path branch, and only via the slash command. Every
stage is delegated to the skill that already owns it — nothing here re-implements
proposal writing, plan authoring, or review. Control returns through
`implementation-plan`'s Step 8 menu.

1. **Objective check — first, before anything else.** No objective was supplied
   (the bare-`build` path, including arriving here through
   `None of these — author a new plan`) → ask for one with `AskUserQuestion`.
   Both the gate below and the delegated skills are meaningless with an empty
   objective, so never invoke one without it.
2. **Proposal-versus-direct gate**, asked on **every** chained entry via
   `AskUserQuestion` ("No plan specified. How do you want to author one?"):
   - `Start with a proposal` — settle should-we and what first.
   - `Straight to plan authoring` — go directly to `implementation-plan`.
   This is a question rather than a default because `build-proposal` triages a
   Tier 0 idea by answering it directly and producing no document, which would
   leave the chain holding nothing to plan from.
3. **Proposal path.** Invoke
   `Skill(skill: "plan-agent:build-proposal", args: "<objective>")`. Do **not**
   forward `--dir` — that skill resolves its own prompts directory, and since
   plan-agent 6.0.0 its `--dir` names where the *prompt* goes, not the plan.
   It converges on a **saved proposal prompt** at
   `<prompts-dir>/proposal-<slug>.md`; that path, the one it reports, is what
   chains onward. Invoke `Skill(skill: "plan-agent:implementation-plan", args:
   "<objective> --from-prompt <prompt path> --dir <path> --type <kind>")`
   — **`--dir` is forwarded here**, unlike to `build-proposal`: it names where
   the *plan* goes, so omitting it would write the spec to the default directory
   and then fail to resolve it on return. `--type` is forwarded when it was
   given.
   **Pass the prompt path behind `--from-prompt`, never as a bare positional
   token.** `implementation-plan` scans positional arguments for a `.md` suffix
   and treats the first hit as a conversion source — the prompt would be
   restructured into a plan whose steps restate proposal headings instead of
   naming real actions. A flag value is not a positional token, so the
   ambiguity cannot arise. Lead with the original objective text: it is what
   the plan is actually about, and it is what type inference reads when no
   `--type` was given.
   **No proposal written → fall through to the direct path.** `build-proposal`
   triages a Tier 0 idea by answering it directly and writing no artifact of
   either kind, so there is nothing to plan from. Say so in one line and continue
   at step 4 with the original objective; never call `implementation-plan` with
   an empty or guessed path.
4. **Direct path.** Invoke
   `Skill(skill: "plan-agent:implementation-plan", args: "<objective>")`,
   forwarding `--dir <path>` and `--type <kind>` when they were given.
5. **Return path.** Re-resolve the produced spec **by path** — the one
   `implementation-plan` reports — never by re-running discovery, which would
   ask the user about the plan they just watched being authored. Then:
   - `Implement now` → **stop and report.** `Skill()` is synchronous, so by the
     time control reaches here Step 8 has already invoked this skill with the
     spec path and that nested run has reached its own terminal state — through
     the gates, or via `Mark in-progress and stop` at its Step 4.4. Report that
     outcome and the plan's path. Do **not** re-enter Steps 1-2: the
     completed-plan precondition would ask whether to redo work that just
     finished, and resume-from-first-unmarked would restart a run the user
     deliberately stopped. The nested build's result **is** this chain's result.
   - `Exit — I'll implement later` → **stop.** Report the produced plan's path,
     leave it at `status: todo`, and write no source files. Step 8 is the only
     point at which the user is asked how to execute, so this answer declines
     the work itself, not merely the inner skill's offer.
   - `Run as workflow` → **stop.** `implementation-plan` has already emitted the
     workflow prompt and set `status: in-progress`; report the plan's path and
     do not start an in-session build racing the workflow the user launched.
6. **Abandonment contract.** If the chain is abandoned between stages — a tool
   error, a session drop, or the user backing out after the proposal stage has
   written but before a plan exists — leave **both** artifacts in place
   uncommitted, the saved prompt and the legacy copy, and report the prompt's
   path. Never clean either one up.
