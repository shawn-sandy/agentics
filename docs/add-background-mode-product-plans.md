# Add background-mode + agent variant to `product-plans` (v2.1.0)

> Adds a `--background` flag, a `agent-product-plans` subagent, and a `/product-plans:product-plans-bg` slash command so the five-reviewer panel can run fully unattended and return immediately (v2.1.0).

<!-- generated:start -->

**Status:** Shipped 2026-05-14  **Plan:** [add-background-mode-product-plans.md](plans/add-background-mode-product-plans.md)
**Type:** artifact

## What shipped

- Added `--background` flag detection at the top of Step 0 in `kit/plugins/product-plans/skills/product-plans/SKILL.md`; when the flag is present, all `AskUserQuestion` prompts are suppressed and fixed defaults are used (output mode: "review + revised plan"; destination: `<stem>-revised.md` sibling file).
- Created `kit/plugins/product-plans/agents/agent-product-plans.md` — a background-mode subagent (`background: true`, `tools: Skill, Read, Write, Edit, Glob, Grep, Bash`, `maxTurns: 30`) that invokes the skill via the `Skill` tool and reports the sibling path on completion.
- Created `kit/plugins/product-plans/commands/product-plans-bg.md` — a one-liner slash command (`allowed-tools: Agent`) that fires `agent-product-plans` with `run_in_background: true` and returns an ack immediately.
- Updated `kit/plugins/product-plans/CHANGELOG.md` with a `2.1.0 — 2026-05-14` entry listing the three new surfaces and the background defaults table.
- Updated `kit/plugins/product-plans/README.md` to add a "Background mode" subsection, update the plugin structure tree, and list both new components.
- Bumped `product-plans` version from `2.0.0` to `2.1.0` (MINOR — additive command, agent, and flag; no breaking changes) in `.claude-plugin/marketplace.json`.
- Updated `CLAUDE.md` reference-implementations row for `product-plans` to reflect `Skills + Agents + Commands` and note the background-mode panel.

> CHANGELOG citation — `kit/plugins/product-plans/CHANGELOG.md`, `## 2.1.0 — 2026-05-14`: "New surfaces for unattended (background) panel execution: `--background` flag on the skill, `agent-product-plans` subagent (`background: true`, `tools: Skill, Read, Write, Edit, Glob, Grep, Bash`, `maxTurns: 30`), and `/product-plans:product-plans-bg <path>` command that fires the agent with `run_in_background: true` and returns an ack immediately."

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/product-plans/skills/product-plans/SKILL.md` | Skill instructions | Modified |
| `kit/plugins/product-plans/agents/agent-product-plans.md` | Agent definition | Created |
| `kit/plugins/product-plans/commands/product-plans-bg.md` | Command wrapper | Created |
| `kit/plugins/product-plans/CHANGELOG.md` | Version history | Modified |
| `kit/plugins/product-plans/README.md` | Plugin README | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `CLAUDE.md` | Project instructions | Modified |

## How it works

Before v2.1.0, the `product-plans` skill ran synchronously and issued two `AskUserQuestion` prompts — one for output mode (Step 2) and one for the revised-plan destination (Step 7). These prompts prevented the skill from being used in a background agent or automated pipeline.

The `--background` flag introduces a branching variable `mode` that is detected once at the top of Step 0. When `mode = background`, Step 1 skips the multi-stage plan-file fallback and requires an explicit path from `$ARGUMENTS`, stopping immediately with `Background mode requires a plan path` if none is supplied. Step 2 sets `output_mode = "review + revised plan"` without calling `AskUserQuestion`. Step 7 writes the revised plan directly to `<original-stem>-revised.md` (a sibling file that never overwrites the source) via `Write`, skipping the destination prompt. All other steps run identically to interactive mode.

The `agent-product-plans.md` subagent wraps this flag-gated skill invocation. Its `background: true` frontmatter causes Claude Code to dispatch it off the main chat thread. The tool list was widened to `Skill, Read, Write, Edit, Glob, Grep, Bash` (rather than the minimal `Skill, Read` the plan originally proposed) because subagent tool grants are not transitive across `Skill` invocations — the inner skill's `Write` and `Edit` calls would be blocked without the wider grant.

The `product-plans-bg.md` command is a thin dispatcher. It validates that `$ARGUMENTS` is non-empty, then calls the `Agent` tool with `subagent_type: "agent-product-plans"` and `run_in_background: true`, printing a one-line acknowledgement. The user gets control back immediately while the panel runs in the background.

Foreground behaviour is preserved exactly: the skill without the `--background` flag still issues both `AskUserQuestion` prompts in Step 2 and Step 7.

## How to use it

**Slash command (background mode):**
```
/product-plans:product-plans-bg docs/plans/my-feature.md
```
Returns immediately with an acknowledgement. The panel runs in the background and writes `docs/plans/my-feature-revised.md` when complete.

**Error case — no path supplied:**
```
/product-plans:product-plans-bg
```
Returns: `Background mode requires a plan path`

**Skill flag (direct background invocation):**
```
Skill: product-plans:product-plans
Args: docs/plans/my-feature.md --background
```
Suppresses both `AskUserQuestion` prompts; writes `my-feature-revised.md` as a sibling.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `5384086` | 2026-05-14 | feat(kit/plugins): add background-mode panel to product-plans (v2.1.0) |

<!-- generated:end -->

## References

- Plan: [add-background-mode-product-plans.md](plans/add-background-mode-product-plans.md)
- Related docs: [create-product-plan-review-panel-plugin.md](create-product-plan-review-panel-plugin.md), [add-domain-tools-to-product-plan-agents.md](add-domain-tools-to-product-plan-agents.md)
