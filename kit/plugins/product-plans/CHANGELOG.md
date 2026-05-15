# Changelog

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
