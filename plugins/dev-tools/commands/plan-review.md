---
description: Review a plan and interview the user about technical implementation, trade-offs, UI/UX concerns, edge cases, and best practices
---

# Plan Review Command

Read the plan provided in $ARGUMENTS (a file path, URL, or inline text) and conduct a structured interview with the user to stress-test it. Use the **AskUserQuestion tool** for every question — do not ask questions as plain text in your response.

If no plan is provided via $ARGUMENTS, ask the user to provide one before proceeding.

## Interview Process

Work through each review dimension **one at a time**. For each dimension, read the relevant parts of the plan, identify gaps or concerns, and ask **1–2 focused questions** using AskUserQuestion before moving to the next.

Do not rush. Wait for the user's answer before proceeding to the next question.

### Dimension 1: Technical Implementation

Identify the core technical approach described in the plan and probe:

- Are the chosen technologies, frameworks, or patterns appropriate for the requirements?
- Are there unstated assumptions about infrastructure, dependencies, or environment?
- Is the implementation sequence logical — are there dependency ordering issues?
- Are integration points between components clearly defined?

### Dimension 2: Trade-offs

Surface the implicit trade-offs in the plan and ask the user to weigh in:

- What is being prioritized (speed, correctness, simplicity, scalability)?
- What alternatives were considered and why were they rejected?
- Are there cost, performance, or complexity trade-offs that deserve explicit acknowledgment?
- Does the plan over-engineer or under-engineer for the stated goals?

### Dimension 3: UI/UX Concerns

If the plan involves any user-facing surface, probe:

- How will users discover and learn this feature?
- What happens when things go wrong — are error states and empty states designed?
- Is the interaction model consistent with existing patterns in the product?
- Are accessibility, responsiveness, and loading states accounted for?

If the plan is purely backend or infrastructure, briefly confirm with the user that there are no user-facing implications, then move on.

### Dimension 4: Edge Cases

Look for scenarios the plan may not address:

- What happens with empty, null, or malformed input?
- How does the system behave under high load, concurrent access, or network failure?
- Are there permission, authorization, or multi-tenancy boundaries that could be crossed?
- What happens if an external dependency is unavailable or returns unexpected data?

### Dimension 5: Best Practices

Evaluate the plan against engineering best practices:

- Is the approach testable — can the key behaviors be verified with automated tests?
- Does the plan include observability (logging, metrics, alerting)?
- Is there a rollback or migration strategy?
- Does it follow the codebase's existing conventions and patterns?

## Question Style Guidelines

When composing AskUserQuestion options:

- Frame options as concrete choices, not vague directions
- Include a "This is already addressed" option when the plan may already cover the concern
- Include a "Not applicable / skip" option when the dimension may not be relevant
- Keep option labels short (1–5 words) with descriptions that explain the implications
- Ask a maximum of 2 questions per dimension to avoid fatigue

## Wrap-Up

After all five dimensions have been covered, provide a brief summary:

1. **Key decisions made** — choices the user confirmed during the interview
2. **Open items** — concerns that were flagged but not yet resolved
3. **Recommended next steps** — concrete actions to strengthen the plan

Keep the summary concise. Do not repeat the entire plan back to the user.
