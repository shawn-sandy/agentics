---
status: proposal
type: feature
created: 2026-08-07
repo-name: agentics
---

# Proposal: A teach-artifact skill that publishes a teaching page about a session or a pull request

> **Deprecated.** The authoritative artifact is the saved prompt at
> `docs/prompts/proposal-add-teach-artifact-skill.md`. This copy is written for one deprecation
> release (plan-agent 6.0.0) and is removed in 6.1.0. Edit the prompt, not this
> file.

> This is a proposal for review, not an execution plan. It captures the measured
> surface of `artifact-tools` 1.11.0 and the two explain-flavored skills in
> `social-media-tools`, and proposes adding one skill, `teach-artifact`. The
> load-bearing decisions are resolved (see Locked decisions); execution is handed
> off (see Next step).

## TL;DR

`artifact-tools` 1.11.0 already separates its publishing engine from its framing:
`eng-recap`, `team-recap`, and `product-doc` are 60-68 line command files over a
276-line shared `references/recap-core.md`. Meanwhile nothing in the kit
publishes a *teaching* page — the two skills that teach (`write-guide`,
`share-explanation`) emit Markdown and a PNG, and the four that publish artifacts
all recap or transcribe. Proposal: add one skill, `teach-artifact`, to
`artifact-tools`. It reuses `recap-core`'s existing Session and PR source modes
verbatim (zero new gathering code) and supplies a teaching frame instead of a
recap frame. Roughly one `SKILL.md` plus one framing reference.

## Context

The idea: a skill that produces an artifact whose job is to *teach* — to leave a
reader understanding how something works — rather than to report what changed.
The original phrasing named "a session, a skill, a diff, etc."

What already exists that it touches, measured rather than recalled:

