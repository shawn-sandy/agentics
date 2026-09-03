# How do I... wcag-compliance-reviewer

Audits HTML, CSS, and React/TypeScript code for WCAG 2.2 Level AA accessibility violations and supplies the fix for each one.

Install: `/plugin marketplace add shawn-sandy/agentics`, then `/plugin install wcag-compliance-reviewer@agentics-kit`

## wcag-compliance-reviewer

Reviews code against the four WCAG principles and returns each violation with the failing snippet, the success criterion, and corrected code.

- **Command** — `/wcag-compliance-reviewer:wcag-compliance-reviewer [file or directory]`
- **Say it instead** — "check this component for accessibility issues"
- **What happens** — Reads the target files, optionally runs the bundled `wcag-check <path>` static scanner, and prints an Accessibility Review Summary with errors, warnings, recommendations, testing advice, and quick wins. Defaults to the bundled WCAG 2.2 AA reference; ask for "the latest W3C guidelines" and it fetches from w3.org instead.
- **Watch out** — Contrast ratios and touch-target sizes must be measured — from a running page via the browser MCP, or computed from resolved values with `python3` — never read off source CSS; `wcag-check` catches roughly 30% of issues and its "potential contrast issue" line is a prompt to measure, not a measurement.
