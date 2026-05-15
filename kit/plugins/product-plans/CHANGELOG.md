# Changelog

## 2.3.0 — 2026-05-15

**Plan improvement is now the primary purpose.** All reviewer agents, role
prompts, skill description, and output template updated to make plan
improvement (not just critique) the explicit goal.

Changes:

- **Skill description** updated — now triggers on "improve", "optimize", or
  "update" a plan, in addition to "cross-functional panel review".
- **Skill Step 2** option renamed from "Review + revised plan" to
  "Review + update plan in place" to reflect the in-place update model.
- **All six reviewer agents** — added a "Your primary goal is plan
  improvement" rule to each agent's Rules section. Every `Recommended
  improvement` must now be a concrete, implementable change.
- **Role prompts** updated — each spawn prompt now says "Review and improve
  the product plan" and includes the improvement mandate so reviewers
  know their output drives direct plan edits.
- **Output template** — section 15 renamed to **15b** (Complete Revised
  Plan) to distinguish it from 15a (Inline Edits). Section 12 notes that
  every item must map to a 15a inline edit or a 15b revision. Header note
  clarifies that sections 12 and 15a drive the improvement mechanism.
- **`agent-product-plans` background agent** — fixed a bug where step 3
  reported `<stem>-revised.md` (a sibling file) as the output; it now
  correctly reports "Plan updated in place: `<path>`" matching the
  in-place edit behavior introduced in 2.2.1.
- **Marketplace description** updated to lead with "Improve, optimize, and
  update" and added `plan-improvement`, `plan-optimization` tags.

## 2.2.1 — 2026-05-15

**Behavior change (Step 7):** The skill now integrates panel findings
directly into the source plan. Both interactive and background modes share
a single path — no prompts, no sibling file. Two passes:

1. **Inline edits** — section 15a of the synthesized report lists discrete
   `(section, action, content)` edits; the lead applies them to the source
   plan via `Edit` in order.
2. **Append panel review** — the full 15-section synthesized report is
   appended as a `## Panel Review` section at the end of the source plan.

This mirrors how `plan-interview` integrates its findings into the plans it
reviews.

**Removed:** the `AskUserQuestion` prompt in Step 7, the **Sibling file**,
**Overwrite original**, and **Append to original** options, the
`git status --porcelain` safety guard, and the background-mode
`<stem>-revised.md` sibling-write.

**Added:** section 15a ("Inline Edits to Apply") in
`references/output-template.md` — a structured table the lead fills with
discrete edits derived from section 12 recommendations.

## 2.2.0 — 2026-05-15

**Additive — no breaking changes.** All existing reviewer behavior is unchanged.

New team member:

- **`product-reviewer-security-expert` agent** — reviews authentication and
  authorization design, data handling and privacy, input validation, dependency
  risk, secrets management, threat modeling, compliance implications, and
  security unknowns.
- **Spawn prompt** added to `references/role-prompts.md`.
- **Output template** updated: Security Expert added to the reviewer roster and
  a new **Section 9 — Security Requirements** inserted; subsequent sections
  renumbered (10–15). The Revised Plan is now section 15.
- **`product-plans` skill** updated: spawn directive now lists six subagent
  types; synthesis and section references updated to match.
- **`agent-product-plans` background agent** description updated to reflect
  six-reviewer panel.

## 2.1.0 — 2026-05-14

**Additive — no breaking changes.** Foreground skill behavior is unchanged.

New surfaces for unattended (background) panel execution:

- **`--background` flag on the `product-plans` skill** — suppresses all
  `AskUserQuestion` calls and uses fixed defaults (see table below). Pass
  any explicit plan path in the same argument string.
- **`agent-product-plans` subagent** — background wrapper agent
  (`background: true`, `tools: Skill, Read, Write, Edit, Glob, Grep, Bash`,
  `maxTurns: 30`). Tool list widened from `Skill, Read` so the inner skill's
  `Write`/`Edit` calls succeed (subagent tool grants are not transitive
  across `Skill` invocations). Invokes the skill via the `Skill` tool.
  Named dispatch target for the command below.
- **`/product-plans:product-plans-bg <path>` command** — one-liner that
  fires `agent-product-plans` with `run_in_background: true` and returns
  an ack immediately.

Background mode defaults:

| Step | Foreground | Background |
|------|------------|------------|
| Plan file resolution | 4-stage fallback (message → IDE → settings → glob) | Explicit path in `$ARGUMENTS` only; stops with `Background mode requires a plan path` if absent |
| Output mode (Step 2) | `AskUserQuestion` (default: review + revised plan) | Hard-coded `review + revised plan` |
| Write destination (Step 7) | `AskUserQuestion` (sibling / overwrite / append) | Hard-coded sibling file (`<stem>-revised.md`), non-destructive |

## 2.0.0 — 2026-05-14

**Breaking change**: plugin and skill renamed from `product-plan-review-panel`
to `product-plans`. Users on v1.0.0 must reinstall:
`/plugin install product-plans@agentics-kit`.

Skill `description` rewritten to use panel/multi-role-specific triggers
(`cross-functional panel review`, `multi-role critique`, role names) so
auto-activation no longer overlaps with `plan-interview` or `code-review`.

## 1.0.0 — 2026-05-14

- Initial release.
- Skill `product-plan-review-panel`: orchestrates a five-reviewer Agent Team (PM, Lead Developer, UX Designer, Frontend Engineer, Accessibility Expert) to produce a consolidated 14-section product-plan review and optional revised plan.
- Subagent definitions (teammate-only): `product-reviewer-pm`, `product-reviewer-lead-developer`, `product-reviewer-ux-designer`, `product-reviewer-frontend-engineer`, `product-reviewer-accessibility-expert`.