- **`kit/plugins/artifact-tools` at 1.11.0** — four skills (`diff-artifact` 90
  lines, `plan-artifact` 115, `prompt-artifact` 97, `session-artifact` 171),
  three commands (`eng-recap` 68, `product-doc` 60, `team-recap` 67), and eight
  shared references (1,382 lines total across the plugin's Markdown).
- **`references/recap-core.md` (276 lines)** is the engine the three commands
  share. It owns: the two source modes (Session default, PR via
  `#455`/URL/`--pr`), the PR preflight that degrades to session mode when `gh` or
  a GitHub remote is missing, the GraphQL review-thread query, the opt-in
  20-file diff budget, the page-build constraints (mermaid in
  `<pre class="mermaid">`, theme-aware, no emoji as UI, `overflow-x: auto` for
  wide content), the mermaid-SVG inlining procedure, the gallery hand-off to
  `social-media-tools:save-artifact`, and the shared republish record under
  `{plansDirectory}/sessions/`.
- **Each command declares exactly five things** and inherits the rest: audience,
  section list, favicon, inbox stem, and republish key.
- **`social-media-tools:write-guide`** already owns teaching *archetypes*
  (`system-explainer`, `rule-deep-dive`, `how-to`, `concept-explainer`,
  `change-recap`) — but writes Markdown to `<plansDirectory>/guides/`.
- **`social-media-tools:share-explanation`** answers "how does X work" from real
  source — but delivers a social-card PNG through the `share-*` pipeline.

## Core finding

> `artifact-tools` already separates engine from framing — three recap commands
> of 60-68 lines each sit on one 276-line shared reference — so a *teaching
> frame* over the sources it already reads costs almost nothing; and nothing in
> the kit publishes a teaching page as an artifact at all, because the two skills
> that teach output Markdown and a PNG while the four that publish artifacts
> recap or transcribe.

## Side-by-side

| Capability | Accepts | Output | Frame |
|---|---|---|---|
| `session-artifact` | session transcript | claude.ai artifact page | recap: Summary / Decisions / Learnings |
| `/eng-recap`, `/team-recap`, `/product-doc` | session or PR | claude.ai artifact page | recap, three audiences |
| `diff-artifact` | branch, commit range, PR | claude.ai artifact page | annotated review walkthrough |
| `plan-artifact`, `prompt-artifact` | plan HTML, saved prompt | claude.ai artifact page | verbatim republish |
| `social-media-tools:write-guide` | any project topic | Markdown in `guides/` | teaching (5 archetypes) |
| `social-media-tools:share-explanation` | file, component, concept | social-card PNG | short explanation |
| **`teach-artifact` (proposed)** | session, PR | claude.ai artifact page | **teaching** |

The bottom row is the only cell in the Output x Frame grid that is currently
empty.

## Locked and resolved decisions

Settled before this draft:

1. **It lands in the existing `artifact-tools` plugin, not a new one.** The
   publishing pipeline, the scrub gate, the gallery hand-off, and the republish
   record all already live there.

Resolved in the 2026-08-07 review:

2. **Shape: one skill named `teach-artifact`, not a fourth recap command.**
   A command would have been ~65 lines and free, but it inherits only what
   `recap-core` exposes and reads as a variant recap. A skill auto-activates on
   "explain how this works as a page", and can take new sources later without a
   rename. Propagates to: file at
   `kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md`; needs a skill
   `description` within the <=200-char / <=80-char-first-sentence budget; carries
   the plan-mode guard line verbatim, because it writes files and publishes.
3. **Sources in v1: Session and PR only — `recap-core`'s two existing modes,
   reused verbatim.** Zero new gathering code ships. The PR preflight, the
   session-mode fallback, and the review-thread query are all inherited as-is.
   Propagates to: Workstream B; the resolver's extension seam is *documented*,
   not pre-built — a four-mode resolver with two modes stubbed would be
   speculative scaffolding. Note the tension this creates, recorded honestly in
   Risks: in v1 the frame is the *only* thing distinguishing `teach-artifact`
   from the recap trio.
4. **Independent of `write-guide`; the seam is stated rather than shared.**
   No cross-plugin dependency, so `artifact-tools` stays installable alone.
   Propagates to: both plugin READMEs gain a one-line boundary statement —
   `write-guide` produces long-form Markdown you keep in the repo,
   `teach-artifact` produces a shareable page.
5. **Name: `teach-artifact`.** Matches the plugin's `<subject>-artifact` pattern.
   Propagates to: republish key `teach-artifact-url:`, inbox stem
   `teach-artifact` (or `pr-<number>-teach` in PR mode), and a favicon fixed at
   first publish and never changed.

## Workstreams

### A — Teaching frame

The substance of the skill: what a teaching page contains that a recap does not.
A recap answers *what changed*; a teaching page answers *how does this work, and
why is it built this way*. Candidate section spine, to be settled at plan time:
the mental model first, then how it works now, then one path walked end to end,
then why it is built this way, then where to look next. The reviewer test: if a
draft's sections restate `team-recap`'s, the skill has not earned its slot.

### B — Source reuse and the extension seam

Delegate source resolution to `recap-core.md`'s Source section unchanged —
Session default, PR on `#455`/URL/`--pr <n>`, with the documented preflight and
its deliberate session-mode fallback. Add a short, explicit note naming where a
future source (a skill, a rule, a file) would attach, without writing it.

### C — Publishing wiring

Claim `teach-artifact-url:` in the shared republish record and touch no other
key — four writers already share that record per session, and reusing another's
key republishes over its page. Inherit the blocking `security-scrub` gate, the
page-build constraints, the mermaid-SVG inlining, and the
`social-media-tools:save-artifact` hand-off. Pick a favicon and keep it stable.

### D — Marketplace and documentation obligations

A new skill in a plugin is a MINOR bump: `artifact-tools` 1.11.0 -> 1.12.0 in
`.claude-plugin/marketplace.json` only, never in `plugin.json`. Add the
`CHANGELOG.md` entry, a row in the plugin README's Features table, a line in its
Usage block, and the boundary statement from decision 4. Verify with
`BASE_REF=main node scripts/check-plugin-versions.mjs`.

## Risks and tensions

- **Overlap with `team-recap` is the real risk.** A teaching page about a session
  and a team recap of that session can converge on the same document. Mitigation:
  the section spine must be teaching-shaped, not recap-shaped. Stop condition: if
  the first real draft reads as a `team-recap` variant, reconsider shipping it as
  a fourth command instead.
- **In v1 the frame is the only differentiator.** With Session and PR only,
  `teach-artifact` accepts exactly what the recap trio accepts. This is a
  deliberate, recorded consequence of decision 3, not an oversight.
- **Republish-key collision.** `recap-core` is explicit that all writers share
  one record and none may touch another's key. A fifth writer widens that
  surface.
- **Teaching a PR is thinner than teaching a session.** `recap-core` already
  notes a PR carries no record of what was tried and abandoned. A teaching frame
  leans harder on the *why* than a recap does, and the PR is the weaker source
  for it.
- **Description-budget collision.** The skill's trigger sentence must not overlap
  `session-artifact`'s ("share a session recap") or `share-explanation`'s ("how
  does X work") closely enough to misfire.

## Open questions (decisions only)

- **Reuse `recap-core.md` directly, or fork a `teach-core.md`?** Reuse keeps one
  file correct and matches how the recap trio works; a fork is free to diverge as
  sources are added. Recommendation: reuse `recap-core` for source and
  publishing, add a small `teach-framing.md` for the sections only.
- **Fixed teaching sections, or picked per source?** Fixed is simpler and
  testable; per-source acknowledges that teaching a PR and teaching a session
  differ in available material.

## Roadmap

| Phase | Work | Size | Depends on |
|---|---|---|---|
| 1 | Skill shell — `SKILL.md` plus the teaching-frame reference, session mode | S | — |
| 2 | PR mode through `recap-core`'s preflight and fallback | S | 1 |
| 3 | Publishing wiring — republish key, inbox stem, favicon, scrub gate | S | 1 |
| 4 | Marketplace obligations — 1.12.0, CHANGELOG, README rows, description check | S | 1-3 |

## Appendix A — The five declarations, filled in

Every `artifact-tools` recap writer declares exactly these. `teach-artifact`'s
proposed values:

| Declaration | Value |
|---|---|
| Audience | someone who needs to understand the system, not review the change |
| Sections | Workstream A's spine, settled at plan time |
| Favicon | one emoji, fixed at first publish, never changed on redeploy |
| Inbox stem | `teach-artifact`, or `pr-<number>-teach` in PR mode |
| Republish key | `teach-artifact-url:` — and no other key in the shared record |

## Appendix B — Recap frame vs. teaching frame

| Recap asks | Teaching asks |
|---|---|
| What changed? | How does it work? |
| Who decided what, and why? | Why is it built this way rather than the obvious alternative? |
| What files were touched? | What do I read first, and in what order? |
| What is still open? | What will surprise me when I change it? |
| What was tried and abandoned? | What is the mental model I need before any of this parses? |

## Next step

Convert to an execution plan:

`/plan-agent:implementation-plan author an execution plan from the proposal prompt at docs/prompts/proposal-add-teach-artifact-skill.md`
