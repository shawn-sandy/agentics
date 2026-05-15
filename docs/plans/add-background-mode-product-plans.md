---
status: completed
type: feature
created: 2026-05-14
modified: 2026-05-14
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

## Steps

1. **Add `--background` flag detection at the top of Step 0 in `SKILL.md`** — scan `$ARGUMENTS` for the literal `--background`; set `mode = background` (else `mode = interactive`). — *Why:* the rest of the steps need to branch on `mode` without re-parsing args each time. *Verify:* `grep -n '\-\-background' kit/plugins/product-plans/skills/product-plans/SKILL.md` returns the new detection line in Step 0.

2. **Modify Step 1 (plan file resolution) in `SKILL.md`** — when `mode = background`, only accept a path from `$ARGUMENTS`; skip the IDE / settings / glob fallbacks and emit `Background mode requires a plan path` then stop if absent. — *Why:* the 5-stage fallback can silently pick the wrong file when no human is watching. *Verify:* the relevant Step 1 paragraph names `mode = background` as a branch and shows the stop message.

3. **Modify Step 2 (output mode) in `SKILL.md`** — when `mode = background`, set `output_mode = "review + revised plan"` without calling `AskUserQuestion`. — *Why:* `AskUserQuestion` hangs forever in a backgrounded subagent. *Verify:* `grep -n 'AskUserQuestion' kit/plugins/product-plans/skills/product-plans/SKILL.md` shows the Step 2 reference is gated by `mode = interactive`.

4. **Modify Step 7 (revised-plan destination) in `SKILL.md`** — when `mode = background`, write to `<original-stem>-revised.md` (sibling, non-destructive) via `Write`; skip the destination `AskUserQuestion` and the overwrite/append branches. — *Why:* same as Step 3 — no human to answer. Sibling is the safest default since it never destroys the source. *Verify:* the Step 7 prose explicitly states that background mode goes straight to sibling write.

5. **Create `kit/plugins/product-plans/agents/agent-product-plans.md`** — frontmatter with `background: true`, `tools: Skill, Read`, `maxTurns: 30`. Body: Role, Caveat, and Workflow (confirms file exists via `Read`, calls `Skill(product-plans:product-plans, "<path> --background")`, reports sibling path). — *Why:* gives the slash command a named subagent_type to dispatch and isolates background execution from the user's session. *Verify:* `grep -E '^(name|background|tools|maxTurns):' kit/plugins/product-plans/agents/agent-product-plans.md` shows all four fields.

6. **Create `kit/plugins/product-plans/commands/product-plans-bg.md`** — `allowed-tools: Agent`. Body: error on empty args, Agent tool call with `subagent_type: "agent-product-plans"` and `run_in_background: true`, ack line. — *Why:* gives the user a one-liner `/product-plans:product-plans-bg <path>` entry point. *Verify:* `ls kit/plugins/product-plans/commands/product-plans-bg.md` succeeds; the body explicitly sets `run_in_background: true`.

7. **Update `kit/plugins/product-plans/CHANGELOG.md`** — prepend a `## 2.1.0 — 2026-05-14` entry listing the three new surfaces and the background defaults table. — *Why:* CHANGELOG is the user-facing record of what shipped. *Verify:* `head -20 kit/plugins/product-plans/CHANGELOG.md` shows the `2.1.0` heading at the top.

8. **Update `kit/plugins/product-plans/README.md`** — add "Background mode" subsection under **Features** and **Usage**, update Plugin Structure tree, add `Command: product-plans-bg` + `Agent: agent-product-plans` under **Components**. — *Why:* README is the primary install/usage doc. *Verify:* `grep -nE 'background|product-plans-bg|agent-product-plans' kit/plugins/product-plans/README.md` returns matches in three sections.

9. **Bump `.claude-plugin/marketplace.json`** — change `product-plans` entry `version` from `2.0.0` to `2.1.0`. — *Why:* MINOR bump per `.claude/rules/marketplace.md` (additive command + agent + flag, no breaking changes). *Verify:* `jq -r '.plugins[] | select(.name=="product-plans") | .version' .claude-plugin/marketplace.json` prints `2.1.0`.

10. **Update `CLAUDE.md` reference-implementations row** — change the `product-plans` row's type column from `Skills + Agents` to `Skills + Agents + Commands` and amend the notes to mention background-mode panel. — *Why:* `CLAUDE.md` is loaded into every session; the table is how future-you discovers what each plugin contains. *Verify:* `grep -n 'product-plans' CLAUDE.md` shows the updated row.

## Verification

End-to-end:

1. Run `claude --plugin-dir ./kit/plugins/product-plans` to load the
   updated plugin locally. Confirm Claude Code prints no manifest or
   skill-name errors.
2. **Foreground regression check** — run the skill without any flag on a
   small plan file. Confirm it still asks the two `AskUserQuestion` prompts
   (Steps 2 and 7) and behaves identically to v2.0.0.
3. **Background flag check** — call the skill directly with `--background`
   and a plan path: confirm no `AskUserQuestion` fires, the panel runs, and
   a `<stem>-revised.md` file lands next to the source.
4. **Slash-command check** — run
   `/product-plans:product-plans-bg docs/plans/<some-plan>.md` and confirm
   the chat returns the one-line ack immediately.
5. **No-path error path** — run `/product-plans:product-plans-bg` with no
   argument; confirm the agent returns `Background mode requires a plan path`.
6. **Marketplace registration** — `jq -e '.plugins[] | select(.name=="product-plans" and .version=="2.1.0")' .claude-plugin/marketplace.json` exits `0`.

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
