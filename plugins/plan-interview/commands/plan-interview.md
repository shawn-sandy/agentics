---
description: Stress-test a plan with a structured interview across technical, UX, edge case, and out-of-scope domains
argument-hint: [plan-file-path] - omit to auto-detect from IDE or ~/.claude/plans/
allowed-tools: Read, Glob, AskUserQuestion, Write, Edit, TodoWrite
---


# /plan-interview:plan-interview

Stress-test a plan through a structured conversational interview before implementation begins.

## Usage

```
/plan-interview:plan-interview                                        # auto-detects from IDE or latest in ~/.claude/plans/
/plan-interview:plan-interview ~/.claude/plans/my-feature.md          # use a specific plan file
```

## Instructions

### Step 0 — Create progress todos

Before doing any other work, use `TodoWrite` to create todos for each step of this interview. This gives the user visibility into progress and ensures no step is skipped.

Create the following todos (all starting with `status: "pending"`):

- Step 2: Read, validate plan name, and analyze the plan
- Step 3a: Round 1 — Technical & Trade-offs
- Step 3b: Round 2a — UI/UX & Flows (if applicable)
- Step 3c: Round 2b — Accessibility & Semantic (if applicable)
- Step 3d: Round 3 — Edge Cases & Best Practices (if applicable)
- Step 4: Surface out-of-scope concerns & complexity check
- Step 5: Compile and present review summary
- Step 6: Save findings to the plan file

Mark each todo `status: "completed"` as you finish that step.

### Step 1 — Resolve the plan file

Use the first match from this priority order:

1. **Explicit argument**: If `$ARGUMENTS` is provided, treat it as the file path and read it directly.
2. **Currently open file**: If no argument is given, check whether a file is currently open or selected in the IDE (provided via context). If it exists, is a `.md` file, and its content looks like a plan (contains headings like `## Implementation`, `## Plan`, `## Steps`, `## Instructions`, or similar structural markers), use it.
3. **Project-level settings**: Read `.claude/settings.json` in the current project directory. If a `"plansDirectory"` key exists, glob `*.md` files from that path and use the most recently modified file. This takes precedence over the global config in step 4.
4. **Latest plan in `~/.claude/plans/`**: If none of the above applies, use `Glob` on `~/.claude/plans/*.md`, sort by modification time, and select the most recently modified file.

Once resolved, tell the user which file will be used (e.g., "Interviewing plan: `~/.claude/plans/my-feature.md`") before proceeding.

If no plan file can be found via any of these methods, tell the user and stop.

### Step 2 — Read, validate plan name, and analyze the plan

Read the resolved plan file.

**Plan name validation**: Before extracting plan details, check whether the
plan's filename and H1 heading accurately describe the plan's content.

1. **Extract identifiers**: Get the filename (without path or `.md` extension)
   and the H1 heading (first line matching `# ...`).

2. **Determine the plan's purpose**: Read enough of the plan to form a
   one-sentence summary of what it intends to accomplish.

3. **Evaluate the filename** against these criteria:
   - **Descriptive**: Contains words that relate to the plan's goal or content.
     Good: `create-skill-reviewer-plugin`, `fix-marketplace-json-location`.
     Bad: `fuzzy-swimming-pearl`, `hidden-popping-moonbeam`.
   - **Not random**: Does not follow a random adjective-noun or
     adjective-verb-noun pattern with no connection to the plan's subject matter.
     Note: `add-dark-mode-toggle` is descriptive even though it contains
     adjectives — the key test is whether the words relate to the plan content.
   - **Not too generic**: Not a placeholder like `plan.md`, `untitled.md`,
     `draft.md`, `temp.md`, or `new-plan.md`.

4. **Evaluate the H1 heading**:
   - Does an H1 heading exist?
   - Does it describe the plan's purpose? (Good: `# Plan: Create
     'skill-reviewer' Plugin`. Bad: `# Plan` alone, or missing entirely.)
   - Does it align with the filename? Flag misalignment only when the filename
     and heading refer to entirely different topics — not when they describe the
     same topic at different scopes (e.g., `fix-auth-bug` and
     `# Plan: Refactor Authentication Module` are aligned because both concern
     authentication).

5. **Record the result** as one of:
   - **Pass**: Both filename and heading are descriptive and aligned — proceed
     silently.
   - **Needs attention**: One or both are non-descriptive, generic, or
     misaligned. Record:
     - Which element(s) failed (filename, heading, or both)
     - Why (random pattern, too generic, misaligned, or missing)
     - A **suggested filename** in kebab-case derived from the plan's goal
     - A **suggested H1 heading** in `# Plan: [Description]` format

If the name needs attention, present the finding immediately before continuing:

```markdown
### Plan Name Review

| Element | Current | Issue | Suggested |
|---------|---------|-------|-----------|
| Filename | `fuzzy-swimming-pearl.md` | Random — unrelated to content | `create-skill-reviewer-plugin.md` |
| H1 Heading | _(missing)_ | No H1 heading found | `# Plan: Create 'skill-reviewer' Plugin` |
```

Then ask the user via `AskUserQuestion`: *"Would you like me to rename this plan
file to `[suggested-name].md`?"* (and if the H1 heading was also flagged,
include it in the offer: *"…and update the heading to `# Plan: [Description]`?"*).

If the user confirms:
- Rename the file using Bash `mv`.
- Update the H1 heading in the file using `Edit` (if it was flagged).
- **Update the resolved file path** for the remainder of the interview so that
  Steps 4–6 (especially Step 6's save operation) reference the new path.

If the user declines, proceed without changes.

If the name passes validation, skip this section silently.

Extract the following to guide question generation:

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

### Plan Naming
[Include only if name validation found issues in Step 2. Reproduce the table
showing current name(s), the issue, and suggested replacement(s). Note whether
the user accepted or declined the rename offer. Omit this section entirely if
the name passed validation.]

### Open Risks & Concerns
[List risks, unknowns, or concerns surfaced — with brief context]

### Recommended Next Steps
[Amendments to the plan, additional spikes, or clarifications needed before implementation]

### Simplification Opportunities
[Concise list of areas where the plan can be reduced in scope or abstraction, with specific simpler alternatives — omit this section if no complexity concerns were found]
```

### Step 6 — Save findings to the plan file

After presenting the summary, **always** append it to the plan file — do not ask
for confirmation. Use the `Edit` tool to append the summary as a new
`## Interview Summary` section at the end of the plan file.

If the plan file already contains an `## Interview Summary` section from a
previous interview, replace it with the new summary instead of appending a
duplicate.

After saving, confirm to the user: *"Interview summary has been saved to
`[plan-file-path]`."*

---

Arguments: $ARGUMENTS
