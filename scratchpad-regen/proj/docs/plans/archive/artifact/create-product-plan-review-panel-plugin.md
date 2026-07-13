---
status: completed
type: artifact
created: 2026-05-14
---

# Plan: Create the `product-plan-review-panel` plugin

## Context

The user wants a reusable Claude Code capability that reviews product plans,
PRDs, UX flows, technical plans, and implementation plans using a simulated
cross-functional review team — one lead coordinator plus five specialist
reviewers (Product Manager, Lead Developer, UX Designer, Lead Frontend
Engineer, Accessibility Expert).

Today the marketplace has `plan-interview` (structured Q&A with the user) and
`deep-grill` (branch-walking critique). Neither simulates a multi-persona
review panel. The new capability fills that gap and produces a consolidated
review plus, by default, a revised plan.

User decisions captured before planning **and confirmed in the Round 1 / Round
3 interview** (see Interview Summary at end of file):

- **Home**: its own standalone plugin at `kit/plugins/product-plan-review-panel/`.
- **Execution model**: real Claude Code [Agent Teams](https://code.claude.com/docs/en/agent-teams) — one lead session coordinates five teammates spawned from reusable subagent definitions. Hard stop with enablement steps if the feature flag isn't set; no in-prompt fallback in v1.0.0.
- **Subagent scope**: teammate-only — bodies are written to be appended to a teammate system prompt; standalone invocation is not supported in v1.0.0.
- **Default output behavior**: produce a revised plan unless the user opts out via `AskUserQuestion`. At write time, the skill asks where to put it (sibling vs overwrite vs in-place append) with no fixed default.
- **Marketplace category**: `productivity`. Accepted tradeoff: no other plugin currently uses this category, so the entry will sit alone in category-filtered discovery.

## Objective

Ship a new plugin `product-plan-review-panel` containing one auto-activating
skill that orchestrates an Agent Team of five specialist subagents to review a
product plan, synthesize their findings into a fixed 14-section output, and
(by default) emit a revised plan to a user-chosen destination. The plugin also
ships the five reusable subagent definitions, scoped for teammate use only.

## Files to create

### Plugin scaffolding

- `kit/plugins/product-plan-review-panel/.claude-plugin/plugin.json` — manifest with `name`, `description`, `author`, `license`, `keywords`, `homepage`, `repository`. **No `version` field** (lives in `marketplace.json`). **`homepage` pinned** to `https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/product-plan-review-panel` per [`/CLAUDE.md`](../../CLAUDE.md).
- `kit/plugins/product-plan-review-panel/README.md` — overview, components, installation, usage, structure. **Must not advertise standalone subagent invocation** — describe only the team-orchestrated flow.
- `kit/plugins/product-plan-review-panel/CHANGELOG.md` — `1.0.0` initial entry.

### Skill

- `kit/plugins/product-plan-review-panel/skills/product-plan-review-panel/SKILL.md` — entry point.
- `kit/plugins/product-plan-review-panel/skills/product-plan-review-panel/references/role-prompts.md` — per-role spawn-prompt templates (kept out of SKILL.md to stay under the 500-line cap).
- `kit/plugins/product-plan-review-panel/skills/product-plan-review-panel/references/output-template.md` — verbatim 14-section final-report template the lead reproduces.

### Subagent definitions (teammate-only)

- `kit/plugins/product-plan-review-panel/agents/product-reviewer-pm.md`
- `kit/plugins/product-plan-review-panel/agents/product-reviewer-lead-developer.md`
- `kit/plugins/product-plan-review-panel/agents/product-reviewer-ux-designer.md`
- `kit/plugins/product-plan-review-panel/agents/product-reviewer-frontend-engineer.md`
- `kit/plugins/product-plan-review-panel/agents/product-reviewer-accessibility-expert.md`

## Files to modify

- `.claude-plugin/marketplace.json` — bump top-level `version` from `3.3.0` to `3.4.0` (MINOR — new plugin added). Append the new plugin entry with `version: "1.0.0"`, `category: "productivity"`, focused one-sentence description, and tags (`panel-review`, `multi-reviewer`, `agent-team`, `product-plan`, `prd`, `ux`, `accessibility`, `review`). Project's PostToolUse hook auto-validates JSON syntax.

## Reusable patterns to follow (do not reinvent)

- **Plugin layout**: mirror `kit/plugins/skill-reviewer/` — `.claude-plugin/plugin.json` + `README.md` + `CHANGELOG.md` + `skills/<name>/SKILL.md` + `agents/*.md` (sibling to `skills/`, not nested inside it).
- **SKILL.md structure**: mirror [`kit/plugins/plan-interview/skills/plan-interview/SKILL.md`](../../kit/plugins/plan-interview/skills/plan-interview/SKILL.md) — frontmatter, Table of Contents, numbered Steps with progressive disclosure, references pointers.
- **Output-template style**: copy the fenced-markdown approach from [`kit/plugins/code-review/skills/code-review-agent/SKILL.md`](../../kit/plugins/code-review/skills/code-review-agent/SKILL.md) — verbatim block the model reproduces.
- **Plan-file resolution**: reuse the Step 1 priority order from `plan-interview/SKILL.md` (user message path → open IDE file → project `plansDirectory` → global `plansDirectory` → `~/.claude/plans/*.md`). Reference, don't reimplement.
- **Subagent file format**: standard Claude Code subagent files. Reference: [`kit/plugins/code-review/agents/agent-code-reviewer.md`](../../kit/plugins/code-review/agents/agent-code-reviewer.md).
- **Authoring rules**: [`/.claude/rules/skill-authoring.md`](../../.claude/rules/skill-authoring.md).
- **Marketplace registration**: [`/.claude/rules/marketplace.md`](../../.claude/rules/marketplace.md).

## Skill design (concise spec for the implementer)

### Frontmatter

```yaml
---
name: product-plan-review-panel
description: "Use when the user asks to review, critique, validate, stress-test, harden, or prepare a product plan, PRD, feature proposal, UX flow, technical plan, or implementation plan for development — runs a simulated cross-functional review panel (PM, Lead Developer, UX, Frontend, Accessibility) coordinated by a lead and produces a consolidated review plus a revised plan."
allowed-tools: Read, Glob, Bash, AskUserQuestion, TodoWrite, Edit, Write
---
```

### "When not to use" section in SKILL.md

- **Do not invoke from plan mode.** The skill performs writes (revised plan, possible env-var nudge) and assumes the lead can act. Confirm plan mode is off before running.
- **Not a code reviewer.** For code, use `code-review`. For plan-stress-testing without a panel, use `plan-interview`.

### SKILL.md body (numbered Steps)

1. **Step 0 — Progress todos**: `TodoWrite` one todo per step.
2. **Step 1 — Resolve the plan file**: reuse the plan-interview priority order; announce path.
3. **Step 2 — Choose output mode**: `AskUserQuestion` — `"Review only"` vs `"Review + revised plan"` (default: revised plan, preselected).
4. **Step 3 — Verify Agent Team availability**:
   - Run `claude --version`.
   - Parse with `^(\d+)\.(\d+)\.(\d+)` and compare only the first three numeric components — ignore pre-release suffixes (`-beta`, `+dev`, etc.) so they don't block.
   - Confirm `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`.
   - If either check fails, surface the exact enablement instructions from the Agent Teams docs and stop. **Do not** fall back to in-prompt role-play.
5. **Step 4 — Spawn the team (verbatim natural-language directive)**: SKILL.md contains a fenced directive block the lead executes verbatim, e.g.:

   ```text
   Create an agent team to review the product plan at <ABSOLUTE_PATH>.
   Spawn all five teammates immediately so they review in parallel using
   these subagent types:
     - product-reviewer-pm
     - product-reviewer-lead-developer
     - product-reviewer-ux-designer
     - product-reviewer-frontend-engineer
     - product-reviewer-accessibility-expert
   Brief each teammate with the matching section from
   references/role-prompts.md (with <ABSOLUTE_PATH> substituted).
   Wait for all five to send findings before synthesizing.
   ```

6. **Step 5 — Wait and collect**: lead waits for all five teammates to send findings via the shared task list. **Reviewer failure handling**: if any teammate stops on an error or goes idle without findings, the lead respawns it once with the same role prompt. If it errors again, the role's section in the final report is marked `Reviewer unavailable — not assessed` and the gap is also surfaced in the Executive Summary and Highest-Risk Issues sections (not only in the role section).
7. **Step 6 — Synthesize**: lead compares findings, surfaces overlaps, names conflicts, evaluates tradeoffs, and challenges weak assumptions. Reproduces the verbatim 14-section template from `references/output-template.md`. Section 14 ("Revised product plan") IS the canonical revised plan; Step 7 below serializes it to disk without re-generating content.
8. **Step 7 — Persist the revised plan (default on)**: unless the user chose review-only at Step 2, prompt via `AskUserQuestion` for the destination:
   - **Sibling file** (`<original-stem>-revised.md`) — non-destructive.
   - **Overwrite the original** — only proceeds if `git status --porcelain <path>` returns empty (source file clean); refuses otherwise.
   - **Append to original** as a new `## Revised Plan` section — file now contains both versions.

   Write using `Write` (sibling, overwrite) or `Edit` (append). The content is section 14 of the chat output, written verbatim — do not re-generate.
9. **Step 8 — Clean up the team**: lead issues `"Clean up the team"` per the docs' warning ("Always use the lead to clean up").

### `references/role-prompts.md`

One section per role. Each section includes the **spawn directive** the lead sends, e.g.:

```text
Spawn a teammate using the product-reviewer-pm agent type with the prompt:
"Review the product plan at <ABSOLUTE_PATH>. You are the Product Manager
reviewer. Independently — without seeing other reviewers' findings — assess
user value, product strategy, business goals, scope, prioritization, success
metrics, assumptions, release readiness, and risks. Report in the required
schema (Works well / Unclear / Critical / Minor / Missing / Risks /
Improvements / Questions / Approval status). If you encounter ambiguity, list
it under 'Unclear' in your own findings — do not message the lead mid-review."
```

Variants for the other four roles, scoped to the user's stated review
dimensions.

### `references/output-template.md`

Fenced verbatim template with the 14 user-required sections, in this order:

1. Executive summary (must explicitly mention any role marked "Reviewer unavailable")
2. Role-by-role review (5 subsections, one per reviewer)
3. Highest-risk issues (must include any reviewer-unavailable gap as a risk)
4. Blocking issues
5. Important but non-blocking improvements
6. UX recommendations
7. Accessibility requirements
8. Frontend implementation considerations
9. Technical feasibility concerns
10. Open questions before development
11. Recommended changes to the plan
12. Conflicts or tradeoffs between reviewer recommendations
13. Final decision (approve / approve with revisions / reject)
14. Revised product plan (omit if user chose review-only at Step 2)

### Subagent definitions (`agents/*.md`)

Each file uses standard subagent frontmatter:

```yaml
---
name: product-reviewer-pm
description: "Product manager reviewer for the product-plan-review-panel skill. Reviews user value, strategy, scope, prioritization, success metrics, assumptions, and release risks. Teammate-only — designed to run inside an Agent Team led by product-plan-review-panel; not for standalone invocation."
tools: Read, Glob, Grep, Bash(git *)
model: inherit
---
```

Body conventions (apply to all five files):

- Define the role and the domain to review.
- List the required output schema (the 9 sub-items above).
- Enforce "review independently — do not infer or anticipate other reviewers' findings, and do not message the lead during the review; list ambiguities under 'Unclear' instead."
- Ban generic praise and abstract advice.
- Force an explicit `Approval status: approve | approve with changes | reject` line.
- May reference "the panel", "the lead", and "the shared task list" (teammate-only context).
- Do **not** include `skills` or `mcpServers` frontmatter keys — they aren't inherited in teammate mode anyway.

## Steps

1. **Read three reference files** — [`/.claude/rules/skill-authoring.md`](../../.claude/rules/skill-authoring.md), [`kit/plugins/plan-interview/skills/plan-interview/SKILL.md`](../../kit/plugins/plan-interview/skills/plan-interview/SKILL.md), and [`kit/plugins/code-review/agents/agent-code-reviewer.md`](../../kit/plugins/code-review/agents/agent-code-reviewer.md) — to lock in exact frontmatter conventions and prose voice. *Why:* this repo enforces specific authoring rules (≤500 lines, kebab-case names, third-person descriptions, references one level deep) and a consistent imperative-to-Claude voice. *Verify:* the implementer can quote the frontmatter shape they will use for SKILL.md and each agent file before writing.

2. **Scaffold the plugin directory** at `kit/plugins/product-plan-review-panel/` with empty `skills/product-plan-review-panel/references/` and `agents/` subdirectories, then write `.claude-plugin/plugin.json` (with `homepage` pinned to the plugin-directory URL), `README.md`, and `CHANGELOG.md`. *Why:* `marketplace.json` registration in Step 7 will fail validation if `plugin.json` is missing or the directory layout is wrong. *Verify:* `find kit/plugins/product-plan-review-panel -type f -o -type d` returns the expected tree; `jq '.name, .homepage' kit/plugins/product-plan-review-panel/.claude-plugin/plugin.json` returns the plugin name and the pinned plugin-directory URL; the JSON file contains **no** `version` key.

3. **Write the five subagent definitions** under `kit/plugins/product-plan-review-panel/agents/` following the teammate-only body conventions above. Each frontmatter uses `tools: Read, Glob, Grep, Bash(git *)`. *Why:* the SKILL.md will reference these by `agent type` name when spawning teammates; scoped `Bash(git *)` eliminates unscoped-shell permission prompts. *Verify:* `ls kit/plugins/product-plan-review-panel/agents/` shows five `.md` files; open one and confirm frontmatter parses (no XML tags, kebab-case `name`, `description` ≤1024 chars, no `skills`/`mcpServers` keys, `tools` line restricted to the four entries above).

4. **Write `skills/product-plan-review-panel/references/role-prompts.md`** with one labeled section per role containing the exact spawn-prompt text the lead will send, including the `<ABSOLUTE_PATH>` placeholder, the 9-item output schema, and the "do not message the lead mid-review" rule. *Why:* extracting these prompts keeps SKILL.md under 500 lines and ensures every teammate gets a consistent brief with explicit ambiguity-handling rules. *Verify:* file contains exactly five sections (one per role), each with a `Spawn a teammate using the <agent-type>` directive matching the five agent filenames from Step 3, and each prompt includes the "list it under 'Unclear'" instruction.

5. **Write `skills/product-plan-review-panel/references/output-template.md`** with the verbatim 14-section template inside a single fenced markdown block. Section 1 (Executive summary), section 3 (Highest-risk issues), and the affected role section in section 2 must all surface any `Reviewer unavailable` status — not section 2 alone. *Why:* the lead reproduces this block verbatim during synthesis; surfacing reviewer gaps in three places prevents the user from missing them. *Verify:* the file shows all 14 sections in spec order; sections 1/2/3 contain explicit `Reviewer unavailable` handling notes; section 14 carries an "(omit if review-only)" gating note.

6. **Write `skills/product-plan-review-panel/SKILL.md`** following the design spec above (frontmatter, "When not to use" section, Steps 0–8 including the verbatim spawn directive and reviewer-failure handling). *Why:* this is the entry point that auto-activates on review-related prompts and runs the lead workflow. *Verify:* `wc -l` returns ≤ 500; the description front-loads "Use when the user asks to review…" and lists every trigger verb from the user spec; `allowed-tools` lists every tool the body uses and nothing it doesn't; Step 4 contains the verbatim natural-language directive block including "Spawn all five teammates immediately so they review in parallel"; Step 7 contains the three-way `AskUserQuestion` for revised-plan destination with the `git status --porcelain` safety check on the overwrite path.

7. **Register the plugin and bump the marketplace version** in `.claude-plugin/marketplace.json`. Bump top-level `"version"` from `3.3.0` to `3.4.0`. Append a new entry with `name: "product-plan-review-panel"`, `git-subdir` source pointing at `kit/plugins/product-plan-review-panel`, `version: "1.0.0"`, `category: "productivity"`, focused description, and tags. *Why:* without this entry the plugin isn't installable via `/plugin install product-plan-review-panel@agentics-kit`; the top-level MINOR bump matches the rule that adding a component is a MINOR change. *Verify:* `jq '.version' .claude-plugin/marketplace.json` returns `"3.4.0"`; `jq '.plugins[] | select(.name=="product-plan-review-panel") | {version, category, source, tags}' .claude-plugin/marketplace.json` returns the expected shape with `category: "productivity"`; project's PostToolUse JSON-validation hook reports clean.

8. **Update the plugin's `README.md` and `CHANGELOG.md`** to reflect the final shipped surface (one skill + five teammate-only agents). README's Components section describes the team flow only — do NOT show `subagent_type: product-reviewer-pm` examples that would imply standalone invocation. *Why:* CLAUDE.md requires plugin docs updated alongside structural changes; teammate-only framing prevents users from calling subagents that aren't designed to run alone. *Verify:* README's Components section lists the skill (with trigger keywords) and notes the five subagent types are teammate-only; CHANGELOG has a `1.0.0` entry with a one-line summary; no `subagent_type:` invocation examples appear anywhere in the README.

9. **Rename this plan file** from `create-a-reusable-skill-pure-tide.md` to `create-product-plan-review-panel-plugin.md` using `git mv` (or `mv` if untracked). *Why:* the current filename contains the random `pure-tide` suffix flagged by [`/.claude/rules/plan-mode.md`](../../.claude/rules/plan-mode.md); renaming before commit makes the filename match the H1 and the plan's content. *Verify:* `ls docs/plans/ | grep -i product-plan-review-panel` shows the renamed file; `git status` shows the rename (or the new untracked filename); the H1 heading inside the file still matches.

10. **Run `/skill-reviewer:reviewing-skills` against the new SKILL.md and `/skill-reviewer:auditing-allowed-tools` against its frontmatter.** *Why:* these are the repo's in-house enforcement skills for the authoring rules. *Verify:* the scored audit returns no failing items in "Core quality" or "Frontmatter constraints"; `allowed-tools` matches the tools actually used in the SKILL.md body.

11. **End-to-end dry run.** Enable agent teams (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`), open a session in this repo loading the new plugin (`claude --plugin-dir ./kit/plugins/product-plan-review-panel`), point Claude at an existing plan under `docs/plans/`, and ask "review this product plan with the panel." *Why:* confirms auto-activation, real five-teammate spawn from the new subagent types, parallel execution, and the 14-section output. *Verify:* (a) the skill triggers without an explicit `/` invocation; (b) `~/.claude/teams/` shows a team config with five members; (c) the final report contains all 14 sections (or 13 if review-only) and ends with an explicit `Final decision: ...` line; (d) `~/.claude/teams/<team>/config.json` shows the five teammate names mapping to the new `product-reviewer-*` subagent types.

## Verification

End-to-end: with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set, a fresh Claude
Code session loading the new plugin should auto-trigger
`product-plan-review-panel` on a prompt like "review this product plan"
against any `.md` plan file. The session should spawn an agent team of five
teammates using the new `product-reviewer-*` subagent types **in parallel**,
the lead should produce the 14-section consolidated report ending in an
explicit final-decision line, and (unless the user opted out at Step 2)
prompt for a revised-plan destination and write the file accordingly.

If a reviewer errors twice (initial + respawn), the report must still ship
with that role flagged as `Reviewer unavailable — not assessed` in the
Executive Summary, the role section, and Highest-Risk Issues.

The repo-level skill-reviewer audit should pass with no failing items, the
marketplace JSON validator hook should report clean, and `jq` should confirm
the plugin is registered at `version: 1.0.0` with `category: "productivity"`,
and that the marketplace top-level `version` is `3.4.0`.

**Commit hygiene**: the implementation commit set must include this plan file
(renamed) alongside the new plugin files — `CLAUDE.md` requires the plan to
ship in the same commit as plugin changes.

## Next Steps *(optional)*

- **Backfill a paired slash command** (mirrors how `plan-interview` pairs a skill with an explicit `/plan-interview:plan-interview` command):

  ```text
  Add commands/product-plan-review-panel.md to the product-plan-review-panel
  plugin that explicitly invokes the skill with a plan-file path argument.
  Match the description and allowed-tools conventions used by existing
  commands in the marketplace. Bump the plugin to a new MINOR version.
  ```

- **Fallback mode for users without Agent Teams enabled**:

  ```text
  Extend product-plan-review-panel/SKILL.md with an opt-in single-session
  fallback: when CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS is not set, offer to
  run all five reviews sequentially in the current Claude session using the
  same role prompts. Keep the agent-team path as the default and clearly
  label the fallback as lower-fidelity (risk of role-bleed). Bump the plugin
  to a new MINOR version.
  ```

- **Revisit ask-at-write-time friction**:

  ```text
  After running product-plan-review-panel on at least five real plans,
  evaluate whether the three-way AskUserQuestion at Step 7 (sibling vs
  overwrite vs append) creates more friction than value. If so, propose a
  default destination (most likely sibling file) with the prompt becoming
  a confirm-only "Write revised plan to <path>?" yes/no.
  ```

- **Category revisit**:

  ```text
  After product-plan-review-panel has shipped under category 'productivity'
  for some time, check whether any other plugins have adopted the same
  category. If the category remains a one-off, recommend whether to (a)
  migrate the plugin to 'development' to sit with other review tools, or
  (b) seed two or three more productivity-style plugins. Provide a decision
  with reasoning.
  ```

## Interview Summary

> Output of `/plan-interview:plan-interview` run on 2026-05-14. All findings
> have been folded into the body of this plan above; this section is preserved
> for traceability.

### Key Decisions Confirmed

- Agent-team gating: hard stop with enablement steps; no in-prompt fallback in v1.0.0.
- Subagent scope: teammate-only.
- Spawn directive style: verbatim natural-language directive block in SKILL.md Step 4.
- Teammate tools: `Read, Glob, Grep, Bash(git *)`.
- Reviewer failure handling: respawn once → partial report with `Reviewer unavailable` surfaced in Executive Summary + role section + Highest-Risk Issues.
- Revised plan destination: AskUserQuestion at write time (sibling vs overwrite-with-git-safety vs append). No fixed default.
- Marketplace top-level version: MINOR → `3.4.0`.
- Plugin category: `productivity` (orphaned in category-filtered discovery; tradeoff accepted).

### Plan Naming

| Element | Current | Issue | Suggested | Decision |
|---------|---------|-------|-----------|----------|
| Filename | `create-a-reusable-skill-pure-tide.md` | Random `pure-tide` suffix | `create-product-plan-review-panel-plugin.md` | Approved; deferred to Step 9 of implementation (plan mode forbids `mv` now) |
| H1 | `# Plan: Create the` ``product-plan-review-panel`` `plugin` | Pass | — | No change |

### Open Risks & Concerns

- **`productivity` category orphans the plugin in filtered discovery.** Small but real; user accepted.
- **Reviewer-failure UX** quietly drops a role unless the lead surfaces "Reviewer unavailable" prominently. Mitigated by requiring the gap in three sections (Executive Summary, role section, Highest-Risk Issues).
- **Ask-at-write-time** trades default friction for choice friction. Revisit prompt-fatigue after five real runs (see Next Steps).
- **Experimental-flag dependency** locks v1.0.0 to opt-in users. Fallback prompt in Next Steps is the escape hatch.
- **Permission-prompt friction**: even with `Bash(git *)`, git invocations bubble approvals to the lead. Pre-approving `Bash(git *)` in user settings helps.
- **Teammate context isolation**: each teammate loads project CLAUDE.md fresh but not the lead's conversation. `role-prompts.md` should reserve a "session notes" placeholder so the lead can inject session-specific deltas into each spawn prompt.

### Additional Concerns Folded Into the Plan Body

1. `homepage` URL pinned to plugin-directory URL (Files to create + Step 2 verify).
2. Teammate ambiguity rule: list under "Unclear" rather than messaging the lead (role-prompts.md + subagent body conventions).
3. `claude --version` parse: regex `^(\d+)\.(\d+)\.(\d+)`, ignore pre-release suffixes (SKILL.md Step 3).
4. Section 14 ↔ file write: section 14 IS the revised plan; Step 7 serializes it without re-generating (SKILL.md Step 6 + Step 7).
5. Spawn parallelism: directive explicitly says "Spawn all five teammates immediately so they review in parallel" (SKILL.md Step 4).
6. README must not advertise standalone subagent invocation (Step 8 verify).
7. Commit hygiene: plan file ships in the same commit set as the plugin (Verification).
8. "When not to use": skill must not be invoked from plan mode (SKILL.md "When not to use" section).
9. Marketplace top-level bump: `3.3.0` → `3.4.0`, category `productivity` (Step 7).

### Complexity Check

No over-engineering detected. 11 files = 3 plugin scaffolding (Claude Code spec) + 1 SKILL.md + 2 reference files (500-line cap) + 5 subagent files (one per stated role). Nothing reducible without violating spec or user requirements.
