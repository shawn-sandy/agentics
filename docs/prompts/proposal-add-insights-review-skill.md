---
type: proposal
intent: Add a skill that reviews a Claude Code /insights report and routes each recommendation to global memory, a path-scoped rule, a project skill, or a repo plugin
techniques: Long-context grounding, XML structure, Comparison tables, Positive framing, Output format
created: 2026-08-14
status: converged
modified: 2026-08-14
generated-sha: b6c7fd22ec3d191a4f6ca9630d9953fb529b68b33e51f03ed7bcc7cdf7419d16
---

# Proposal: Add Insights Review Skill

> This is a proposal for review, not an execution plan. It carries the
> grounded research and the decisions already made; the final instruction
> below hands off to drafting an execution plan from it.

<tldr>
`/insights` writes a structured HTML report to `~/.claude/usage-data/report.html`
with stable section ids and two distinct payload types — it is not free-form
advice. Those two payload types map directly onto memory-shaped and skill-shaped
destinations, so routing is largely a read of report structure rather than
inference over prose. The real engineering problem is idempotency: 3 of the 5
CLAUDE.md suggestions in the 2026-08-14 report are already applied verbatim to
`~/.claude/CLAUDE.md`. Recommendation: add a third skill, `insights-review`, to
the `memory-tools` plugin (v4.1.0 to 4.2.0), routing to four destinations and
delegating writes to its two existing sibling skills, with a runtime gate
choosing apply-directly versus emit-a-plan.
</tldr>

<context>
The user already runs this workflow by hand, and the evidence sits in the repo
and in the home directory:

- Commit `a99b1a7` — "Add three implementation plans from the 2026-08-14 usage
  report" — turned one report into `docs/plans/add-scope-guard-hook.md`,
  `docs/plans/harden-ship-preflight.md`, and
  `docs/plans/replace-grep-drift-check.md`.
- `~/.claude/CLAUDE.md` sections **Verification**, **Formatting & Scope**, and
  **Ship / PR Workflow** are verbatim report suggestions already pasted in.
- `~/.claude/rules/review-bot-loops.md` is report item #3 ("Bot-review triage is
  your single biggest recurring workload") hand-implemented as a path-scoped
  rule file.
- Nine reports exist, 2026-07-16 through 2026-08-14, so this is a recurring
  cadence rather than a one-off.

What already exists that this touches: `memory-tools` v4.1.0 ships
`agentic-memory-management` (owns CLAUDE.md audit and rewrite) and
`path-rules-advisor` (owns `.claude/rules/` creation), with a documented seam —
`path-rules-advisor/SKILL.md` explicitly defers global memory to its sibling.
`plan-agent` v9.3.0 owns `implementation-plan`, the emit-a-plan destination.
</context>

<finding>
The `/insights` report is a structured artifact, not free-form advice: its two
payload types — checkbox-selectable markdown blocks and "Paste into Claude Code"
capability prompts — map directly onto memory-shaped and skill-shaped
destinations, so routing is a read of report structure rather than inference over
prose. The engineering problem is idempotency, because 3 of the 5 CLAUDE.md
suggestions in the current report are already applied verbatim.
</finding>

<comparison>
| Dimension | Proposed skill | Manual workflow today |
|---|---|---|
| Trigger | One invocation naming the report (or defaulting to it) | Open `report.html` in a browser, read all seven sections |
| Recommendation extraction | Parse stable section ids; 5 checkbox blocks + 7 paste-prompts | Read and copy by hand, button by button |
| Already-applied detection | Exact heading plus normalized bullet match, reported and skipped | None — user re-reads and remembers what was done |
| Destination choice | Heuristic classification, confirmed as a batch | Decided ad hoc per item |
| Global memory writes | Delegated to `agentic-memory-management` | Hand-edit `~/.claude/CLAUDE.md` |
| Path-scoped rules | Delegated to `path-rules-advisor` | Hand-author `~/.claude/rules/*.md` |
| Plan output | Delegated to `plan-agent:implementation-plan` | Hand-prompt, as in commit `a99b1a7` |
| Auditability | One summary table per run listing every item and its disposition | Nothing recorded |
</comparison>

<decisions>
Locked and resolved — treat these as settled; do not reopen them:

Settled before this draft:

1. **Input is the Claude Code `/insights` usage report.** Not a generic markdown
   doc, not the claude.ai analytics export, not live transcript analysis. This
   pins the parser to a known artifact.
