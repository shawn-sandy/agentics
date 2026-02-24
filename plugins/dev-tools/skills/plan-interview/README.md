# plan-interview Skill

Stress-tests implementation plans through a structured multi-round interview before coding begins. Surfaces risks across technical trade-offs, UX/accessibility, and edge cases — without approving or signing off on the plan.

## Overview

The `plan-interview` skill reads a plan file, assesses its scope, and conducts 1–3 rounds of focused questions using `AskUserQuestion`. After the interview, it presents a structured summary and optionally appends it to the plan file.

## Activation

**Phrases that activate the skill:**
```
"Stress-test this plan"
"Interview my plan"
"Find gaps in this plan"
"Critique this plan"
"Validate my plan"
"What risks am I missing?"
```

**NOT intended for:**
```
"Does this plan look good?"     → (approval request, not a stress-test)
"Can I proceed with this plan?" → (sign-off request)
"Is this plan ready?"           → (approval request)
```

The skill surfaces risks — it does not approve plans.

## Plan File Resolution

The skill locates the plan file using this 5-step priority order:

1. **Explicit path in your message** — if you include a file path, it is read directly
2. **Currently open `.md` file** — if the file looks like a plan (contains headings like `## Implementation`, `## Steps`, `## Plan`), it is used
3. **Project config override** — `plansDirectory` key in `.claude/settings.json` → most recently modified `.md` file
4. **Global config** — `plansDirectory` key in `~/.claude/settings.json` → most recently modified `.md` file
5. **Default fallback** — most recently modified file in `~/.claude/plans/*.md`

The skill tells you which file it will use before proceeding. If no file is found, it stops and asks.

## Interview Rounds

The number of rounds depends on plan scope and whether the plan involves UI:

| Round | Name | When it runs |
|-------|------|-------------|
| **R1** | Technical & Trade-offs | Always |
| **R2a** | UI/UX & Flows | Medium/complex plans, or any plan with UI signals |
| **R2b** | Accessibility & Semantic Structure | Immediately after R2a whenever R2 runs |
| **R3** | Edge Cases & Best Practices | Complex/multi-area plans only |

**Scope thresholds:**
- **Short/focused** (1–2 files, single concern) → 1 round (R1 only)
- **Medium** (feature with UI + logic) → 2 rounds (R1 + R2a + R2b)
- **Complex/multi-area** (architecture, cross-cutting, 3+ domains) → 3 rounds (R1 + R2a + R2b + R3)

**UI signals that always trigger Round 2**, even on short plans:
- Framework keywords: React, Vue, Svelte, Angular
- HTML/CSS terms: `className`, `style`, Tailwind, styled-components
- File types: `.tsx`, `.jsx`, `.css`, `.scss`, `.html`
- UX terminology: button, modal, form, dialog, dropdown, layout, page, component

### What Each Round Covers

**Round 1 — Technical & Trade-offs:**
- The most uncertain architectural or implementation decision
- Build vs. buy, library choice, or API design trade-offs
- Performance, scalability, or data model concerns
- Unclear integration points or dependencies

**Round 2a — UI/UX & Flows:**
- Happy path, error states, loading states, empty states
- Mobile or responsive behavior
- Motion and animation (`prefers-reduced-motion`, focus indicators)
- UI states not covered by the plan (skeleton loading, optimistic updates)

**Round 2b — Accessibility & Semantic Structure:**
- Keyboard navigation, focus order, focus trapping (modals/dialogs)
- Screen reader support: ARIA roles, labels, live regions
- WCAG 2.1 AA: color contrast (4.5:1 text, 3:1 UI), touch targets (44×44px)
- Semantic HTML: heading hierarchy, landmark regions, form label association

**Round 3 — Edge Cases & Best Practices:**
- Critical failure modes and race conditions
- Concurrent user scenarios and data conflicts
- Regression risks: existing tests, API contracts, backward compatibility
- Security, performance, test coverage, and DX best practices

## Output Format

After all rounds, the skill presents a structured summary:

```markdown
## Plan Interview Summary

### Key Decisions Confirmed
[Decisions the user confirmed or clarified during the interview]

### Open Risks & Concerns
[Risks, unknowns, or concerns surfaced — with brief context]

### Recommended Next Steps
[Amendments to the plan, spikes needed, or clarifications before implementation]

### Simplification Opportunities
[Areas where the plan can be reduced in scope or abstraction, with simpler alternatives]
```

If the skill detects concerns outside the structured rounds (missing rollback strategy, ownership gaps, implicit assumptions), these appear in an **Additional Concerns** section before the summary. If it finds over-engineered elements, they appear in a **Complexity Concerns** section with simpler alternatives.

## Opt-in: Save Findings

After the summary, the skill asks:

> "Would you like me to append this interview summary to the plan file?"

It **does not write to disk** without your explicit confirmation. If confirmed, the summary is appended as a new `## Interview Summary` section at the end of the plan file.

## Scope

- Surfaces risks and gaps — does not approve or reject plans
- Reviews the resolved plan file only — does not scan the entire project
- Generates questions dynamically from the plan content — no generic or hardcoded questions
- Does not modify the plan file without explicit confirmation

## Tips

**What makes a plan well-suited for interviewing:**
- Has a clear goal statement and scope boundary
- Lists specific files, components, or services involved
- Names the tech stack and key dependencies
- Flags known open questions or trade-offs

**What produces the most useful interviews:**
- Plans with specific implementation details (not just high-level intentions)
- Plans that name the frameworks and libraries being used (triggers appropriate UI/a11y rounds)
- Plans with at least 3–5 implementation steps (gives the skill enough to probe)
