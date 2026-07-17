# Proposal: Merge plan-interview into plan-agent

- **Status:** decision-complete
- **Tier:** 1 (lightweight — single research pass, internal-only)
- **Created:** 2026-07-17
- **Repo:** agentics

## Context

The marketplace ships two planning plugins: `plan-interview` (v2.2.8, 5 skills /
10 commands / 1 agent / 1 hook) and `plan-agent` (v3.1.1, 9 skills / 1 command /
8 agents / 4 hooks). The user asked whether their overlap justifies merging them
into one plugin. The repo has an established consolidation pattern — six plugins
were previously removed for redundancy (see the Removed Plugins table in
`.claude/rules/marketplace.md` and commit `ebba701`).

## Core finding

> The two plugins already operate as one system split by file format:
> `plan-agent` owns the modern HTML-plan lifecycle end-to-end (create →
> interview → review team → finalize → gallery), while `plan-interview` holds
> the legacy `.md`-plan utilities plus the standalone conversational
> stress-test — and `plan-agent`'s own docs treat `plan-interview` as its
> companion.

Three files in `plan-agent` hand off to `plan-interview` by name
(`README.md` "Optional pairing" section, `skills/finalize-plan/SKILL.md:61`,
`skills/review-plan/SKILL.md:14`). Zero functional references flow the other
way.

## Side-by-side: the four duplication seams

Survivor column reflects locked decision 3 (plan-agent wins every overlap).

| Seam | plan-interview | plan-agent | Survivor |
|---|---|---|---|
| Stress-testing | `plan-interview` + `deep-grill` skills (conversational, multi-round) | Built-in Step 5b interview + 7-reviewer `review-plan` Agent Team | **plan-agent** — drop `plan-interview`; keep `deep-grill` only if node-by-node decision walk is judged additive to the review team (see W1) |
| Status lifecycle | `plan-status`, `update-plan-status` (`.md` plans only) | `finalize-plan` (`.html` plans only) | **plan-agent** — `finalize-plan` is canonical; `plan-status` survives only as legacy `.md` support |
| HTML rendering | `markdown-to-html` skill (general md → HTML) | `render-plan-html.py` + `build-plan-html.mjs` (plan spec → interactive HTML) | **plan-agent** for plans; `markdown-to-html` carries over only as the general-purpose converter (no plan-agent equivalent) |
| Filename hygiene | `plan-hygiene` + `review-rename-plans` commands | `validate-plan-filename.py` PostToolUse hook | **plan-agent** — hook stays; drop both commands |

Unique to `plan-interview` (no counterpart in `plan-agent`): `documenting-plans`
(+ `plan-documenter` agent), `plan-maintenance` (archiving), the general-purpose
`markdown-to-html` converter, and the ExitPlanMode nudge hook.

## Locked decisions

1. **Shape: full merge + prune.** Fold `plan-interview` into `plan-agent`
   v4.0.0 (MAJOR — absorbs a plugin and renames every `/plan-interview:*`
   namespace). Prune duplicates during the move rather than carrying them over
   wholesale. *(Decided 2026-07-17.)*
2. **Retirement: de-register + delete.** Remove the `plan-interview` entry from
   `.claude-plugin/marketplace.json`, delete `kit/plugins/plan-interview/`, and
   add a Removed Plugins row pointing users at `plan-agent` — the same pattern
   as the six prior removals. Source stays recoverable from git history.
   *(Decided 2026-07-17.)*
3. **Overlap tie-breaker: plan-agent wins.** At every seam where both plugins do
   the same job, keep `plan-agent`'s implementation and drop
   `plan-interview`'s — do not port the redundant version. Only `plan-interview`
   capabilities with **no** `plan-agent` counterpart carry over. *(Decided
   2026-07-17.)*

## Workstreams

### W1 — Carry over (only capabilities plan-agent lacks entirely)

Per decision 3, port only what has no `plan-agent` counterpart:

- `documenting-plans` skill + command + `plan-documenter` agent — plan-agent has
  no prose-doc generator.
- `plan-maintenance` command — plan-agent has no archiving.
- `markdown-to-html` skill + command — general md→HTML converter (plan-agent
  renders plan specs only); also the delegate the deprecated `plan-to-html`
  pointed at.
- ExitPlanMode nudge hook → merge into `plan-agent/hooks.json`, updating its
  message to reference the built-in interview.
- **`deep-grill` — carry over only if judged additive.** The node-by-node
  decision walk is a different mode from the review-plan team; keep it if that
  distinction earns its context cost, otherwise drop it under decision 3. Flag
  this one call to the planning layer rather than pre-deciding.

### W2 — Drop the redundant version (plan-agent wins the seam)

- Drop `plan-interview` skill + command — superseded by plan-agent's built-in
  Step 5b interview and `review-plan` team.
- Drop `plan-to-html` (skill + command) — already a deprecated alias.
- Drop `plan-hygiene` + `review-rename-plans` commands — the
  `validate-plan-filename` hook is the surviving hygiene mechanism.
- Status: `finalize-plan` (`.html`) is canonical. Keep `plan-status` **only** as
  legacy `.md` support and fold `update-plan-status` (bulk mode) into it as a
  flag. `finalize-plan`'s existing "not my format" handoff at
  `skills/finalize-plan/SKILL.md:61` repoints to the now-local
  `/plan-agent:plan-status`.

### W3 — Repo touchpoints (measured blast radius)

- `.claude-plugin/marketplace.json` — remove `plan-interview` entry; bump
  `plan-agent` to 4.0.0; extend its description/tags.
- `.claude/rules/marketplace.md` — add Removed Plugins row: merged into
  `plan-agent` 4.0.0.
- `CLAUDE.md` — plugin table drops from 13 to 12 rows; fold the
  `plan-interview` row's content into the `plan-agent` row.
- `kit/plugins/plan-agent/README.md` — replace the "Optional: plan-interview
  pairing" section with the merged skills; `CHANGELOG.md` entry for 4.0.0.
- `kit/plugins/plan-agent/skills/review-plan/SKILL.md:14` — update the
  boundary note to the local skill name.
- `.claude/settings.json` `enabledPlugins` — remove
  `plan-interview@agentics-kit`.
- Tests: `tests/plugins/test-save-pdf.sh`, `tests/publish/smoke-clean-dist.sh`,
  `tests/publish/test-dist-transforms.mjs` reference `plan-interview` — repoint
  to a surviving plugin. `tests/fixtures/merge-marketplace/*.json` use it only
  as sample data — leave unchanged.

## Migration notes for users

- All `/plan-interview:*` invocations become `/plan-agent:*` (same skill
  names). One-line mapping table goes in the 4.0.0 CHANGELOG entry.
- Users with `plan-interview@agentics-kit` enabled should uninstall it and
  ensure `plan-agent@agentics-kit` ≥ 4.0.0.

## Open questions

- **Keep `deep-grill`?** The only genuine judgment call left. It overlaps the
  review-plan team in intent but differs in mode (walks each decision node
  conversationally vs. parallel role reviewers). Decision 3 says drop overlaps;
  the mode difference is the case for keeping it. Left for the planning layer to
  resolve with the skill body in front of it — not a missing fact.

## Trade-off acknowledged

Post-merge `plan-agent` carries ~11–12 skills (9 today + `documenting-plans` +
`markdown-to-html`, ± `deep-grill`), ~4–5 commands, 9 agents. Decision 3 keeps
the growth small by dropping every redundant version rather than porting it. The
cost is accepted in exchange for: one install for the full plan lifecycle, no
format-forked status systems, no cross-plugin handoffs to a plugin that may not
be installed, and one namespace to document.
