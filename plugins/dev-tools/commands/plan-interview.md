---
description: Stress-test a plan with a structured interview across technical, UX, edge case, and out-of-scope domains
argument-hint: [plan-file-path] - omit to auto-detect from IDE or ~/.claude/plans/
allowed-tools: Read, Glob, AskUserQuestion, Write, Edit
---

<!-- Synced with: ~/.claude/skills/plan-interview/SKILL.md — keep both files in sync -->

# /plan-interview

Stress-test a plan through a structured conversational interview before implementation begins.

## Usage

```
/plan-interview                                        # auto-detects from IDE or latest in ~/.claude/plans/
/plan-interview ~/.claude/plans/my-feature.md          # use a specific plan file
```

## Instructions

### Step 1 — Resolve the plan file

Use the first match from this priority order:

1. **Explicit argument**: If `$ARGUMENTS` is provided, treat it as the file path and read it directly.
2. **Currently open file**: If no argument is given, check whether a file is currently open or selected in the IDE (provided via context). If it exists, is a `.md` file, and its content looks like a plan (contains headings like `## Implementation`, `## Plan`, `## Steps`, `## Instructions`, or similar structural markers), use it.
3. **Project-level settings**: Read `.claude/settings.json` in the current project directory. If a `"plansDirectory"` key exists, glob `*.md` files from that path and use the most recently modified file. This takes precedence over the global config in step 4.
4. **Latest plan in `~/.claude/plans/`**: If none of the above applies, use `Glob` on `~/.claude/plans/*.md`, sort by modification time, and select the most recently modified file.

Once resolved, tell the user which file will be used (e.g., "Interviewing plan: `~/.claude/plans/my-feature.md`") before proceeding.

If no plan file can be found via any of these methods, tell the user and stop.

### Step 2 — Read and analyze the plan

Read the resolved plan file. Extract the following to guide question generation:

- **Goal**: What is being built and why?
- **Key components**: What files, services, or systems are involved?
- **Tech stack**: Languages, frameworks, libraries, APIs
- **Scope**: Is this a focused change, a medium-sized feature, or a complex multi-area effort?
- **UI involvement**: Does the plan reference components, pages, forms, styles, or HTML? (Used to determine whether Round 2 runs regardless of scope.)
- **Open questions**: Any unresolved questions listed in the plan?

Also extract **complexity signals** from the plan:

- Multiple new abstractions or layers (factories, registries, adapters, base classes) introduced for a focused task
- Third-party libraries proposed for tasks covered by native APIs or the standard library
- Custom implementations of patterns the framework or language already provides
- Premature optimization signals (caching, queuing, batching) without stated scale requirements
- More than 3 new files proposed for a single-concern change
- Complex state management (Redux, Zustand, XState) proposed for local or ephemeral state

Use the scope assessment to determine how many interview rounds to conduct:

- **Short/focused plan** (single concern, 1–2 files): 1 round
- **Medium plan** (feature with UI + logic): 2 rounds
- **Complex/multi-area plan** (architecture, cross-cutting concerns, 3+ domains): 3 rounds

After scope assessment, also check for **UI involvement**: look for any of the following signals in the plan:

- Framework keywords: React, Vue, Svelte, Angular, or similar component-based UI libraries
- HTML/CSS terms: `className`, `style`, CSS, Tailwind, styled-components, or similar
- File types: `.tsx`, `.jsx`, `.css`, `.scss`, `.html`
- UX terminology: button, modal, form, dialog, dropdown, input, layout, page, screen, component

If any UI signals are detected, always include Round 2 — even for plans classified as short/focused. When triggering Round 2 on a short plan, briefly note what was detected (e.g., "Running Round 2 — plan references React components and `.tsx` files") so the user understands why.

### Step 3 — Conduct the structured interview

Generate questions dynamically from the plan content — do not use generic or hardcoded questions. Each `AskUserQuestion` call may include up to 4 questions.

**Round 1 — Technical & Trade-offs** (always run):

Ask up to 4 questions covering:

- The most uncertain architectural or implementation decision in the plan
- Build vs. buy, library choice, or API design trade-offs
- Performance, scalability, or data model concerns specific to this plan
- Any unclear integration points or dependencies

