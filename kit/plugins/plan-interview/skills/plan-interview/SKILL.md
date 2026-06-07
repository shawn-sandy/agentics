---
name: plan-interview
description: "Stress-tests implementation plans through structured interviews. Surfaces gaps, risks, and assumptions via targeted questions. Use when the user asks to stress-test or validate a technical plan."
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Write, Edit, TodoWrite, Skill, ToolSearch, ExitPlanMode
---

# Plan Interview

Stress-test a plan through a structured conversational interview before
implementation begins.

## When not to use

Does not execute implementation work or apply code fixes from the plan — this is a review tool only. Updating the plan file itself (Step 6) is permitted. Not for product plans, PRDs, or stakeholder proposals — use `product-plans:plan-review-agents` for those.

## Table of Contents

- [Step 0 — Exit plan mode and create progress todos](#step-0--exit-plan-mode-and-create-progress-todos)
- [Step 1 — Resolve the plan file](#step-1--resolve-the-plan-file)
- [Step 1.5 — Classify and route](#step-15--classify-and-route)
- [Step 2 — Read, validate plan name, and analyze the plan](#step-2--read-validate-plan-name-and-analyze-the-plan)
- [Step 2.5 — Skill tool analysis](#step-25--skill-tool-analysis-skill-review-mode-only)
- [Step 2.6 — Skill quality checklist](#step-26--skill-quality-checklist-skill-review-mode-only)
- [Step 3 — Conduct the structured interview](#step-3--conduct-the-structured-interview)
- [Step 4 — Surface out-of-scope concerns](#step-4--surface-out-of-scope-concerns)
- [Step 5 — Compile and present the review summary](#step-5--compile-and-present-the-review-summary)
- [Step 6 — Offer to save findings](#step-6--offer-to-save-findings)

## Instructions

### Step 0 — Exit plan mode and create progress todos

**Flag detection**: Scan the activation message and any arguments for the
literal text `--quick`. If present, set `quick_mode = true`; otherwise
`quick_mode = false`. Record this once here — subsequent steps reference it
without re-parsing.

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** — skip this step entirely when not in plan mode. When calling: use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

Before doing any other work, use `TodoWrite` to create todos for each step of
this interview. This gives the user visibility into progress and ensures no step
is skipped.

Create the following todos (all starting with `status: "pending"`):

- Step 1.5: Classify and route (plan-review mode only)
- Step 2: Read, validate plan name, and analyze the plan
- Step 2.5: Skill tool analysis (skill-review mode only)
- Step 2.6: Skill quality checklist (skill-review mode only)
- Step 3a: Round 1 — Technical & Trade-offs
- Step 3b: Round 2a — UI/UX & Flows (if applicable)
- Step 3c: Round 2b — Accessibility & Semantic (if applicable)
- Step 3d: Round 3 — Edge Cases & Best Practices (if applicable)
- Step 4: Surface out-of-scope concerns & complexity check
- Step 5: Compile and present review summary
- Step 6: Offer to save findings

Mark each todo `status: "completed"` as you finish that step.

### Step 1 — Resolve the plan file

Use the first match from this priority order:

1. **User message**: If a file path appears in the user's message, treat it as
   the plan file path and read it directly.
2. **Currently open file**: If no path was given, check whether a `.md` file is
   currently open or selected in the IDE (provided via context). If it exists
   and its content looks like a plan (contains headings like
   `## Implementation`, `## Plan`, `## Steps`, `## Instructions`, or similar
   structural markers), use it.
3. **Project-level config override**: Read `.claude/settings.json` in the
   current project directory. If a `"plansDirectory"` key exists, glob `*.md`
   files from that path and use the most recently modified file. This takes
   precedence over the global config.
4. **Global config**: Read `~/.claude/settings.json`. If a `"plansDirectory"`
   key exists, glob `*.md` files from that path and use the most recently
   modified file.
5. **Default fallback**: Use `Glob` on `~/.claude/plans/*.md`, sort by
   modification time, and select the most recently modified file.

Once resolved, detect the review mode before proceeding:

**Skill detection** — the resolved file is a skill if:

- Its filename is `SKILL.md`, **or**
- Its YAML frontmatter contains both a `name:` and `description:` field but the
  body has no plan-style headings (`## Implementation`, `## Plan`, `## Steps`,
  `## Context`)

Set `mode = skill-review` if detected, otherwise `mode = plan-review`.

Announce the file and mode:

- Plan: `"Interviewing plan: ~/.claude/plans/my-feature.md"`
- Skill: `"Reviewing skill: path/to/SKILL.md"`

If no file can be found via any of these methods, tell the user and stop.

### Step 1.5 — Classify and route _(plan-review mode only)_

Skip this step entirely when `mode = skill-review` or `quick_mode = true`.

Do a lightweight scan of the resolved plan file to detect its type. Use `Read`
with a small limit (first 80 lines) to extract headings and opening content
without loading the full file.

**Product-plan signals — headings** (match case-insensitively):
`## User Stories`, `## Success Metrics`, `## Business Goals`, `## Personas`,
`## Requirements`, `## Acceptance Criteria`, `## KPIs`, `## OKRs`,
`## Go-to-Market`, `## Launch Plan`

**Product-plan signals — body keywords:**
"stakeholder", "product manager", "market research", "user research",
"A/B test", "go-to-market", "business objective", "customer segment"

Count distinct signals found across the first 80 lines.

**If 2 or more signals are detected**, ask the user via `AskUserQuestion`:

> "This plan contains product-level content ([list the 2–3 strongest signals]).
> How would you like to review it?"

Options:
- **Full panel review** — route to `product-plans:plan-review-agents` (six
  specialist agents: PM, Dev, UX, Frontend, A11y, Security run in parallel)
- **Quick technical interview** — continue here (single-agent, focused on
  implementation gaps and decision trade-offs)

If the user chooses **Full panel review**, invoke the panel skill and stop:

```
Skill(skill: "product-plans:plan-review-agents", args: "<resolved-path>")
```

Do not run any further steps of this skill — the panel skill owns the session
from this point.

If the user chooses **Quick technical interview**, or if fewer than 2 signals
are found, continue to Step 2 without comment.

> **Tip:** To skip this routing check and always run the technical interview,
> pass `--quick` in the invocation: `/plan-interview:plan-interview --quick [path]`

### Step 2 — Read, validate plan name, and analyze the plan

**In `skill-review` mode**: skip the plan name validation section entirely and
proceed directly to Step 2.5 after reading the file.

Read the resolved file.

**Plan name validation**: Before extracting plan details, check whether the
plan's filename and H1 heading accurately describe the plan's content.

1. **Extract identifiers**: Get the filename (without path or `.md` extension)
   and the H1 heading (first line matching `# ...`).

2. **Determine the plan's purpose**: Read enough of the plan to form a
   one-sentence summary of what it intends to accomplish.

3. **Evaluate the filename** against these criteria:
   - **Descriptive**: Contains words that relate to the plan's goal or content.
     Good: `create-skill-reviewer-plugin`, `fix-marketplace-json-location`. Bad:
     `fuzzy-swimming-pearl`, `hidden-popping-moonbeam`.
   - **Not random**: Does not follow a random adjective-noun or
     adjective-verb-noun pattern with no connection to the plan's subject
     matter. Note: `add-dark-mode-toggle` is descriptive even though it contains
     adjectives — the key test is whether the words relate to the plan content.
   - **Not too generic**: Not a placeholder like `plan.md`, `untitled.md`,
     `draft.md`, `temp.md`, or `new-plan.md`.
   - **Verb-led**: Starts with an imperative verb. Good: `add-dark-mode-toggle`,
     `fix-auth-redirect`, `create-skill-reviewer-plugin`. Bad:
     `branch-agent-append-date-suffix` (noun-led), `auth-module-changes`
     (noun-led). Common verbs: `add`, `fix`, `create`, `build`, `implement`,
     `update`, `refactor`, `migrate`, `configure`, `remove`, `enable`,
     `disable`, `move`, `rename`, `extract`, `deploy`, `document`, `integrate`.

4. **Evaluate the H1 heading**:
   - Does an H1 heading exist?
   - Does it describe the plan's purpose? (Good:
     `# Plan: Create 'skill-reviewer' Plugin`. Bad: `# Plan` alone, or missing
     entirely.)
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
     - Why (random pattern, too generic, misaligned, not verb-led, or missing)
     - A **suggested filename** in kebab-case derived from the plan's goal — must
       start with an imperative verb (e.g., `add-`, `fix-`, `create-`)
     - A **suggested H1 heading** in `# Plan: [Description]` format

If the name needs attention, present the finding immediately before continuing:

```markdown
### Plan Name Review

| Element    | Current                   | Issue                         | Suggested                                |
| ---------- | ------------------------- | ----------------------------- | ---------------------------------------- |
| Filename   | `fuzzy-swimming-pearl.md` | Random — unrelated to content | `create-skill-reviewer-plugin.md`        |
| H1 Heading | _(missing)_               | No H1 heading found           | `# Plan: Create 'skill-reviewer' Plugin` |
```

Then ask the user via `AskUserQuestion`: _"Would you like me to rename this plan
file to `[suggested-name].md`?"_ (and if the H1 heading was also flagged,
include it in the offer: _"…and update the heading to
`# Plan: [Description]`?"_).

If the user confirms:

- Rename the file using Bash `mv`.
- Update the H1 heading in the file using `Edit` (if it was flagged).
- **Update the resolved file path** for the remainder of the interview so that
  Steps 4–6 (especially Step 6's save operation) reference the new path.

Then ask via `AskUserQuestion`: _"Generate HTML for the renamed plan?
(`markdown-to-html` will prompt for a color theme.)"_ (options: `Yes, generate HTML`
/ `Skip`). If confirmed, call:

```
Skill(skill: "plan-interview:markdown-to-html", args: "<new-path> --no-open --mode=plan")
```

If the user declines, continue to the rest of Step 2.

If the user declines, proceed without changes.

If the name passes validation, skip this section silently.

Extract the following to guide question generation:

- **Goal**: What is being built and why?
- **Key components**: What files, services, or systems are involved?
- **Tech stack**: Languages, frameworks, libraries, APIs
- **Scope**: Is this a focused change, a medium-sized feature, or a complex
  multi-area effort?
- **UI involvement**: Does the plan reference components, pages, forms, styles,
  or HTML? (Used to determine whether Round 2 runs regardless of scope.)
- **Open questions**: Any unresolved questions listed in the plan?
- **Step structure**: Does the `## Steps` section exist? For each numbered step,
  check whether it includes both a `*Why:*` line and a `*Verify:*` (or
  `- Verify:`) line. Record the count of steps missing a verify line (e.g.,
  "3 of 5 steps lack a verify").

Also extract **complexity signals** from the plan:

- Multiple new abstractions or layers (factories, registries, adapters, base
  classes) introduced for a focused task
- Third-party libraries proposed for tasks covered by native APIs or the
  standard library
- Custom implementations of patterns the framework or language already provides
- Premature optimization signals (caching, queuing, batching) without stated
  scale requirements
- More than 3 new files proposed for a single-concern change
- Complex state management (Redux, Zustand, XState) proposed for local or
  ephemeral state

Use the scope assessment to determine how many interview rounds to conduct:

- **Short/focused plan** (single concern, 1–2 files): 1 round
- **Medium plan** (feature with UI + logic): 2 rounds
- **Complex/multi-area plan** (architecture, cross-cutting concerns, 3+
  domains): 3 rounds

After scope assessment, also check for **UI involvement**: look for any of the
following signals in the plan:

- Framework keywords: React, Vue, Svelte, Angular, or similar component-based UI
  libraries
- HTML/CSS terms: `className`, `style`, CSS, Tailwind, styled-components, or
  similar
- File types: `.tsx`, `.jsx`, `.css`, `.scss`, `.html`
- UX terminology: button, modal, form, dialog, dropdown, input, layout, page,
  screen, component

If any UI signals are detected, always include Round 2 — even for plans
classified as short/focused. When triggering Round 2 on a short plan, briefly
note what was detected (e.g., "Running Round 2 — plan references React
components and `.tsx` files") so the user understands why.

### Step 2.5 — Skill tool analysis _(skill-review mode only)_

Skip this step entirely when `mode = plan-review`.

Analyze the skill file to detect tool usage and recommend `allowed-tools` for
the skill's frontmatter.

1. **Parse existing `allowed-tools`**: Extract the current `allowed-tools` value
   from the YAML frontmatter. If absent, treat as empty.

2. **Scan for tool references**: Search the skill body for any of the following
   known Claude tool names (match as whole words or within backticks):

   ```
   Read, Write, Edit, MultiEdit, Glob, Grep, Bash, AskUserQuestion,
   TodoWrite, Agent, WebFetch, WebSearch, NotebookRead, NotebookEdit,
   ToolSearch, ExitPlanMode
   ```

   Also detect filtered patterns such as `Bash(git *)` or `Bash(gh *)`.

3. **Classify each tool** as one of:
   - **Declared** — already present in `allowed-tools`
   - **Missing** — detected in the skill body but absent from `allowed-tools`
   - **Undeclared** — listed in `allowed-tools` but not detected in the body
     (flag for review, do not auto-remove)

4. **Present the analysis table:**

   ```markdown
   ### Skill Tool Analysis

   | Status     | Tool  | Detected In                         |
   | ---------- | ----- | ----------------------------------- |
   | Declared   | Read  | Step 1 — reading skill file         |
   | Missing    | Grep  | Step 3 — interview codebase references |
   | Undeclared | Write | In allowed-tools but not detected   |
   ```

5. **Output a suggested `allowed-tools` line**, listing all detected tools in
   alphabetical order:

   ````markdown
   **Suggested frontmatter** (commands only — `allowed-tools` is not supported
   in SKILL.md files):

   ```yaml
   allowed-tools: AskUserQuestion, Bash, Edit, Glob, Grep, Read, TodoWrite
   ```
   ````

   ```

   > Note: `allowed-tools` is only valid in command files (`.md` files in
   > `commands/`). If the reviewed skill has a paired command file, the
   > recommendation applies there.
   ```

### Step 2.6 — Skill quality checklist _(skill-review mode only)_

Skip this step entirely when `mode = plan-review`.

Read [reference/skill-checklist.md](reference/skill-checklist.md) and evaluate the reviewed skill
against every item in the checklist. For each category, mark items as passing
or failing based on what you can observe in the skill file and its directory.

Present the results as a scored table:

```markdown
### Skill Quality Checklist

| Category        | Passing | Failing | N/A |
| --------------- | ------- | ------- | --- |
| Core quality    | 8       | 2       | 0   |
| Code & scripts  | —       | —       | 8   |
| Testing         | 0       | 3       | 1   |
```

Then list only the **failing items** with a brief note on each:

```markdown
**Failing items:**

- [ ] Description does not include when to use the Skill
- [ ] No concrete examples provided
- [ ] Not tested with multiple models
```

Mark items as **N/A** (not applicable) when the skill has no scripts or code
(entire "Code and scripts" category may be N/A for instruction-only skills).

### Step 3 — Conduct the structured interview

Generate questions dynamically from the plan content — do not use generic or
hardcoded questions. Each `AskUserQuestion` call may include up to 4 questions.

**Round 1 — Technical & Trade-offs** (always run):

Ask up to 4 questions covering:

- The most uncertain architectural or implementation decision in the plan
- Build vs. buy, library choice, or API design trade-offs
- Performance, scalability, or data model concerns specific to this plan
- Any unclear integration points or dependencies

Use `multiSelect: true` for questions where the user may want to flag multiple
concerns (e.g., "Which of these areas need more investigation?").

**Round 2a — UI/UX & Flows** (run for medium and complex plans, or any plan with
UI involvement — see Step 2):

Ask up to 4 questions covering:

- User flows: happy path, error states, loading states, empty states
- Mobile or responsive behavior concerns
- Motion and animation: `prefers-reduced-motion`, transitions, focus indicators
  after animation
- Any UI state not covered by the plan (e.g., skeleton loading, optimistic
  updates, error recovery)

**Round 2b — Accessibility & Semantic Structure** (run immediately after Round
2a when Round 2 is triggered):

Ask up to 4 questions covering:

- Keyboard navigation, focus order, focus trapping (modals/dialogs), skip-nav
  links
- Screen reader support: ARIA roles, labels, `aria-describedby` for errors, live
  regions
- WCAG 2.1 AA compliance: color contrast (4.5:1 text, 3:1 UI), touch targets
  (44×44px min)
- Semantic HTML: heading hierarchy, landmark regions, form label association

**Round 3 — Edge Cases & Best Practices** (run for complex plans only):

Ask up to 4 questions covering:

- Critical failure modes or race conditions
- Concurrent user scenarios or data conflicts
- Regression risks: which existing tests might break, what
  backward-compatibility contracts exist (API shape, component props, data
  schema), and whether visual or behavioral regression testing is in place
- Which best practices should guide implementation: security, performance, test
  coverage, DX
- Any remaining open questions from the plan that haven't been addressed

> **Deep Grill**: To walk every decision branch in depth after this interview,
> run the standalone `deep-grill` skill. Say _"deep grill this plan"_ or invoke
> it directly with `/plan-interview:deep-grill [plan-file-path]`.

### Step 4 — Surface out-of-scope concerns

After the structured rounds, review the full plan one more time and identify any
issues that were not covered by the interview questions. These are concerns you
observed independently — not topics already raised by the user. Look for:

- Missing sections a plan of this type would normally include (e.g., rollback
  strategy, auth/permissions, data migration, monitoring)
- Implicit assumptions in the plan that could silently break implementation
- Ownership or responsibility gaps (who handles what is unclear)
- Naming, scope, or intent ambiguities that could cause misalignment during
  implementation
- Risks that fall outside the Technical / UI / Edge Case domains
- Regression blind spots: the plan does not identify which existing tests, API
  contracts, or user-visible behaviors could break

If any out-of-scope concerns exist, present them as a clearly labelled section
in the chat before the summary:

```markdown
### Additional Concerns (Outside Structured Rounds)

- [Concern 1]: [Brief explanation of why this matters]
- [Concern 2]: [Brief explanation of why this matters]
```

If no additional concerns exist, skip this section silently.

**Complexity Check** (always run):

After the out-of-scope scan, evaluate the proposed approach against what the
simplest working solution would look like. For each element that appears
over-engineered, ask: _Could a built-in, a single function, or a native API
replace this abstraction?_ Only surface real issues — do not flag complexity for
its own sake on genuinely complex plans. Only name a simpler alternative when
one is clearly apparent; omit concerns where no obvious alternative exists.

If any complexity concerns are found, present them under a clearly labelled
section:

```markdown
### Complexity Concerns

- [Over-engineered element]: [Why it's unnecessary] — Simpler alternative:
  [specific suggestion]
```

Skip this section silently if no complexity concerns are found.

### Step 5 — Compile and present the review summary

After all rounds and the out-of-scope check are complete, output a structured
summary in the chat:

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

### Step Structure

[Include only if Step 2 found steps missing a verify line. State the count
(e.g., "3 of 5 steps lack a *Verify:* line") and show a corrected example:

**Corrected example:**
1. **[Action]** — [description]. *Why:* [rationale]. *Verify:* [how to confirm
   this step succeeded].

Omit this section entirely if all steps already carry action + why + verify.]

### Recommended Next Steps

[Amendments to the plan, additional spikes, or clarifications needed before
implementation]

### Simplification Opportunities

[Concise list of areas where the plan can be reduced in scope or abstraction,
with specific simpler alternatives — omit this section if no complexity concerns
were found]

### Skill Quality Checklist Results

[Include only in `skill-review` mode. Reproduce the scored table and failing
items from Step 2.6. Omit this section entirely when reviewing a plan file.]

### Allowed Tools Recommendation

[Include only in `skill-review` mode. Reproduce the tool analysis table from
Step 2.5, plus the suggested `allowed-tools` line for any paired command file.
Omit this section entirely when reviewing a plan file.]
```

### Step 6 — Offer to save findings

After presenting the Step 5 summary, ask the user:

> "Would you like me to update the plan with suggested changes and append this
> interview summary to the plan file?"

**Do not write to the plan file unless the user explicitly confirms.** If they
confirm, update the plan with suggested changes and append the summary as a new
`## Interview Summary` section at the end of the plan file using the `Edit`
tool. When writing or amending steps, use the three-part format required by
`plan-mode.md`:
`**[Action]** — [description]. *Why:* [rationale]. *Verify:* [confirmation criteria].`

If they decline the summary append, do not modify the file.

**In `plan-review` mode only**: after handling the save decision (whether
confirmed or declined), always generate an interview HTML artifact. Use the
resolved plan path (the renamed path from Step 2, if applicable):

1. Derive paths from the resolved plan file:
   - `plan_dir` = directory containing the plan file
   - `plan_stem` = filename without the `.md` extension

2. Invoke the markdown-to-html skill to render the plan:
   ```
   Skill(skill: "plan-interview:markdown-to-html", args: "<resolved-plan-path> --background --mode=plan")
   ```

3. Rename the default output to the interview-scoped filename:
   ```bash
   mv "<plan_dir>/<plan_stem>.html" "<plan_dir>/<plan_stem>-interview.html"
   ```
   If `mv` fails (e.g. markdown-to-html wrote to a different path), announce the
   actual path that was written instead.

4. Announce:
   > `Interview HTML written: <plan_dir>/<plan_stem>-interview.html`

   This artifact is the shared living document — if you later run
   `product-plans:plan-review-agents` on this plan, it will detect this file
   and append the panel findings to it rather than creating a separate
   `<plan-stem>-review.html`.

**In `skill-review` mode**: if Step 2.5 identified missing tools, also ask:

> "Would you like me to apply the `allowed-tools` recommendation to the paired
> command file?"

If confirmed, use `Edit` to add or update the `allowed-tools` line in the YAML
frontmatter of the corresponding command file (look for a `.md` file in
`commands/` with a matching name). If no paired command file exists, note that
`allowed-tools` is only applicable to command files and skip.
