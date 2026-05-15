---
status: todo
type: feature
created: 2026-05-14
---

# Plan: Add background-mode + agent variant to `product-plans` (v2.1.0)

## Context

The `product-plans` skill (just renamed in v2.0.0 — see commit `05d892c`)
runs a five-reviewer Agent Team panel and produces a 14-section report
plus an optional revised plan. Today it can only be invoked
synchronously — it blocks the user's chat for the duration of the panel
and asks 2–3 `AskUserQuestion` prompts (output mode, revised-plan
destination) that prevent unattended execution.

The user wants to fire the panel off and keep working: `/product-plans-bg
docs/plans/my-feature.md` should dispatch a background agent that runs
the whole panel and writes the revised plan to a sibling file, returning
immediately.

Two patterns already exist in this repo for this:

- `plan-interview/plan-to-html` ships `--background` / `--async` flags
  directly on the skill (`kit/plugins/plan-interview/skills/plan-to-html/SKILL.md`).
- `git-agent` ships paired `agent-*` subagents
  (`kit/plugins/git-agent/agents/agent-ship.md` et al.) with
  `background: true` frontmatter, dispatched by a thin `commands/*-bg.md`
  wrapper.

This plan adopts a **hybrid**: a `--background` flag on the skill (one
source of truth, no duplicated workflow body), a thin background-agent
wrapper that invokes the skill via the `Skill` tool, and a slash-command
dispatcher. Bumps the plugin to **v2.1.0** (MINOR — additive only).

## Objective

Ship three additive surfaces so `product-plans` can run unattended:

1. A `--background` flag on the skill that suppresses all
   `AskUserQuestion` calls and uses fixed defaults.
2. An `agents/agent-product-plans.md` subagent (`background: true`,
   `tools: Skill, Read`) that wraps a single `Skill` invocation.
3. A `commands/product-plans-bg.md` slash-command dispatcher
   (`allowed-tools: Agent`) that fires the agent with
   `run_in_background: true`.

No breaking changes. Foreground behaviour is preserved exactly.

## Files to create

- `kit/plugins/product-plans/commands/product-plans-bg.md` — slash-command dispatcher
- `kit/plugins/product-plans/agents/agent-product-plans.md` — background wrapper agent

## Files to modify

- `kit/plugins/product-plans/skills/product-plans/SKILL.md` — add `--background` flag handling in Steps 0, 1, 2, 7
- `kit/plugins/product-plans/CHANGELOG.md` — prepend `2.1.0` entry
- `kit/plugins/product-plans/README.md` — document the new flag, agent, command in **Features**, **Usage**, **Components**
- `.claude-plugin/marketplace.json` — bump `product-plans` entry version `2.0.0` → `2.1.0`
- `CLAUDE.md` — update reference-implementations table row to include "Commands"

## Defaults when `--background` is set

| Step | Foreground (current) | Background (new) |
|------|----------------------|------------------|
| 1 — plan file | falls through 5-stage resolution; tells user + stops if none found | requires explicit path in `$ARGUMENTS`; errors out fast with `Background mode requires a plan path` if missing |
| 2 — output mode | `AskUserQuestion` (default `Review + revised plan`) | hard-coded to `review + revised plan` — no question |
| 7 — write destination | `AskUserQuestion` (Sibling / Overwrite / Append) | hard-coded to **sibling file** (`<stem>-revised.md`); non-destructive |
| 5 — teammate failure | respawn once, mark unavailable | unchanged (respawn cap of 1 already prevents loops) |

