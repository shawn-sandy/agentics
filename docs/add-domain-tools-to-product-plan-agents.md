# Add Domain-Specific Tools to Product-Plan Reviewer Agents

> Gives each of the six product-plan reviewer agents at least one domain-specific research tool (WebSearch and/or WebFetch) so findings are grounded in cited evidence rather than assertion alone (v3.2.0).

<!-- generated:start -->

**Status:** Shipped 2026-05-15  **Plan:** [add-domain-tools-to-product-plan-agents.md](plans/add-domain-tools-to-product-plan-agents.md)
**Type:** artifact

## What shipped

- Added `WebSearch` and `WebFetch` to `product-reviewer-ux-designer.md` — enables lookup of Apple HIG, Material Design 3, Fluent, and Nielsen's 10 Usability Heuristics; requires citations in output.
- Added `WebSearch` to `product-reviewer-lead-developer.md` — enables research of technology tradeoffs, library alternatives, and ecosystem maturity; `Bash` stays restricted to `git *` to prevent prompt-injection risk.
- Added `WebSearch` and `WebFetch` to `product-reviewer-security-expert.md` — enables OWASP Top 10, CVE/NVD advisories, CWE definitions, and compliance regulation lookups (GDPR, HIPAA, CCPA, PCI-DSS); requires CWE and OWASP cheat sheet citations in every vulnerability finding.
- Added `WebSearch` to `product-reviewer-frontend-engineer.md` — enables browser compatibility (MDN), framework performance patterns, and bundle-size benchmark research; `Bash` stays restricted to `git *` for the same injection-safety reason as the Lead Developer.
- Added `WebSearch` and `WebFetch` to `product-reviewer-accessibility-expert.md` — enables retrieval of WCAG 2.2 Understanding documents from w3.org and ARIA APG design patterns; requires primary-source citations in every WCAG finding.
- Added `WebSearch` and `WebFetch` to `product-reviewer-pm.md` — enables competitive landscape, industry benchmark, and market context research; requires sourced evidence for market claims.
- Updated `kit/plugins/product-plans/CHANGELOG.md` with a `3.2.0 — 2026-05-15` entry covering all six agent changes.
- Bumped `product-plans` version from the prior value to `3.2.0` in `.claude-plugin/marketplace.json` (MINOR — additive tool grants, no breaking changes).

> CHANGELOG citation — `kit/plugins/product-plans/CHANGELOG.md`, `## 3.2.0 — 2026-05-15`: Lists all six agents with their added tools; e.g. "product-reviewer-security-expert — added `WebSearch`, `WebFetch` for OWASP Top 10, CVE/NVD advisories, CWE definitions, and compliance regulation."

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/product-plans/agents/product-reviewer-ux-designer.md` | Agent definition | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-lead-developer.md` | Agent definition | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-security-expert.md` | Agent definition | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-frontend-engineer.md` | Agent definition | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-accessibility-expert.md` | Agent definition | Modified |
| `kit/plugins/product-plans/agents/product-reviewer-pm.md` | Agent definition | Modified |
| `kit/plugins/product-plans/CHANGELOG.md` | Version history | Modified |
| `.claude-plugin/marketplace.json` | Marketplace entry | Modified |

## How it works

Before v3.2.0, all six reviewer agents shared the same read-only tool set: `Read, Glob, Grep, Bash(git *)`. This meant every finding was based solely on static analysis of the plan text and the local codebase — agents could not cite authoritative guidelines, check CVE databases, or verify whether a claimed browser compatibility issue was real.

The change extends each agent's `tools` frontmatter field with the web-access tools appropriate to its domain. The principle is that every factual claim in a review should be backed by a link, not an assertion: "this violates platform conventions" becomes "this violates [Apple HIG guideline, linked]"; "this is a security risk" becomes "this matches CWE-79 [OWASP Cheat Sheet, linked]"; "this fails accessibility" becomes "this fails SC 1.4.3 Contrast Minimum [w3.org Understanding doc, linked]."

Two agents — Lead Developer and Frontend Engineer — received only `WebSearch` rather than the full `WebSearch` + `WebFetch` pair. This reflects the prompt-injection safety rationale: both agents process untrusted plan text as input. Restricting `Bash` to `git *` and omitting `WebFetch` reduces the surface area for an adversarial plan to exfiltrate data or trigger side effects via fetched URLs. Codebase inspection for both agents continues to use the existing `Read` and `Glob` tools.

The three agents that deal with live specifications — UX Designer (HIG/Material Design), Security Expert (CVE/NVD), and Accessibility Expert (WCAG w3.org) — received both `WebSearch` and `WebFetch` because their primary sources require retrieving full documents, not just search results. The PM agent similarly needs `WebFetch` to pull market research articles and competitor pages.

The tool grant changes are confined to each agent's `tools:` frontmatter line; the review workflow instructions were also updated to specify citation requirements so the new tools are used purposefully rather than opportunistically.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `bf67a43` | 2026-05-15 | feat(kit/plugins/product-plans): add domain-specific research tools to all six reviewer agents (v3.2.0) |

<!-- generated:end -->

## References

- Plan: [add-domain-tools-to-product-plan-agents.md](plans/add-domain-tools-to-product-plan-agents.md)
- Related docs: [create-product-plan-review-panel-plugin.md](create-product-plan-review-panel-plugin.md), [add-background-mode-product-plans.md](add-background-mode-product-plans.md)
