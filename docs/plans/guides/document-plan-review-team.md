# The Plan Review Team

A developer guide to `agent-review-plan` and the seven-reviewer Agent Team it dispatches — what each reviewer judges, how the five-or-seven fan-out is decided, and how findings get applied back to the plan in place.

> **Origin.** Written from a read of the `plan-agent` plugin (v2.8.4) in the `agentics` marketplace repo. The trigger was a request to document `kit/plugins/plan-agent/agents/agent-review-plan.md` and *every* agent in the review process. That file turned out to be a thin background wrapper around the real machinery in `review-plan/SKILL.md`, so this guide covers both: the dispatcher and the team it orchestrates.

---

## Table of contents

1. [The thesis in one sentence](#1-the-thesis-in-one-sentence)
2. [What it is — the files](#2-what-it-is--the-files)
3. [Why it exists](#3-why-it-exists)
4. [How it works structurally](#4-how-it-works-structurally)
5. [How it fires — dispatch and the UI gate](#5-how-it-fires--dispatch-and-the-ui-gate)
6. [Decision criteria — five reviewers or seven?](#6-decision-criteria--five-reviewers-or-seven)
7. [The seven reviewers — mandate by mandate](#7-the-seven-reviewers--mandate-by-mandate)
8. [Boundaries — what the team does NOT do](#8-boundaries--what-the-team-does-not-do)
9. [Interactions with related systems](#9-interactions-with-related-systems)
10. [Project-specific context](#10-project-specific-context)
11. [Maintenance and audit](#11-maintenance-and-audit)
12. [Verification protocol](#12-verification-protocol)

---

## 1. The thesis in one sentence

**`agent-review-plan` is a fire-and-forget background subagent that runs the same seven-reviewer plan-review team as the interactive `review-plan` skill — five core reviewers always, two UI reviewers conditionally — and applies the synthesized improvements directly to the plan file.**

Everything below unpacks that sentence.

## 2. What it is — the files

The review process is not one agent. It is a dispatcher, an orchestrating skill, and seven reviewer agents — nine files in all, plus two reference templates.

The dispatcher — [`kit/plugins/plan-agent/agents/agent-review-plan.md`](../../../kit/plugins/plan-agent/agents/agent-review-plan.md) — declares itself as a background subagent in its frontmatter, quoted verbatim:

```yaml
name: agent-review-plan
description: >
  Background plan-review agent. Runs the seven-reviewer Agent Team
  (architecture, completeness, testability, risk, conventions + conditional UX
  and accessibility) on an implementation plan without blocking the parent
  session. Improves and updates the plan in place. ...
tools: Skill, Read, Write, Edit, Glob, Grep, Bash
model: sonnet
maxTurns: 30
background: true
```

Its entire job is three steps: confirm the plan path exists, then call the skill —

```text
Skill(skill: "plan-agent:review-plan", args: "<path> --background")
```

— then report `Plan review complete. Plan updated in place: <path>` and stop. It performs no analysis of its own.

The orchestrator — [`kit/plugins/plan-agent/skills/review-plan/SKILL.md`](../../../kit/plugins/plan-agent/skills/review-plan/SKILL.md) — is where the real work lives. Its own description states the purpose: "Plan review Agent Team. Reviews HTML implementation plans in parallel, synthesizes findings, and applies improvements in place."

The seven reviewers, each its own agent file in `kit/plugins/plan-agent/agents/`:

| Reviewer | File | Always runs? |
| --- | --- | --- |
| Architecture | [`plan-reviewer-architecture.md`](../../../kit/plugins/plan-agent/agents/plan-reviewer-architecture.md) | Yes |
| Completeness | [`plan-reviewer-completeness.md`](../../../kit/plugins/plan-agent/agents/plan-reviewer-completeness.md) | Yes |
| Testability | [`plan-reviewer-testability.md`](../../../kit/plugins/plan-agent/agents/plan-reviewer-testability.md) | Yes |
| Risk | [`plan-reviewer-risk.md`](../../../kit/plugins/plan-agent/agents/plan-reviewer-risk.md) | Yes |
| Conventions | [`plan-reviewer-conventions.md`](../../../kit/plugins/plan-agent/agents/plan-reviewer-conventions.md) | Yes |
| UX | [`plan-reviewer-ux.md`](../../../kit/plugins/plan-agent/agents/plan-reviewer-ux.md) | Only on UI signals |
| Accessibility | [`plan-reviewer-accessibility.md`](../../../kit/plugins/plan-agent/agents/plan-reviewer-accessibility.md) | Only on UI signals |

Every reviewer shares the same frontmatter shape — `allowed-tools: Read, Glob, Grep, Bash` and `model: sonnet` — and is read-only against the codebase; none can write. Only the lead (the skill) edits the plan.

Two reference templates drive synthesis: [`references/role-prompts.md`](../../../kit/plugins/plan-agent/skills/review-plan/references/role-prompts.md) (the spawn brief for each reviewer) and [`references/output-template.md`](../../../kit/plugins/plan-agent/skills/review-plan/skills/review-plan/references/output-template.md) (the synthesis structure).

## 3. Why it exists

A single reviewer reading a plan top-to-bottom tends to flatten concerns: it notices the loudest problem and moves on. The team exists to force *parallel, orthogonal* scrutiny — seven lenses that do not share a context window, so a risk concern can't be crowded out by a naming nit and vice versa.

The `agent-review-plan` wrapper exists for a second reason: latency. A full seven-reviewer pass is slow, and blocking the parent session on it is a poor trade when the author wants to keep working. The wrapper's own caveat states the bargain plainly:

> This is a fire-and-forget dispatch. Edits the user makes to the plan file after dispatch may or may not be reflected in the review findings, depending on timing.

So there are two entry points to the same team: the interactive `review-plan` skill (blocks, can ask questions, can walk findings one by one) and the `agent-review-plan` subagent (non-blocking, no prompts, always applies edits).

## 4. How it works structurally

The dispatcher delegates to the skill; the skill runs an eight-step workflow. The fan-out happens at Step 4.

```text
agent-review-plan (background subagent)
  └─ Skill("plan-agent:review-plan", "<path> --background")
       └─ review-plan SKILL.md
            Step 0  Exit plan mode (if in it) + create todos
            Step 1  Resolve the plan file
            Step 2  Choose output mode  ── bg: forced "update in place"
            Step 3  Verify Agent Teams available (≥ 2.1.32 + flag)
            Step 3b Scan plan HTML for UI signals
            Step 4  Spawn the team ──────────────┐
            Step 5  Wait / collect / respawn      │  5 core agents
            Step 6  Synthesize (output-template)  │  + 2 UI agents
            Step 6b Walkthrough triage ── bg: SKIPPED   if signals
            Step 7  Apply edits + append Team Review
            Step 8  Clean up the team
```

The fan-out at Step 4:

```text
            ┌─ plan-reviewer-architecture ┐
   always ──┼─ plan-reviewer-completeness ┤
            ├─ plan-reviewer-testability  ┼─→ each reads plan spec,
            ├─ plan-reviewer-risk         ┤   reports via SendMessage
            └─ plan-reviewer-conventions  ┘
            ┌─ plan-reviewer-ux           ┐  spawned only when
 if UI  ────┤                             ┼─ ui_signals_present
            └─ plan-reviewer-accessibility┘
```

**The lead-vs-reviewer read split** is the load-bearing performance trick. Reviewers do *not* read the full styled HTML plan. Their briefs run an extractor that derives a compact spec — objective, context, files, steps with why/verify, tests, acceptance criteria, verification — from the visible DOM, in a few thousand tokens. The lead (the skill) still reads the full HTML, because Step 3b's keyword scan and Step 7's CSS-selector edits need the real markup. Status and progress state are intentionally excluded from the spec and are out of review scope.

Every reviewer reports through the same channel — a `SendMessage` call with a bracketed header and a severity-tagged findings list. The severity vocabulary is identical across all seven: `critical | high | medium | low`. A clean reviewer returns an explicit "none" line (`Concerns: none.`, `Gaps: none.`, `Issues: none.`, or `Risk level: low. Key risks: none.`) rather than silence.

## 5. How it fires — dispatch and the UI gate

Two activations stack: getting the team to run at all, and getting the two UI reviewers into it.

**Getting the team to run** has three hard gates in the skill, any of which stops the run:

1. **A plan path.** In background mode an explicit *file* path is mandatory — `--dir` arguments are rejected, and the dispatcher refuses with `Background mode requires a plan path — file not found: <path>` if the file is missing.
2. **Claude Code ≥ 2.1.32.** Below that, Step 3 stops with an upgrade message.
3. **The Agent Teams feature flag.** If `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` is empty or `0`, the skill stops and tells you to set it in `~/.claude/settings.json`.

**Getting the UI reviewers in** is Step 3b. The lead reads the plan HTML (excluding `<style>` and `<script>`) and scans for UI signal keywords:

```text
React, Vue, Svelte, Angular, .tsx, .jsx, .css, .html, className,
style, Tailwind, button, modal, form, dialog, dropdown, page, component
```

If 2+ signals are found (or UI-specific keywords are present), `ui_signals_present = true` and the team grows to seven. The skill announces either `UI signals detected — running 7 reviewers` or `No UI signals — running 5 core reviewers`.

## 6. Decision criteria — five reviewers or seven?

> *Is this plan going to change something a user can see and operate?*

The whole conditional rests on that question, answered heuristically by keyword scan rather than by asking.

### Five core reviewers — always

Architecture, Completeness, Testability, Risk, and Conventions apply to *any* implementation plan — a database migration, a build-script change, a refactor with no UI surface. These run unconditionally.

### Plus two UI reviewers — when signals are present

UX and Accessibility only earn their slot when the plan touches a user-facing surface. Both agents' descriptions say so explicitly: "Use only for plans that touch React, Vue, UI components, or user-facing flows." Spawning them on a backend-only plan would spend two agents producing "none" findings.

### The trade the heuristic makes

A keyword scan is cheap but fallible. A plan that builds a UI without naming a framework — describing "the screen the user lands on" in prose with none of the 17 keywords — would get five reviewers, not seven. The heuristic biases toward *not* running UI reviewers unless there's textual evidence to justify them; it favors precision over recall. If you know a plan is UI work but it reads abstractly, add a concrete keyword (a `.tsx` path, a `button` label) so the scan trips.

## 7. The seven reviewers — mandate by mandate

Each reviewer is a focused system prompt with a fixed mandate, a "how to review" checklist, and a fixed report format. Below is what each one judges and the shape of what it sends back.

### Architecture — *is the shape of the solution sound?*

Scope: component boundaries, layer separation, data flow, external dependencies, and fit with the codebase's existing architecture. It hunts for one-directional dependency flow, hidden integration points, and steps that defer structural decisions. Reports `Fit:` + `Concerns:` + `Recommendations:`.

### Completeness — *can someone execute this without guessing?*

Scope: step granularity, file coverage, missing edge cases (migrations, schema, config, types), acceptance-criteria clarity, and verification feasibility. Its signature catch is the vague verb — a step that says "implement," "refactor," or "improve" without a concrete target. Reports `Completeness:` + `Gaps:` + `Recommendations:`.

### Testability — *is the objective provable by a test?*

Scope: unit/integration/E2E coverage as appropriate, and — the one it cares most about — whether a real smoke or mock test directly asserts the plan's stated objective. It flags any acceptance criterion with no corresponding test, and tests too broad or too narrow to matter. Reports `Test coverage:` + `Gaps:` + `Recommendations:`.

### Risk — *what could go wrong, and can we undo it?*

Scope: breaking changes, data safety, concurrency and race conditions, dependency hazards, rollback story, and performance impact. It is the one reviewer that leads with an overall grade — `Risk level: <critical|high|medium|low>` — followed by `Key risks:` and `Mitigations:`. It looks for unguarded mutations, backward-compat breaks without versioning, and steps that are hard to undo mid-way.

### Conventions — *will this code look like it belongs?*

Scope: naming (camelCase / kebab-case / PascalCase), file placement, code style, import organization, test-file naming (`.test.ts` / `.spec.ts`), and docstring style. It checks that new files land where similar files already live. Reports `Fit:` + `Issues:` + `Recommendations:`.

### UX *(conditional)* — *is the experience clear and frictionless?*

Scope: happy-path user flow, error states and recovery, loading and empty states, interaction clarity (button labels, CTAs), responsive behavior across viewports, and discoverability. Signature catch: "add a button" with no label, placement, or behavior specified. Reports `User fit:` + `Concerns:` + `Recommendations:`.

### Accessibility *(conditional)* — *does it meet WCAG 2.1 AA?*

Scope: keyboard navigation and focus management, screen-reader support (roles, labels, live regions), semantic HTML, color contrast ≥ 4.5:1, touch targets ≥ 44×44px, `prefers-reduced-motion`, and form-label association. It flags `<div>` buttons without roles, unlabeled inputs, and missing focus traps. Reports `A11y compliance:` + `Issues:` + `Recommendations:`.

A standing instruction appears in all seven: **"Do not restate the plan."** The reports are findings only, never a summary of what the plan says — which keeps the lead's synthesis context lean.

## 8. Boundaries — what the team does NOT do

1. **It is not a code reviewer.** The skill says so directly: "For code, use `code-review`." The team reviews the *plan*, not a diff.
2. **It is not a conversational stress-test.** For interactive grilling of a plan, the skill points to `plan-interview`. This team runs once, in parallel, and synthesizes — it does not hold a dialogue.
3. **Reviewers never write.** All seven are read-only (`Read, Glob, Grep, Bash`). Only the lead edits the plan, and only at Step 7.
4. **Background mode never walks findings.** `--background` implies `--skip-analysis`, so the Step 6b per-finding triage is skipped entirely; the full edit table is applied unattended. Interactive runs can triage finding-by-finding.
5. **It does not review status or progress.** The extracted spec deliberately omits status and progress state; whether a plan is `todo` or `in-progress` is out of scope.
6. **It does not auto-activate on every plan type.** The skill runs only when the user asks to review or improve an *implementation* plan — not roadmaps or spike plans.

## 9. Interactions with related systems

- **The interactive twin.** `agent-review-plan` mirrors `review-plan` exactly; the dispatcher exists only to run it non-blocking. The slash-command entry point is `/plan-agent:review-plan-bg <path>`.
- **Agent Teams.** The whole subsystem is built on Claude Code's experimental Agent Teams feature — parallel teammate subagents that report to a lead via `SendMessage`. Without the feature flag and a recent-enough CLI, it hard-stops (see §5).
- **The plan format.** The team consumes the HTML plans produced by `/plan-agent:implementation-plan`. The extractor reads those plans' visible DOM; legacy plans carry an embedded digest the extractor falls back to.
- **Sibling plugins.** `code-review` (code diffs), `plan-interview` (conversational stress-test), and `product-plans` (a separate six-role cross-functional panel for PRDs and proposals) cover the adjacent territory this team deliberately avoids.

## 10. Project-specific context

**The extractor path is cwd-sensitive — verify before trusting it.** Every reviewer brief, and every agent's "How to Review" section, instructs: `node scripts/extract-plan-spec.mjs <plan-path>`. As of this writing the script exists at the **repo-root** `scripts/extract-plan-spec.mjs`, *not* under the plugin directory. The command therefore only resolves when the reviewer's working directory is the repo root. The briefs include a fallback for exactly this — "If the extractor cannot run, fall back to reading the full HTML file" — so a missing script degrades to a slower full-HTML read rather than a hard failure. If you relocate the plugin or run from another cwd, expect the fallback path, not the fast path.

**Version.** These behaviors are from `plan-agent` v2.8.4 as registered in `.claude-plugin/marketplace.json`. The version is bumped manually per the marketplace's convention; later versions may change reviewer counts or the UI-signal keyword list.

## 11. Maintenance and audit

- **When you add or rename a reviewer:** update three places in lockstep — the agent file in `agents/`, the spawn brief in `references/role-prompts.md`, and the role-by-role section in `references/output-template.md`. The skill's Step 4 names the five core reviewers explicitly; a renamed agent that isn't reflected there won't spawn.
- **When you change the UI-signal list:** edit Step 3b's keyword set in the skill. Adding a keyword widens when the two UI reviewers run; the agents' own descriptions ("Use only for plans that touch React, Vue, ...") should stay consistent with it.
- **When the extractor moves:** re-check §10. The brief's hard-coded `scripts/extract-plan-spec.mjs` path is the single most fragile cross-reference in the subsystem.
- **Prune nothing silently.** All seven reviewers are referenced by name in the skill description and the dispatcher description; removing one means editing both descriptions too, or the advertised count (`seven-reviewer Agent Team`) goes stale.

## 12. Verification protocol

To confirm this guide still matches the code:

1. **Reviewer count and names.** Run `ls kit/plugins/plan-agent/agents/plan-reviewer-*.md` — expect exactly seven, matching §2's table.
2. **Always-vs-conditional split.** `grep -n "plan-reviewer-" kit/plugins/plan-agent/skills/review-plan/SKILL.md` — Step 4 should list five core reviewers always and the two UI reviewers under `When ui_signals_present`.
3. **The UI-signal keywords.** Re-read Step 3b in the skill; confirm the keyword list in §5 is current.
4. **The gates.** Confirm the version floor (`2.1.32`) and the flag name (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`) in Step 3.
5. **The extractor path.** Run `find . -name extract-plan-spec.mjs -not -path '*/node_modules/*'`. If it is *not* under `kit/plugins/plan-agent/`, §10's caveat still holds.
6. **Smoke test (canned prompt).** Against a real UI plan:
   ```text
   /plan-agent:review-plan-bg docs/plans/<some-ui-plan>.html
   ```
   Expected: the run announces "Spawned 7 reviewers (5 core + 2 UI)" and finishes with "Plan updated in place: <path>", appending a `<details class="team-review">` block to the plan. A backend-only plan should instead announce "Spawned 5 core reviewers."

---

## Quick reference

```text
DISPATCHER  agent-review-plan.md  (background:true, model:sonnet)
  └─ calls Skill review-plan with "<path> --background"

GATES (skill stops if any fail)
  [1] explicit plan FILE path (no --dir in bg mode)
  [2] Claude Code >= 2.1.32
  [3] CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = 1

TEAM
  ALWAYS (5)            architecture | completeness | testability
                       | risk | conventions
  IF UI SIGNALS (+2)    ux | accessibility
  signal scan = 2+ of: React Vue Svelte Angular .tsx .jsx .css
    .html className style Tailwind button modal form dialog
    dropdown page component

EACH REVIEWER
  reads compact SPEC via scripts/extract-plan-spec.mjs (full-HTML fallback)
  read-only: Read Glob Grep Bash   — never writes
  reports via SendMessage: [Header] + findings, severity
    critical|high|medium|low ; "none" if clean ; never restates plan

LEAD (skill)
  reads FULL HTML  → synthesize (output-template) → triage*
    → apply inline edits + append <details class="team-review">
  *triage SKIPPED in background mode (--skip-analysis implied)
```

---

## Cross-references

- [Create custom subagents](https://code.claude.com/docs/en/sub-agents) — Claude Code docs on subagent definition, tools, and model routing (verified).
- [Plugins reference](https://code.claude.com/docs/en/plugins-reference) — schema for plugin agents and the `name` / `description` / `tools` / `model` frontmatter fields (verified).
- [`agent-review-plan.md`](../../../kit/plugins/plan-agent/agents/agent-review-plan.md) — the background dispatcher.
- [`review-plan/SKILL.md`](../../../kit/plugins/plan-agent/skills/review-plan/SKILL.md) — the orchestrating skill (eight-step workflow).
- [`references/role-prompts.md`](../../../kit/plugins/plan-agent/skills/review-plan/references/role-prompts.md) and [`references/output-template.md`](../../../kit/plugins/plan-agent/skills/review-plan/references/output-template.md) — spawn briefs and synthesis structure.
- Sibling plugins: `code-review` (code diffs), `plan-interview` (conversational stress-test), `product-plans` (six-role product panel).
