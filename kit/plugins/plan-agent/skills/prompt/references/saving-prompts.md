# Phase 7 — directory resolution and filename derivation

Both are skipped entirely when `$ARGUMENTS` carries `--out <path>`. That rule,
and the living-document contract for the `proposal` type, stay in the skill core
where they are always loaded; only the path mechanics live here.

## Resolve the output directory

First match wins.

1. Read `promptsDirectory` using Claude Code's settings precedence —
   project-local `.claude/settings.local.json`, then project
   `.claude/settings.json`, then global `~/.claude/settings.json`. If the key is
   present and non-empty, strip any trailing slash and use that path.
2. Otherwise anchor to the repo root: run `git rev-parse --show-toplevel` and
   join the result with `docs/prompts` (e.g.
   `$(git rev-parse --show-toplevel)/docs/prompts`). If `git rev-parse` fails —
   not a git repo — fall back to `docs/prompts` relative to `$PWD`.

All three readers of this key — this skill, `plan-agent:build-proposal`, and
`artifact-tools:prompt-artifact` — must walk the same three files in the same
order. Diverging does not error; it makes a prompt saved here invisible to the
gallery that publishes it.

Create the directory if it does not exist:

```bash
mkdir -p "<resolved-directory>"
```

## Derive the filename

Three parts joined with hyphens, all lowercase kebab-case:

1. The classified prompt type from Phase 1 (`task`, `system`, `creative`,
   `analytical`)
2. A 3–5 word slug from the user's core intent — strip stop words, replace
   spaces with hyphens
3. Today's date as `YYYY-MM-DD`

Pattern: `{type}-{intent-slug}-{YYYY-MM-DD}.md`

- `task-refactor-auth-middleware-2026-06-04.md`
- `system-customer-support-bot-2026-06-04.md`
- `analytical-compare-pricing-models-2026-06-04.md`

The `proposal` type is the exception and omits the date — see the core for that
rule and the in-place rewrite it goes with.
