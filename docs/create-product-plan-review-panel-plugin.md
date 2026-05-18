# Create the `product-plan-review-panel` plugin

> Ships a new plugin with one auto-activating skill that orchestrates an Agent Team of five specialist subagents to review a product plan and produce a consolidated 14-section report plus an optional revised plan.

<!-- generated:start -->

**Status:** Shipped 2026-05-14  **Plan:** [create-product-plan-review-panel-plugin.md](plans/create-product-plan-review-panel-plugin.md)
**Type:** artifact

## What shipped

- Created the `product-plan-review-panel` plugin at `kit/plugins/product-plan-review-panel/` with plugin manifest, README, and CHANGELOG (initial v1.0.0 entry).
- Wrote the `product-plan-review-panel` skill at `skills/product-plan-review-panel/SKILL.md` — auto-activates on review-related prompts and orchestrates the full Agent Team workflow in Steps 0–8.
- Created `references/role-prompts.md` containing per-role spawn-prompt templates (one section per reviewer) with the 9-item output schema and "do not message the lead mid-review" rule, keeping SKILL.md under the 500-line cap.
- Created `references/output-template.md` with the verbatim 14-section final-report template the lead reproduces, including explicit `Reviewer unavailable` handling in sections 1, 2, and 3.
- Wrote five teammate-only subagent definitions under `agents/`: `product-reviewer-pm.md`, `product-reviewer-lead-developer.md`, `product-reviewer-ux-designer.md`, `product-reviewer-frontend-engineer.md`, `product-reviewer-accessibility-expert.md` — each scoped to `tools: Read, Glob, Grep, Bash(git *)`.
- Registered the plugin in `.claude-plugin/marketplace.json` and bumped the marketplace top-level version from `3.3.0` → `3.4.0` (MINOR — new plugin added, `category: "productivity"`).
- Note: the plugin was subsequently renamed to `product-plans` in v2.0.0 (separate plan); this plan documents the v1.0.0 creation.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/product-plan-review-panel/.claude-plugin/plugin.json` | Plugin manifest | Created |
| `kit/plugins/product-plan-review-panel/README.md` | Plugin documentation | Created |
| `kit/plugins/product-plan-review-panel/CHANGELOG.md` | Version history | Created |
| `kit/plugins/product-plan-review-panel/skills/product-plan-review-panel/SKILL.md` | Skill instructions | Created |
| `kit/plugins/product-plan-review-panel/skills/product-plan-review-panel/references/role-prompts.md` | Role spawn-prompt templates | Created |
| `kit/plugins/product-plan-review-panel/skills/product-plan-review-panel/references/output-template.md` | 14-section output template | Created |
| `kit/plugins/product-plan-review-panel/agents/product-reviewer-pm.md` | PM reviewer subagent | Created |
| `kit/plugins/product-plan-review-panel/agents/product-reviewer-lead-developer.md` | Lead developer reviewer subagent | Created |
| `kit/plugins/product-plan-review-panel/agents/product-reviewer-ux-designer.md` | UX designer reviewer subagent | Created |
| `kit/plugins/product-plan-review-panel/agents/product-reviewer-frontend-engineer.md` | Frontend engineer reviewer subagent | Created |
| `kit/plugins/product-plan-review-panel/agents/product-reviewer-accessibility-expert.md` | Accessibility expert reviewer subagent | Created |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `docs/plans/create-product-plan-review-panel-plugin.md` | Plan file | Modified |

## How it works

The skill resolves the target plan file using a priority chain: an explicit path in the user message, the open IDE file, the project `plansDirectory`, the global `plansDirectory`, and finally `~/.claude/plans/*.md`. Once the path is confirmed, it asks the user whether to produce "Review only" or "Review + revised plan" before doing anything else.

Before spawning the team the skill verifies two prerequisites: it runs `claude --version`, parses the output with `^(\d+)\.(\d+)\.(\d+)` (ignoring pre-release suffixes), and confirms `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set. If either check fails the skill surfaces the exact enablement steps from the Agent Teams docs and stops — there is no in-prompt fallback in v1.0.0.

The team spawn is expressed as a verbatim natural-language directive embedded in Step 4 of SKILL.md. The lead session executes it literally: all five teammates are spawned immediately in parallel, each briefed with the matching section from `references/role-prompts.md` and the absolute path to the plan file. Each reviewer operates independently — reviewers are explicitly instructed not to message the lead mid-review and to file ambiguities under "Unclear" in their own findings.

The five subagent files under `agents/` each use standard Claude Code subagent frontmatter with `tools: Read, Glob, Grep, Bash(git *)`. Their body definitions enforce independent review, the 9-item output schema (Works well / Unclear / Critical / Minor / Missing / Risks / Improvements / Questions / Approval status), and an explicit `Approval status: approve | approve with changes | reject` line. The "teammate-only" scope is stated in both the frontmatter description and the README — standalone invocation is not supported in v1.0.0.

If any reviewer goes idle or errors, the lead respawns it once with the same role prompt. If it errors again, that role's section is marked `Reviewer unavailable — not assessed`; this status must surface in three places: the Executive Summary, the role's section in the role-by-role review, and the Highest-Risk Issues list. The gap therefore cannot be missed in the final report.

After all five findings arrive, the lead synthesizes them using the verbatim 14-section template in `references/output-template.md`. Section 14 is the revised plan itself; when the user chose "Review + revised plan", Step 7 serializes section 14 to disk without regenerating it. The user is asked to choose a destination: a sibling file (`<original-stem>-revised.md`), an overwrite of the original (blocked unless `git status --porcelain` shows the source is clean), or an in-place append as a new `## Revised Plan` section. Step 8 issues `"Clean up the team"` to the lead per the Agent Teams docs warning about cleanup responsibility.

The plugin was registered in `.claude-plugin/marketplace.json` as `category: "productivity"` — an intentional tradeoff accepted during the plan interview, as no other plugin at the time used that category. The marketplace top-level version moved to `3.4.0` to reflect the MINOR addition of a new plugin.

## How to use it

Load the plugin and invoke naturally:

```bash
claude --plugin-dir ./kit/plugins/product-plan-review-panel
```

Then in a session, ask: "Review this product plan" or "Stress-test the plan at docs/plans/my-plan.md". The skill auto-activates on review, critique, validate, stress-test, harden, or prepare verbs applied to a plan, PRD, feature proposal, UX flow, technical plan, or implementation plan.

Requires `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` to be set. The skill will display enablement instructions and stop if the flag is missing.

Install from the marketplace:

```bash
/plugin install product-plan-review-panel@agentics-kit
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `918fe46` | 2026-05-14 | feat(kit/plugins): add product-plan-review-panel plugin v1.0.0 (#119) |

<!-- generated:end -->

## References

- Plan: [create-product-plan-review-panel-plugin.md](plans/create-product-plan-review-panel-plugin.md)
