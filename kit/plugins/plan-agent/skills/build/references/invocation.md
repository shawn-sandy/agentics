# Invocation and arguments

Loaded before Step 1. Covers command versus model activation, flag parsing,
and the objective-versus-path grammar.

Implements a plan and runs it to done — walks the steps, ticks the spec,
re-renders, and runs the completion gates. Given a plan, that is all it does.
Run as `/plan-agent:build` with no plan named, the command form first enters the
authoring chain in Step 1b — proposal, plan, review — and implements what comes
back. Ambient activation keeps the narrower contract: it requires a plan that
already exists and routes elsewhere when there is none.

## Invocation & Arguments

- **Command:** `/plan-agent:build [<plan path>] [<objective>] [--type <kind>]
  [--dir <path>]` — `$ARGUMENTS` carries an optional plan path (`.md` spec or
  `.html`; an `.html` resolves to its sibling `.md`), an optional free-text
  objective, an optional plan type, and an optional plans-directory override.
- **Parse flags first.** Strip `--dir <path>`, `--type <kind>`, and any other
  recognized option
  with its value out of `$ARGUMENTS` before classifying anything. The test below
  applies to the **first positional token**, never to a flag: `--dir tmp/plans`
  alone leaves no positional token at all, which is a bare `build` and takes the
  discovery offer, not an objective named `--dir`.
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
- **Objective versus path.** The test applies to that **first positional token
  only**: it is an objective unless that token carries an `.md`/`.html` suffix
  or a `/`.
  Anything path-shaped hits the Step 1 stop rather than being read as prose. A
  slash later in the string is harmless — `add A/B testing support` leads with
  `add` and parses as an objective — but a slash in the *first* token misreads
  the whole objective as a path (`A/B testing for checkout`), so that stop
  message must name the misparse: "read `A/B testing for checkout` as a plan
  path; reword it if you meant an objective". Never a bare list of paths tried,
  which would leave the user with no idea their objective was read as a
  filename.
- **The Step 1b chain is reachable only from the slash command.** The objective
  is a command parameter read from `$ARGUMENTS`. `/plan-agent:build a todo app`
  enters the chain; the same words typed as plain text do not.
- **Model invocation:** activates on "implement the plan at …", "build the plan
  in <file>". Requires a plan that **already exists** — if there is no plan
  file, stop and route to `/plan-agent:implementation-plan <objective>` rather
  than authoring one here. **This is the model path's contract and it is
  unchanged:** `$ARGUMENTS` is empty here, so there is no objective to chain on
  and Step 1b is never entered.
