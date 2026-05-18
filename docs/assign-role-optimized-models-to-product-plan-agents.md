# Assign role-optimized models to product-plan reviewer agents

> Replaces `model: inherit` with fixed per-role model assignments across all six product-plan reviewer agents — `opus` for deep-reasoning roles (Lead Developer, Security) and `sonnet` for pattern-grounded roles (PM, UX, Frontend, Accessibility) — eliminating review quality variance from parent-session model choice.

<!-- generated:start -->

**Status:** Shipped 2026-05-16  **Plan:** [assign-role-optimized-models-to-product-plan-agents.md](plans/assign-role-optimized-models-to-product-plan-agents.md)
**Type:** artifact

## What shipped

- Updated `kit/plugins/product-plans/agents/product-reviewer-lead-developer.md` — `model: inherit` → `model: opus` (architecture, feasibility, and system-level risk require open-ended multi-step technical reasoning).
- Updated `kit/plugins/product-plans/agents/product-reviewer-security-expert.md` — `model: inherit` → `model: opus` (adversarial threat modeling, multi-step attack reasoning, and regulatory analysis demand deep reasoning).
- Updated `kit/plugins/product-plans/agents/product-reviewer-pm.md` — `model: inherit` → `model: sonnet` (strategy and business-value analysis is structured and pattern-grounded).
- Updated `kit/plugins/product-plans/agents/product-reviewer-ux-designer.md` — `model: inherit` → `model: sonnet` (flows and interaction design are pattern-based judgment).
- Updated `kit/plugins/product-plans/agents/product-reviewer-frontend-engineer.md` — `model: inherit` → `model: sonnet` (component patterns, framework conventions, and performance tradeoffs are structured).
- Updated `kit/plugins/product-plans/agents/product-reviewer-accessibility-expert.md` — `model: inherit` → `model: sonnet` (WCAG 2.2 AA checking plus semantic/focus-management judgment is pattern-grounded).
- Updated `.claude-plugin/marketplace.json` — `product-plans` version bumped from `3.2.0` to `3.2.1` (patch).
- Updated `kit/plugins/product-plans/CHANGELOG.md` with a 3.2.1 entry describing the model assignments.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/product-plans/agents/product-reviewer-lead-developer.md` | Agent definition | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-security-expert.md` | Agent definition | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-pm.md` | Agent definition | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-ux-designer.md` | Agent definition | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-frontend-engineer.md` | Agent definition | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-accessibility-expert.md` | Agent definition | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |
| `kit/plugins/product-plans/CHANGELOG.md` | Changelog | Modified |

## How it works

Before this change, all six reviewer agents used `model: inherit`, meaning each reviewer ran on whatever model the parent session happened to use. A panel invoked from a Haiku session would produce shallow analysis from roles like Lead Developer and Security that demand deep, adversarial reasoning, while an Opus session would over-spend on reviewers whose work is largely pattern matching against known frameworks and standards.

The classification used two axes: reasoning depth (does the discipline require multi-step, adversarial, or open-ended architectural reasoning?) and pattern grounding (is the work largely a structured check against established standards or familiar tradeoffs?). Roles on the deep-reasoning end were assigned `opus`; roles on the pattern-grounded end were assigned `sonnet`. No reviewer was assigned `haiku` because every reviewer still needs to interpret a free-form plan and produce structured judgment.

The panel orchestrator `agent-product-plans` was deliberately left unchanged — it already ran on `sonnet`, which is appropriate for orchestration and file editing across a panel run. The separate `plan-documenter` agent in `kit/plugins/plan-interview/agents/` was also out of scope and already ran on `sonnet`.

The practical trade-off is that two reviewers now always run on `opus` regardless of the parent session model, making panels more expensive than the previous best case but consistently high quality. Users who want a fast, cheaper pass would need to manually override the `model` field in the agent files or invoke the agents individually. This is an intentional design choice: review quality should not silently degrade based on the caller's model tier.

The version bump is a patch (3.2.0 → 3.2.1) because the behavioral change is internal — the public interface (invocation syntax, output format, section structure) is unchanged. The only observable difference is deeper and more consistent analysis from the Lead Developer and Security reviewers.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `44dc02f` | 2026-05-17 | docs(sweep): mark 18 completed plans as artifact and generate initial docs |
| `865eb2b` | 2026-05-16 | fix(docs/plans): correct plan frontmatter and orchestrator misattribution |
| `4b11fe6` | 2026-05-16 | fix(kit/plugins/product-plans): assign role-optimized models to reviewer agents (v3.2.1) |

<!-- generated:end -->

## References

- Plan: [assign-role-optimized-models-to-product-plan-agents.md](plans/assign-role-optimized-models-to-product-plan-agents.md)