2. **Routing uses explicit heuristics plus a batch confirm gate.** Classify with
   rules, then confirm the whole classified batch before any write. No per-item
   interrogation, no silent automation.
3. **Both output modes ship; the caller picks at runtime.** Apply directly, or
   emit an implementation plan instead.

Resolved in the 2026-08-14 review:

4. **Home is the `memory-tools` plugin.** Two of the four destinations are
   already its turf and the seam between its two skills is documented, so the new
   skill delegates instead of reimplementing. Propagates to Workstream F:
   `memory-tools` needs a minor version bump to 4.2.0 in
   `.claude-plugin/marketplace.json`, plus README and CHANGELOG entries.
5. **Four destinations, adding path-scoped `.claude/rules/`.** Global
   `CLAUDE.md`, path-scoped rules, project skill, repo plugin.
   `~/.claude/rules/review-bot-loops.md` proves rules files are a destination
   already used by hand. Propagates to Workstream B (four-way routing table) and
   Workstream E (a delegation seam to `path-rules-advisor`).
6. **Already-applied suggestions are reported and skipped.** Detected by exact
   heading plus normalized bullet text, listed in the summary as already applied,
   and excluded from the confirm gate. Propagates to Workstream C and to the
   Workstream D summary table, which must show every item including the skipped
   ones.
7. **Default input is `~/.claude/usage-data/report.html`, overridable by a path
   argument.** Warn when the file's mtime is older than roughly 14 days so a
   stale report is visible rather than silently re-processed. Propagates to
   Workstream A.
</decisions>

<workstreams>
**A — Report parser.** Parse `~/.claude/usage-data/report.html` by its stable
ids: `section-work`, `section-usage`, `section-wins`, `section-friction`,
`section-features`, `section-patterns`, `section-horizon`. The report embeds no
JSON (`application/json` occurrences: 0), so extraction is HTML-structural. Two
extractors: checkbox-selectable markdown blocks under "Suggested CLAUDE.md
Additions", and "Paste into Claude Code" prompt blocks. Accept a path argument;
default to `report.html`; warn on mtime older than roughly 14 days. Fail loudly
naming the missing id when the markup changes, rather than returning an empty
result.

**B — Classifier and routing table.** Four destinations. Markdown blocks carrying
a `## Heading` plus bullets are memory-shaped: global `CLAUDE.md` when the rule
is cross-project, path-scoped `.claude/rules/` when it names a file type or
directory. Paste-prompts describing a repeatable capability are skill-shaped: a
project skill when it is one workflow, a repo plugin when it is several related
skills plus supporting files. Every classification carries a one-line reason
shown at the gate.

**C — Already-applied detector.** For memory-shaped items, match the suggestion's
`## Heading` against existing headings in the target file, then compare
normalized bullet text (whitespace-collapsed, punctuation-insensitive). For
skill-shaped items, match against existing skill names and descriptions. Report
matches as already applied and exclude them from the gate. On the 2026-08-14
report this must classify Verification, Formatting & Scope, and Ship / PR
Workflow as applied, and Numbers in Docs and Git Safety as new.

**D — Confirm gate and the apply-versus-plan fork.** Present one table: every
extracted item, its destination, its reason, and its status (new or already
applied). Then a single `AskUserQuestion` gate offering apply directly, emit a
plan instead, or cancel. Nothing is written before the gate resolves.

**E — Delegation seams.** Never reimplement what a sibling owns. Global
`CLAUDE.md` writes go to `agentic-memory-management`. Path-scoped rule files go
to `path-rules-advisor`. Plan emission goes to `plan-agent:implementation-plan`
with objective text, never a bare path. Skill and plugin scaffolding follows
`.claude/rules/plugin-patterns.md` and `.claude/rules/skill-authoring.md`.

**F — Plugin packaging.** New skill directory
`kit/plugins/memory-tools/skills/insights-review/`. Bump `memory-tools` to 4.2.0
in `.claude-plugin/marketplace.json` only, never in `plugin.json`. Update the
plugin README and CHANGELOG, and the root README plugin table via its canonical
generator. Verify with `BASE_REF=main node scripts/check-plugin-versions.mjs`.
</workstreams>

<risks>
**The report markup is undocumented and can change.** Anthropic ships
`/insights`; nothing guarantees the section ids are stable across Claude Code
releases. Mitigation: pin to ids, assert each expected id is present, and fail
with the missing id named rather than silently producing zero recommendations.

**Writes land outside the repository.** `~/.claude/CLAUDE.md` and
`~/.claude/rules/` are unversioned. Mitigation: write a timestamped backup before
any modification, and never write before the gate resolves.

