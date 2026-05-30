# Plan: Add Built-in Structured Interview Step to plan-agent

## Context

The `plan-agent` plugin creates self-contained HTML plans via a §1–§8 workflow. Currently, plan stress-testing requires either installing the separate `plan-interview` plugin or using the `--interview` flag which delegates to that external plugin after the plan is already committed. This means developers who only use `plan-agent` miss the opportunity to catch gaps, risks, and trade-offs before committing their plans.

Adding a lightweight, built-in interview step directly into the planning workflow will improve plan quality by surfacing issues during creation rather than after the fact — no external plugin dependency needed.

## Approach

Insert a new **§5b Interview** step between §5 Align and §6 Commit. This step analyzes the plan content for complexity, then runs 1–3 structured interview rounds using `AskUserQuestion` with dynamically generated questions. The step is a **standard part of the workflow** — it always runs unless explicitly opted out with `--no-interview` or `--quick`.

There is no `--interview` flag. The interview is not opt-in — it is a default stage of plan creation. The only flag is `--no-interview` (and `--quick` which implies it) to skip the step when speed matters. The old `--interview` flag (which delegated to the external `plan-interview` plugin after §8) is removed entirely. The standalone `plan-interview` plugin remains available for deeper post-hoc reviews.

## Files to Modify

### 1. `kit/plugins/plan-agent/skills/planning/SKILL.md` (primary)

**Flag changes in frontmatter + Invocation section:**
- `argument-hint` (line 6): remove `[--interview]`, add `[--no-interview]`
- `--quick` bullet (line 16): expand to `--no-clarify --no-align --no-interview`; mention §5b
- `--interview` bullet (line 23): delete entirely and replace with `--no-interview` — skip §5b Interview. The interview is standard, not opt-in
- Delete the post-§8 delegation paragraph (line 56) — no more external delegation

**Insert new step 5b after step 5 (line 45) and before step 6 (line 46):**

The step contains:
- **Complexity detection** — classify the plan as short (1 round), medium (2 rounds), or complex (3 rounds) by analyzing plan content (file count, domain breadth, step count)
- **UI signal override** — always include Round 2 if plan references React/Vue/Angular, `.tsx`/`.jsx`/`.css`, Tailwind, UX terms (button, modal, form, etc.)
- **Round 1 — Technical & Trade-offs** (always): up to 4 questions on architectural decisions, library trade-offs, performance, integration points
- **Round 2a — UI/UX & Flows** (medium+ or UI): up to 4 questions on user flows, responsive behavior, motion/animation, UI state gaps
- **Round 2b — Accessibility & Semantic** (after 2a): up to 4 questions on keyboard nav, screen reader support, WCAG 2.1 AA, semantic HTML
- **Round 3 — Edge Cases & Best Practices** (complex only): up to 4 questions on failure modes, concurrency, regression risks, remaining open questions
- **Post-interview**: brief summary of findings, then `AskUserQuestion` to offer updating the plan HTML before proceeding to §6

All questions must be generated dynamically from plan content — no hardcoded/generic questions.

### 2. `kit/plugins/plan-agent/CHANGELOG.md`

Add `v0.10.0` entry at top documenting:
- Added: §5b Interview step as a standard workflow stage (always runs by default)
- Added: `--no-interview` flag to opt out when speed matters
- Changed: `--quick` now includes `--no-interview`
- Removed: `--interview` flag — the interview is no longer opt-in; it is standard

### 3. `.claude-plugin/marketplace.json`

- Bump `plan-agent` version from `0.9.0` to `0.10.0`
- Update description to mention built-in structured interview

### 4. `kit/plugins/plan-agent/.claude-plugin/plugin.json`

- Update description to reflect the new capability

### 5. `kit/plugins/plan-agent/README.md`

- Line 22: rewrite "Optional pairing" note — plan-agent now has its own interview; plan-interview is for deeper standalone reviews
- Line 59: update invocation syntax (remove `--interview`, add `--no-interview`)
- Lines 64–73: update flags table (remove `--interview` row, add `--no-interview`, update `--quick`)
- Line 81: remove `--interview` example
- Lines 86–96: insert §5b in the workflow list between Align and Commit
- Lines 195: update argument list
- Lines 218–225: rewrite plan-interview pairing section

## Key Design Decisions

- **Standard, not opt-in**: the interview is a core workflow stage like Create or Frontmatter — not a flag-gated feature. Only `--no-interview` (or `--quick`) skips it. This follows the same pattern as Clarify and Align
- **No external dependency**: the plan content is already in-context from §2 Create. Delegating to plan-interview would re-read/re-analyze the file and run its full 6-step workflow unnecessarily
- **Step 5b (not renumbered)**: avoids churn across README, CHANGELOG, and external references. The `X.5` pattern is already proven in plan-interview (Step 1.5, 2.5, 2.6)
- **Dynamic questions only**: every question must reference specific plan details (file paths, component names, library choices) — matches plan-interview's established standard

## Verification

1. Run `/plan-agent:planning add a user profile page` (no flags) — confirm §5b runs, detects UI signals, runs Rounds 1 + 2a + 2b
2. Run `/plan-agent:planning --no-interview fix a typo` — confirm §5b is skipped
3. Run `/plan-agent:planning --quick add dark mode` — confirm Clarify, Align, AND Interview all skip
4. Run `/plan-agent:planning fix the login redirect bug` — confirm only Round 1 runs (short/focused, no UI)
5. Run `/plan-agent:planning refactor auth into OAuth, session, and RBAC services` — confirm all 3 rounds run
6. Confirm post-interview update correctly edits the HTML plan when user accepts
7. Validate that passing the old `--interview` flag is silently ignored (not parsed)
