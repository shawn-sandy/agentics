# Invocation and arguments

Loaded before Step 1. Covers command versus model activation, flag parsing,
and the argument precedence ladder.

Implements a plan and runs it to done — walks the steps, ticks the spec,
re-renders, and runs the completion gates. Given a plan, that is all it does.
Run as `/plan-agent:build` with no plan named, the command form first enters the
authoring chain in Step 1b — proposal, plan, review — and implements what comes
back. Ambient activation keeps the narrower contract: it requires a plan that
already exists and routes elsewhere when there is none.

## Invocation

- **Command:** `/plan-agent:build [<plan path>] [<objective>] [--type <kind>]
  [--dir <path>] [--continue]` — `$ARGUMENTS` carries an optional plan path (`.md` spec or
  `.html`; an `.html` resolves to its sibling `.md`), an optional free-text
  objective, an optional plan type, and an optional plans-directory override.
- **The Step 1b chain is reachable only from the slash command.** The objective
  is a command parameter read from `$ARGUMENTS`. `/plan-agent:build a todo app`
  enters the chain; the same words typed as plain text do not.
- **Model invocation:** activates on "implement the plan at …", "build the plan
  in <file>". Requires a plan that **already exists** — if there is no plan
  file, stop and route to `/plan-agent:implementation-plan <objective>` rather
  than authoring one here. **This is the model path's contract and it is
  unchanged:** `$ARGUMENTS` is empty here, so there is no objective to chain on
  and Step 1b is never entered.

## Argument precedence

Classification runs in this order and **stops at the first rule that matches**.
No rule falls through to the next on failure: a fall-through is what turns a
mistyped filename into a whole authored plan.

### Rule 0 — Strip flags first

Remove `--dir <path>`, `--type <kind>`, `--continue`, and any other recognized
option **together with its value** from `$ARGUMENTS`. What survives is the
**rest string**. Every rule below reads the rest string, never raw
`$ARGUMENTS`.

`--dir tmp/plans` alone therefore leaves an **empty** rest string — that is a
bare `build` that takes Rule 3, not an objective named `--dir` and not a halt.

**A value-taking flag with no value is an error**, named as such. This covers
`--dir` and `--type` alike, and both failure shapes: nothing after the flag, or
another recognized flag after it (`--dir --continue` must not consume
`--continue` as a directory). `--dir` with no value is "`--dir` requires a
path"; `--type` with no value is "`--type` requires one of feature, fix,
refactor, docs, chore" — never a silent drop and never a token left in the rest
string. `--type` with an *invalid* value errors the same way (below). It exists because the
alternatives are both live bugs: dropping the flag silently resolves the
default plans directory while the user believes they overrode it, and leaving
`--dir` in the rest string hands Rule 2 a one-token objective that authors an
entire plan named after a flag.

- **`--type <kind>`** — one of `feature`, `fix`, `refactor`, `docs`, `chore`;
  anything else is an error naming the valid set, never a silent fallback.
  Forwarded to `implementation-plan` on both Step 1b paths so the authored plan
  states its type instead of having it inferred from a leading verb. Repeated
  occurrences resolve **last-wins**, which is what lets the `fix` and `refactor`
  commands **prepend** a default that a user-supplied `--type` overrides.
  Prepend, not append: under last-wins the surviving value is the final one, so
  a default placed after `$ARGUMENTS` would beat the user's explicit flag
  instead of yielding to it.
  **It applies only when a plan is being authored.** With a plan path resolved
  at Step 1, that plan already carries its own `type:` — ignore the flag and say
  so in one line rather than rewriting frontmatter the user did not ask you to
  touch.
- **`--continue`** — a valueless flag that suppresses the phase checkpoint
  offer in Step 2, so a phased plan runs end to end in one session. Ignored by
  a plan that declares no `### Phase:` headings, which never stops anyway.

### Rule 1 — Path (the rest string names a plan file)

The rest string is a plan path when **either** test passes, in this order:

1. **It names an existing file.** Test the complete rest string against the
   filesystem **first, before any shape test**. The filesystem is ground truth:
   if the string is a file, it is a path, whatever it looks like.
2. **It is a single whitespace-free token** carrying an `.md`/`.html` suffix or
   a `/`.

The shape test in (2) is what corrects the original bug: suffix-or-slash was
applied to the *first token* (`A/B` out of `A/B testing for checkout`) instead
of to the whole string. A path is one filesystem name, so **any whitespace in
the rest string disqualifies it** under (2) and sends it to Rule 2.

**But whitespace only disqualifies a string that does not exist on disk** —
which is why (1) runs first and is not merely an optimization. A plans
directory containing a space (`--dir "my plans"`, or a `plansDirectory` setting
with one) produces real spec paths like `my plans/add-foo.md`. Shape-testing
those reads them as prose and sends an existing plan to Rule 2, which authors a
*new* plan — into the same whitespace-bearing directory. `implementation-plan`
Step 8's `Implement now` callback then re-enters this skill with that path, it
misclassifies again, and the chain authors plans without converging. Test (1)
closes that loop: `A/B testing for checkout` is not a file and still reaches
Rule 2, while `my plans/add-foo.md` resolves as what it is.

Resolve it, in order:

1. Use it **as given** if that file exists — absolute paths and
   `--dir tmp/plans` plans both resolve here.
2. Otherwise retry its basename under the resolved plans directory.
3. Still nothing → **stop.** Name both paths tried. Do not fall through to
   discovery and implement a different plan, and **do not enter Step 1b**:
   chaining on a mistyped filename would author a whole plan because of a typo.

An `.html` argument resolves to its sibling `<stem>.md`. No sibling spec
(legacy HTML-only plan) → stop and say so; this skill edits specs, not HTML.
**Do not enter Step 1b**: a plan exists and needs its spec reconstructed, not a
new plan authored on top of it.

**Misparse note.** A single-token slash-bearing objective — `A/B`, `CI/CD`,
`i18n/l10n` — still classifies as a path, because nothing distinguishes it from
a relative filename. When that stop fires on a token with no `.md`/`.html`
suffix, say so: "read `A/B` as a plan path; add a `.md` suffix if you meant a
file, or reword it if you meant an objective." Never a bare list of paths
tried, which leaves the user with no idea their objective was read as a
filename.

### Rule 2 — Objective (anything else non-empty)

Everything the path test rejects is a free-text objective, and **the whole rest
string is the objective** — never its first token, never a prefix.
`A/B testing for checkout`, `add dark mode`, and
`migrate src/api to fetch` are all objectives. Go to Step 1b and author a plan.

### Rule 3 — Empty rest string (discovery)

Glob the resolved plans directory for `.md` specs whose frontmatter `status:`
is `todo` or `in-progress`, newest `created:` first (missing or tied
`created:` → fall back to file mtime). **Never descend into `archive/`.**

| Matches | Action |
|---------|--------|
| **exactly one** | **Auto-select it.** Echo the path and why it was chosen. One candidate carries no ambiguity to resolve, and refusing to adopt it is what made `--dir tmp/plans` halt on a directory holding exactly the plan the user meant. |
| **more than one** | List them via `AskUserQuestion` — **at most the top three** plus `None of these — author a new plan`, stating how many were suppressed (`AskUserQuestion` caps at four options, so an unbounded offer cannot render at all). `None of these` → Step 1b. |
| **zero** | Ask for an objective via `AskUserQuestion`, then Step 1b. |
