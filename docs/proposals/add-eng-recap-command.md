---
title: Add an engineering-audience recap command to artifact-tools
status: decision-complete
tier: 1
created: 2026-07-27
repo-name: agentics
---

# Add an engineering-audience recap command to artifact-tools

## Context

`artifact-tools` ships two recap commands, both thin framing overrides on one
`session-artifact` pipeline:

| Command | Audience | Length | Distinguishing feature |
|---|---|---|---|
| `/artifact-tools:product-doc` | Product team, non-engineering stakeholders | 153 lines | Features / Bug fixes / Implementation-plan details |
| `/artifact-tools:team-recap` | Whole team, mixed in one document | 238 lines | Stat strip, mermaid diagrams, before/after table, glossary |

Neither is written for the engineer who has to touch the code next. The request
is a third sibling with that focus.

## Core finding

> The gap is not audience coverage — it is that both existing commands pay a
> **translate-for-non-engineers tax**, and that tax is exactly what crowds out
> the detail an engineer needs.

`team-recap` mandates the tax explicitly: *"Lead every section with the
plain-language statement, then the technical detail. Never the reverse"* and
*"Spell out every internal name, acronym, or repo-specific term the first time
it appears."* Those rules are correct for its audience and wrong for an
engineering one. An engineering recap is the same pipeline with that constraint
**inverted** — assume the vocabulary, lead with the technical fact, and spend
the reclaimed space on code paths, invariants, rejected tradeoffs, and test
coverage.

This is why the answer is a third command rather than a flag on `team-recap`: a
flag would have to suppress that command's central authoring rule, which is most
of what makes it that command.

## Side-by-side

What each command does with the same session:

| Dimension | `product-doc` | `team-recap` | `eng-recap` (proposed) |
|---|---|---|---|
| Opening move | What a user can now do | Plain-language statement first | The technical fact first |
| Jargon | Spelled out | Spelled out + glossary | Assumed |
| Diagrams | None | Mermaid, SVG-inlined | Mermaid, SVG-inlined |
| PR raw material | Commit bodies + file names | Commit bodies + file names | **+ diff hunks** |
| Code in body | Only what a non-coder needs | Only when clearest | Freely — signatures, configs, invariants |
| Unique sections | Features, Bug fixes, Plan details | Before/after, Glossary | Architecture, Tradeoffs, Learnings, Tests, Follow-ups (stat strip shared with `team-recap`) |

## Established facts

Researched, not assumed:

1. **All recap writers share one per-session record** under
   `{plansDirectory}/sessions/`, distinguished only by a frontmatter republish
   key: `artifact-url:` (skill), `product-artifact-url:`, `team-artifact-url:`.
   A fourth writer reusing a sibling's key republishes over that sibling's page.
2. **`tests/plugins/test-artifact-tools.sh` check 7 enforces key distinctness**
   via a hardcoded `owners` map (lines 193–197). A new command is invisible to
   that check until it is added to the map.
3. **Check 8 asserts `found >= 2`** PR-mode commands (line 243). A third command
   passes the assertion, but its failure message names only `product-doc` and
   `team-recap` and goes stale.
4. **Check 2 validates skill frontmatter only** — commands are not frontmatter-
   validated, so a malformed command file ships silently.
5. **No `package.json`.** Tests are standalone executables under `tests/`;
   `test-artifact-tools.sh` is run directly.
6. **Version:** `artifact-tools` is at `1.6.0` in `marketplace.json`, with no
   `version` key in `plugin.json`. A new command is a MINOR bump → `1.7.0`.
7. **README carries each command twice** — once in the Commands table (line 33)
   and once as a `### <name> (command)` Components subsection.
8. **Destination pattern:** hand the rendered HTML to
   `social-media-tools:save-artifact` with a stem; session mode uses the command
   name, PR mode uses `pr-<number>-<suffix>`.

## Locked decisions

| # | Decision | Rationale | Rejected |
|---|---|---|---|
| 1 | Ship as a **new command**, `/artifact-tools:eng-recap` | A flag on `team-recap` would have to suppress that command's central authoring rule | `--eng` flag on `team-recap`; deferring the choice to the plan interview |
| 2 | Republish key `eng-artifact-url:` | Fourth distinct key on the shared record; anything else republishes over a sibling | Reusing `team-artifact-url:` |
| 3 | **Inherit the mermaid pipeline**, SVG-inlining included | Engineers benefit most from sequence/flow/state diagrams, and the procedure is already written and proven in `team-recap` | Prose/tables only; mermaid without SVG inlining (loses diagrams in the committed gallery copy) |
| 4 | **Read diff hunks** in PR mode, with a size cap | An engineering audience is the one case where hunks carry real signal — changed signatures, new invariants, error paths. Commit bodies still lead for the *why* | Matching siblings exactly; delegating hunk detail to `diff-artifact` |
| 5 | Eight sections: At a glance (stat strip), Architecture & code paths, Decisions, Tradeoffs & rejected options, Learnings, Tests & verification, Review follow-ups & tech debt, Files touched | All four offered sections were selected, then Learnings and the At-a-glance strip were added during plan alignment: a tradeoff is a decision that was weighed, a learning is a dead end that was walked, and dropping the latter loses the dead ends | Any narrower subset; folding Learnings into Tradeoffs |

### Consequence of decision 3

`eng-recap` lands at roughly `team-recap`'s size (~240 lines), not
`product-doc`'s (~153), and inherits the browser-pane dependency along with its
documented fallback (file the rendered HTML with diagram blocks as text, and say
so).

### Consequence of decision 4

The diff read is the one place `eng-recap` departs from both siblings, so it
needs its own guardrail. `gh pr diff` on a large PR can exceed the context the
recap itself needs — the same failure `session-artifact` avoids by refusing to
read the JSONL directly. A cap-and-summarize policy is required, mirroring the
one `diff-artifact` already documents for the 16 MiB artifact limit.

## Workstreams

1. **The command file** — `kit/plugins/artifact-tools/commands/eng-recap.md`.
   Framing overrides only: source (session + PR with diff), audience (inverted
   tax), sections (the eight), visual requirements (inherited), destination
   (stem `eng-recap` / `pr-<n>-eng`), republish key (`eng-artifact-url:`).
2. **Test coverage** — extend `tests/plugins/test-artifact-tools.sh`: add
   `commands/eng-recap.md` → `eng-artifact-url` to the check-7 `owners` map,
   raise check 8's `found >= 2` to `>= 3` with a corrected message, and add a
   check asserting the diff-size cap is documented.
3. **Registration and docs** — `marketplace.json` `1.6.0` → `1.7.0` and its
   `description`; `CHANGELOG.md` `[1.7.0]` entry; README Commands table row and
   `### eng-recap (command)` subsection; root `CLAUDE.md` plugin-table row.

## Open questions

None. The remaining unknowns are implementation detail (exact section wording,
the diff cap threshold), which belong to the execution plan.

## Handoff

Decision-complete. To turn this into an execution plan:

```
/plan-agent:implementation-plan author an execution plan from the proposal at docs/proposals/add-eng-recap-command.md
```