**Idempotency matching is heuristic.** Normalized bullet comparison can produce a
false "already applied" and silently drop a genuinely new rule. Mitigation: match
on heading first and require bullet overlap above a stated threshold; show
matched items in the summary so a false positive is visible rather than
invisible.

**Scope creep into full plugin generation.** The plugin destination is the
largest of the four and could swallow the skill. Mitigation: for plugin-shaped
items, scaffold the directory and manifest and stop, then hand off; do not
attempt to author every skill in the new plugin.

**The CI version guard fails the PR if the bump is missed.** Any edit under
`kit/plugins/memory-tools/` requires the `marketplace.json` bump in the same PR.
</risks>

<open-questions>
Decisions still owned by the human — surface them, do not answer them:

- Should apply-directly write a timestamped backup of `~/.claude/CLAUDE.md`
  before modifying it? The file is unversioned and hand-tuned, and a backup costs
  one copy — but it also accumulates untracked files in the home directory.
- Skill name: `insights-review` or `review-insights`? The former matches the
  noun-first pattern of its siblings `path-rules-advisor` and
  `agentic-memory-management`.
</open-questions>

<roadmap>
| Phase | Work | Size | Depends on |
|---|---|---|---|
| 1 | Workstream A — parser with id assertions, against all 9 local reports | M | — |
| 2 | Workstream C — already-applied detector, validated on the 3-of-5 case | M | 1 |
| 3 | Workstream B — four-way classifier and routing table | M | 1 |
| 4 | Workstream D — summary table and the apply-versus-plan gate | S | 2, 3 |
| 5 | Workstream E — delegation seams to the three owning skills | M | 4 |
| 6 | Workstream F — packaging, version bump, README, CHANGELOG, tests | S | 5 |
</roadmap>

<appendices>
Appendix A — Measured report structure

Source: `~/.claude/usage-data/report-2026-08-14-071004.html`, 75,440 bytes.

| Property | Measured value |
|---|---|
| Section ids | `section-work`, `section-usage`, `section-wins`, `section-friction`, `section-features`, `section-patterns`, `section-horizon` |
| H2 headings | What You Work On; How You Use Claude Code; Impressive Things You Did; Where Things Go Wrong; Existing CC Features to Try; New Ways to Use Claude Code; On the Horizon |
| Embedded JSON | none — 0 occurrences of `application/json` |
| Checkbox inputs | 5 (Suggested CLAUDE.md Additions, with "Copy All Checked") |
| "Paste into Claude Code" blocks | 7 |
| Copy buttons | 15 |
| Archive | 9 reports, `report-YYYY-MM-DD-HHMMSS.html`, 2026-07-16 to 2026-08-14, plus canonical `report.html` |

Appendix B — Routing table

| Report payload | Shape test | Destination | Owning skill |
|---|---|---|---|
| Suggested CLAUDE.md Addition, cross-project rule | `## Heading` + bullets, no path or filetype named | `~/.claude/CLAUDE.md` | `agentic-memory-management` |
| Suggested CLAUDE.md Addition, scoped rule | names a directory, glob, or file type | `.claude/rules/<name>.md` | `path-rules-advisor` |
| Paste-prompt, single repeatable workflow | one trigger, one procedure | project skill under `skills/` | this skill, per `skill-authoring.md` |
| Paste-prompt, several related capabilities | multiple triggers sharing supporting files | repo plugin under `kit/plugins/` | this skill, per `plugin-patterns.md` |
| Any of the above, plan mode selected | user chose emit-a-plan at the gate | `docs/plans/<verb-target>.md` | `plan-agent:implementation-plan` |

Appendix C — Already-applied measurement (2026-08-14 report)

| Suggested section | Present in `~/.claude/CLAUDE.md` |
|---|---|
| Verification | yes |
| Formatting & Scope | yes |
| Ship / PR Workflow | yes |
| Numbers in Docs | no |
| Git Safety | no |

Three of five already applied. This is the regression case the detector in
Workstream C must reproduce.
</appendices>

Author an execution plan that delivers Workstreams A through F in roadmap order.
Draft real, actionable steps naming the files each one touches — do not restate
the workstream headings above as steps. Treat the locked decisions as settled
inputs, and carry the two open questions into the plan's unresolved-questions
section rather than answering them. The parser, the already-applied detector, and
the routing classifier each need real tests: Appendix C is the regression case
the detector must reproduce, and the nine local reports under
`~/.claude/usage-data/` are the corpus the parser must survive.