Use `multiSelect: true` for questions where the user may want to flag multiple concerns (e.g., "Which of these areas need more investigation?").

**Round 2a — UI/UX & Flows** (run for medium and complex plans, or any plan with UI involvement — see Step 2):

Ask up to 4 questions covering:

- User flows: happy path, error states, loading states, empty states
- Mobile or responsive behavior concerns
- Motion and animation: `prefers-reduced-motion`, transitions, focus indicators after animation
- Any UI state not covered by the plan (e.g., skeleton loading, optimistic updates, error recovery)

**Round 2b — Accessibility & Semantic Structure** (run immediately after Round 2a when Round 2 is triggered):

Ask up to 4 questions covering:

- Keyboard navigation, focus order, focus trapping (modals/dialogs), skip-nav links
- Screen reader support: ARIA roles, labels, `aria-describedby` for errors, live regions
- WCAG 2.1 AA compliance: color contrast (4.5:1 text, 3:1 UI), touch targets (44×44px min)
- Semantic HTML: heading hierarchy, landmark regions, form label association

**Round 3 — Edge Cases & Best Practices** (run for complex plans only):

Ask up to 4 questions covering:

- Critical failure modes or race conditions
- Concurrent user scenarios or data conflicts
- Regression risks: which existing tests might break, what backward-compatibility contracts exist (API shape, component props, data schema), and whether visual or behavioral regression testing is in place
- Which best practices should guide implementation: security, performance, test coverage, DX
- Any remaining open questions from the plan that haven't been addressed

### Step 4 — Surface out-of-scope concerns

After the structured rounds, review the full plan one more time and identify any issues that were not covered by the interview questions. These are concerns you observed independently — not topics already raised by the user. Look for:

- Missing sections a plan of this type would normally include (e.g., rollback strategy, auth/permissions, data migration, monitoring)
- Implicit assumptions in the plan that could silently break implementation
- Ownership or responsibility gaps (who handles what is unclear)
- Naming, scope, or intent ambiguities that could cause misalignment during implementation
- Risks that fall outside the Technical / UI / Edge Case domains
- Regression blind spots: the plan does not identify which existing tests, API contracts, or user-visible behaviors could break

If any out-of-scope concerns exist, present them as a clearly labelled section in the chat before the summary:

```markdown
### Additional Concerns (Outside Structured Rounds)

- [Concern 1]: [Brief explanation of why this matters]
- [Concern 2]: [Brief explanation of why this matters]
```

If no additional concerns exist, skip this section silently.

**Complexity Check** (always run):

After the out-of-scope scan, evaluate the proposed approach against what the simplest working solution would look like. For each element that appears over-engineered, ask: *Could a built-in, a single function, or a native API replace this abstraction?* Only surface real issues — do not flag complexity for its own sake on genuinely complex plans. Only name a simpler alternative when one is clearly apparent; omit concerns where no obvious alternative exists.

If any complexity concerns are found, present them under a clearly labelled section:

```markdown
### Complexity Concerns

- [Over-engineered element]: [Why it's unnecessary] — Simpler alternative: [specific suggestion]
```

Skip this section silently if no complexity concerns are found.

### Step 5 — Compile and present the review summary

After all rounds and the out-of-scope check are complete, output a structured summary in the chat:

```markdown
## Plan Interview Summary

### Key Decisions Confirmed
[List decisions the user confirmed or clarified during the interview]

### Open Risks & Concerns
[List risks, unknowns, or concerns surfaced — with brief context]

### Recommended Next Steps
[Amendments to the plan, additional spikes, or clarifications needed before implementation]

### Simplification Opportunities
[Concise list of areas where the plan can be reduced in scope or abstraction, with specific simpler alternatives — omit this section if no complexity concerns were found]
```

### Step 6 — Offer to save findings

After presenting the summary, ask the user:

> "Would you like me to append this interview summary to the plan file?"

**Do not write to the plan file unless the user explicitly confirms.** If they confirm, append the summary as a new `## Interview Summary` section at the end of the plan file using the `Edit` tool.

---

Arguments: $ARGUMENTS

