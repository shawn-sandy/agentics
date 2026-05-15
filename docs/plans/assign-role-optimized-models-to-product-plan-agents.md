# Assign role-optimized models to product-plan reviewer agents

**Status:** completed
**Plugin:** product-plans
**Version bump:** 3.2.0 → 3.2.1 (patch)

## Problem

All six product-plan reviewer agents used `model: inherit`, so each
reviewer's model was determined by whatever model the parent session
happened to be running. That made review quality inconsistent: a panel
fired from a Haiku session would get shallower analysis from disciplines
that demand deep reasoning (Lead Developer, Security), while a panel
fired from an Opus session would over-spend on reviewers whose work is
pattern-driven and well-suited to Sonnet.

The goal: pick the right model per reviewer based on the cognitive
demands of the role, and remove the inheritance dependency.

## Approach

Reviewed each reviewer agent's description and Review Scope and
classified the work along two axes:

- **Reasoning depth** — does the discipline require multi-step,
  adversarial, or open-ended architectural reasoning?
- **Pattern grounding** — is the discipline largely a structured check
  against known standards, established patterns, or familiar tradeoffs?

Deep-reasoning roles → `opus`. Pattern-grounded analytical roles →
`sonnet`. No reviewer was assigned `haiku` because every reviewer still
needs to interpret a free-form plan and produce structured judgment.

## Assignments

| Reviewer | Model | Rationale |
|---|---|---|
| product-reviewer-lead-developer | opus | Architecture, feasibility, system-level risk — open-ended technical reasoning over the full stack |
| product-reviewer-security-expert | opus | Adversarial threat modeling, multi-step attack reasoning, regulatory analysis |
| product-reviewer-pm | sonnet | Strategy and business-value analysis — structured, balanced reasoning |
| product-reviewer-ux-designer | sonnet | Flows, usability, interaction design — pattern-based judgment |
| product-reviewer-frontend-engineer | sonnet | Component patterns, framework conventions, performance tradeoffs |
| product-reviewer-accessibility-expert | sonnet | WCAG 2.2 AA checking plus semantic/focus-management judgment |

The two orchestrator agents (`agent-product-plans`, `plan-documenter`)
already had `model: sonnet` and were left unchanged — `sonnet` is the
right tier for orchestration and file editing across the panel.

## Files Changed

- `kit/plugins/product-plans/agents/product-reviewer-lead-developer.md`
  — `inherit` → `opus`
- `kit/plugins/product-plans/agents/product-reviewer-security-expert.md`
  — `inherit` → `opus`
- `kit/plugins/product-plans/agents/product-reviewer-pm.md`
  — `inherit` → `sonnet`
- `kit/plugins/product-plans/agents/product-reviewer-ux-designer.md`
  — `inherit` → `sonnet`
- `kit/plugins/product-plans/agents/product-reviewer-frontend-engineer.md`
  — `inherit` → `sonnet`
- `kit/plugins/product-plans/agents/product-reviewer-accessibility-expert.md`
  — `inherit` → `sonnet`
- `.claude-plugin/marketplace.json` — version 3.2.0 → 3.2.1
- `kit/plugins/product-plans/CHANGELOG.md` — added 3.2.1 entry

## Trade-offs

- Two reviewers now run on `opus`, which is more expensive per panel
  invocation than the previous worst case where every reviewer inherited
  a single (often cheaper) model. The benefit is consistently deeper
  technical and security analysis regardless of where the panel is
  invoked from.
- Hard-coding models removes parent-session control. If a user wants
  every reviewer on Haiku for a fast pass, they would now need to edit
  the agents or override at the harness level. This trade-off is
  intentional: reviewer quality should not silently degrade based on the
  caller's model choice.
