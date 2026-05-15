---
status: completed
type: feature
created: 2026-05-15
modified: 2026-05-15
---

# Add Domain-Specific Tools to Product-Plan Reviewer Agents

## Goal

Each of the six product-plan reviewer agents previously had only read-only file
tools (`Read, Glob, Grep, Bash(git *)`). The goal is to give every agent at
least one tool dedicated to their domain so reviews are grounded in evidence —
authoritative guidelines, live market data, the actual codebase — rather than
assertion alone.

## Changes

### product-reviewer-ux-designer

**Added:** `WebSearch`, `WebFetch`

Use case: look up platform Human Interface Guidelines (Apple HIG, Material
Design 3, Fluent), Nielsen's 10 Usability Heuristics, and interaction
conventions. Require citations in output so "this violates platform conventions"
becomes "this violates [specific guideline, linked]."

### product-reviewer-lead-developer

**Added:** `WebSearch`

Use case: look up technology tradeoffs, library alternatives, known scaling
limits, and ecosystem maturity when the plan makes specific technology choices.
Codebase inspection (`package.json`, `go.mod`, config files) uses the existing
`Read` + `Glob` tools. `Bash` stays restricted to `git *` — unrestricted shell
access on agents that ingest untrusted plan text creates a prompt-injection risk
that advisory instructions cannot enforce.

### product-reviewer-security-expert

**Added:** `WebSearch`, `WebFetch`

Use case: look up OWASP Top 10 guidance, CVE/NVD advisories for named
libraries, CWE definitions, and compliance regulation (GDPR, HIPAA, CCPA,
PCI-DSS). Require citations in output so every vulnerability finding names
the CWE and links the OWASP cheat sheet.

### product-reviewer-frontend-engineer

**Added:** `WebSearch`

Use case: research browser compatibility (MDN), framework performance patterns,
bundle-size benchmarks, and ecosystem alternatives. Dependency and config
inspection (`package.json`, `tsconfig.json`, bundler/lint configs) uses the
existing `Read` + `Glob` tools. `Bash` stays restricted to `git *` for the
same prompt-injection safety reason as the Lead Developer.

### product-reviewer-accessibility-expert

**Added:** `WebSearch`, `WebFetch`

Use case: retrieve WCAG 2.2 Understanding documents from w3.org, ARIA APG
design patterns, and AT compatibility notes. Require primary-source citations
(w3.org) in every WCAG finding so "this fails SC 1.4.3" becomes "this fails
SC 1.4.3 Contrast Minimum [link to Understanding doc]."

### product-reviewer-pm

**Added:** `WebSearch`, `WebFetch`

Use case: research the competitive landscape, industry benchmarks, and market
context to stress-test business assumptions in the plan. Require evidence:
"comparable products do X" backed by a source, not just asserted.

## Files Changed

- `kit/plugins/product-plans/agents/product-reviewer-ux-designer.md`
- `kit/plugins/product-plans/agents/product-reviewer-lead-developer.md`
- `kit/plugins/product-plans/agents/product-reviewer-security-expert.md`
- `kit/plugins/product-plans/agents/product-reviewer-frontend-engineer.md`
- `kit/plugins/product-plans/agents/product-reviewer-accessibility-expert.md`
- `kit/plugins/product-plans/agents/product-reviewer-pm.md`
- `kit/plugins/product-plans/CHANGELOG.md` — version 3.2.0 entry
- `.claude-plugin/marketplace.json` — version bumped to 3.2.0