`--background` is a string-contains check on `$ARGUMENTS` (mirrors
`plan-to-html`'s `--setup` detection).

## Proposed agent shape (`agents/agent-product-plans.md`)

```yaml
---
name: agent-product-plans
description: >
  Background product-plan panel agent. Runs the full five-reviewer
  cross-functional panel (PM, Dev, UX, Frontend, Accessibility) on a
  product plan, PRD, or feature proposal without blocking the parent
  session. Use when the user asks to "run the panel in the background",
  "fire off the review panel", or "review this plan and keep working".
  Mirrors the product-plans skill but runs as a background subagent.
tools: Skill, Read
model: sonnet
maxTurns: 30
background: true
---
```

Body: ~20 lines. Role / Caveat / single workflow step that calls
`Skill(skill: "product-plans:product-plans", args: "<path> --background")`
and reports the resolved sibling-file path back when complete. No
workflow duplication.

`tools: Read` is included so the agent can sanity-check the plan path
exists before dispatching the skill. `maxTurns: 30` accommodates the
skill's 8 steps plus the 5 teammate spawn/synthesis cycles.

## Proposed command shape (`commands/product-plans-bg.md`)

```yaml
---
description: Run the product-plans review panel in the background. Pass the plan path as argument.
allowed-tools: Agent
---
```

Body: invoke `Agent` with `subagent_type: "agent-product-plans"`,
`run_in_background: true`, `description: "Background product-plan panel review"`,
and a prompt embedding `$ARGUMENTS` (the plan path). Return a single-line
ack: `Background panel review started: <path>`. No polling.

## Steps

1. **Add `--background` flag detection at the top of Step 0 in `SKILL.md`** — scan `$ARGUMENTS` for the literal `--background`; set `mode = background` (else `mode = interactive`). Add `Skill` and `Read` to nothing — only the skill side changes its own behaviour. — *Why:* the rest of the steps need to branch on `mode` without re-parsing args each time. *Verify:* `grep -n '\\-\\-background' kit/plugins/product-plans/skills/product-plans/SKILL.md` returns the new detection line in Step 0.

2. **Modify Step 1 (plan file resolution) in `SKILL.md`** — when `mode = background`, only accept a path from `$ARGUMENTS`; skip the IDE / settings / glob fallbacks and emit `Background mode requires a plan path` then stop if absent. — *Why:* the 5-stage fallback can silently pick the wrong file when no human is watching. *Verify:* the relevant Step 1 paragraph names `mode = background` as a branch and shows the stop message.

3. **Modify Step 2 (output mode) in `SKILL.md`** — when `mode = background`, set `output_mode = "review + revised plan"` without calling `AskUserQuestion`. — *Why:* `AskUserQuestion` hangs forever in a backgrounded subagent. *Verify:* `grep -n 'AskUserQuestion' kit/plugins/product-plans/skills/product-plans/SKILL.md` shows the Step 2 reference is gated by `mode = interactive`.

4. **Modify Step 7 (revised-plan destination) in `SKILL.md`** — when `mode = background`, write to `<original-stem>-revised.md` (sibling, non-destructive) via `Write`; skip the destination `AskUserQuestion` and the overwrite/append branches. — *Why:* same as Step 3 — no human to answer. Sibling is the safest default since it never destroys the source. *Verify:* the Step 7 prose explicitly states that background mode goes straight to sibling write.

5. **Create `kit/plugins/product-plans/agents/agent-product-plans.md`** — frontmatter from the **Proposed agent shape** section above. Body has three short sections: Role (background panel agent), Caveat (fire-and-forget; in-progress edits to the plan after dispatch may or may not be reflected), Workflow (a single bullet that calls `Skill(product-plans:product-plans, "<path> --background")` and reports the resulting sibling path). — *Why:* gives the slash command a named subagent_type to dispatch and isolates background execution from the user's session. *Verify:* the file exists; `grep -E '^(name|background|tools|maxTurns):' kit/plugins/product-plans/agents/agent-product-plans.md` shows all four fields.

6. **Create `kit/plugins/product-plans/commands/product-plans-bg.md`** — frontmatter from the **Proposed command shape** section above. Body: a `## Workflow` section with one Agent tool call (`subagent_type: "agent-product-plans"`, `run_in_background: true`, prompt embedding `$ARGUMENTS`) plus the ack line format. — *Why:* gives the user a one-liner `/product-plans:product-plans-bg <path>` entry point. *Verify:* `ls kit/plugins/product-plans/commands/product-plans-bg.md` succeeds; the body explicitly sets `run_in_background: true`.

7. **Update `kit/plugins/product-plans/CHANGELOG.md`** — prepend a `## 2.1.0 — 2026-05-14` entry listing the three new surfaces (flag, agent, command) and the background defaults table. — *Why:* CHANGELOG is the user-facing record of what shipped. *Verify:* `head -20 kit/plugins/product-plans/CHANGELOG.md` shows the `2.1.0` heading at the top.

8. **Update `kit/plugins/product-plans/README.md`** — add a "Background mode" subsection under **Features** mentioning the flag + slash command, add a usage example block under **Usage**, and add `Command: product-plans-bg` + `Agent: agent-product-plans` entries under **Components**. — *Why:* README is the primary install/usage doc. *Verify:* `grep -nE 'background|product-plans-bg|agent-product-plans' kit/plugins/product-plans/README.md` returns matches in three sections.

9. **Bump `.claude-plugin/marketplace.json`** — change `product-plans` entry `version` from `2.0.0` to `2.1.0`. — *Why:* MINOR bump per `.claude/rules/marketplace.md` (additive command + agent + flag, no breaking changes). *Verify:* `jq -r '.plugins[] | select(.name=="product-plans") | .version' .claude-plugin/marketplace.json` prints `2.1.0`.

10. **Update `CLAUDE.md` reference-implementations row** — change the `product-plans` row's type column from `Skills + Agents` to `Skills + Agents + Commands` and amend the notes to mention background-mode panel. — *Why:* `CLAUDE.md` is loaded into every session; the table is how future-you discovers what each plugin contains. *Verify:* `grep -n 'product-plans' CLAUDE.md` shows the updated row.

## Verification

End-to-end:

1. Run `claude --plugin-dir ./kit/plugins/product-plans` to load the
   updated plugin locally. Confirm Claude Code prints no manifest or
   skill-name errors.
2. **Foreground regression check** — in that session, run the skill
   without any flag on a small plan file. Confirm it still asks the two
   `AskUserQuestion` prompts (Steps 2 and 7) and behaves identically to
   v2.0.0.
3. **Background flag check** — call the skill directly with
   `--background` and a plan path: confirm no `AskUserQuestion` fires,
   the panel runs, and a `<stem>-revised.md` file lands next to the
   source.
4. **Slash-command check** — run
   `/product-plans:product-plans-bg docs/plans/<some-plan>.md` and
   confirm the chat returns the one-line ack immediately, then a
   background-task completion notification arrives later when the
   sibling file is written.
5. **No-path error path** — run `/product-plans:product-plans-bg`
   with no argument; confirm the agent returns
   `Background mode requires a plan path` and exits without spawning
   the panel.
6. **Cleanup check** — confirm Step 8's `Clean up the team.` directive
   in the skill still fires inside the backgrounded run (no orphaned
   teammates in `claude /agents` output).
7. **Marketplace registration** — `jq -e '.plugins[] | select(.name=="product-plans" and .version=="2.1.0")' .claude-plugin/marketplace.json` exits `0`.

## Next steps *(optional)*

- Add `--mode` and `--write` explicit flags:
  ```text
  Extend the product-plans skill --background mode with optional
  --mode=review|revised and --write=sibling|overwrite|append CLI flags
  so background users can override the hard-coded defaults documented in
  the v2.1.0 CHANGELOG. Mirror the flag-parsing pattern used in
  kit/plugins/plan-interview/skills/plan-to-html/SKILL.md Step 1.
  ```

- Apply the same hybrid pattern to `plan-interview`:
  ```text
  Audit kit/plugins/plan-interview/skills/plan-interview/SKILL.md for
  AskUserQuestion blockers that prevent unattended runs. If any exist,
  propose a --background flag + agents/agent-plan-interview.md +
  commands/plan-interview-bg.md mirroring the product-plans v2.1.0
  pattern. Out of scope: actually implementing it — just the plan.
  ```

## Unresolved questions *(omit if none)*

- Skill-tool availability inside a backgrounded subagent:
  ```text
  Verify that a subagent with `background: true` in its frontmatter and
  `tools: Skill, Read` can successfully invoke the Skill tool to run
  another skill (specifically product-plans:product-plans). The
  plan-interview/plan-to-html --async pattern uses `subagent_type:
  "general-purpose"` instead of a named agent — find out whether that
  choice was deliberate (Skill tool unavailable in custom subagents?)
  or incidental. If custom subagents cannot call Skill, the hybrid
  plan's agent must fall back to either (a) using general-purpose as
  the dispatch type or (b) duplicating the skill workflow into the
  agent body (git-agent pattern). Report back with the result.
  ```
