---
status: completed
type: standard
created: 2026-05-08
---

# Plan: tdd-loop skill + accessible Tabs demo

## Context

The `code-testing-agent` plugin already ships `tdd-fix` — an autonomous red/green loop bounded at 10 iterations, designed for **bug fixes** (failing test reproduces a bug, loop fixes the bug). What's missing is the **feature-first** counterpart: given a feature description, write a comprehensive failing test suite up front, commit it as a clean review artifact, then loop on the implementation, and finally split the PR into two commits (`test:` then `feat:`) so a reviewer can verify the tests existed before the code.

This skill formalizes that workflow as `code-testing-agent:tdd-loop`. The demo proves it works end-to-end by scaffolding a real React+Vitest project under `examples/tabs-demo/` and using the loop to implement a WAI-ARIA Tabs component (this is the first JS code in the marketplace and is intentionally isolated under `examples/`).

## Objective

1. Add `tdd-loop` skill to `code-testing-agent` plugin.
2. Demonstrate it by implementing an accessible Tabs component under `examples/tabs-demo/`.
3. Bump `code-testing-agent` MINOR; ship via the existing `git-agent` skills.

## Build Prerequisites

These are **blocking** — verify before authoring `tdd-loop/SKILL.md`. If any check fails, fix the upstream skill first.

1. **`commit-agent` must accept a message-type hint.** Read `kit/plugins/git-agent/skills/commit-agent/SKILL.md`. Confirm it accepts a passed-in commit-type override (e.g., "force `test:`"). If not present, extend `commit-agent` (MINOR bump) before authoring `tdd-loop`.
2. **`running-tests` must detect vitest.** Read `kit/plugins/code-testing-agent/skills/running-tests/SKILL.md` and `references/test-runner-guide.md`. Confirm `vitest.config.ts` / `vitest` in `package.json devDependencies` triggers detection. Extend if missing.
3. **Plan-mode detection mechanism.** The skill's Step 0 must use the same plan-mode check that `commit-agent` and `pr-agent` already use (Step 0 in those skills) — not a fictional `mcp__plan-mode` flag. Copy that pattern verbatim.

## Critical Files

- **Create:** `kit/plugins/code-testing-agent/skills/tdd-loop/SKILL.md`
- **Create:** `kit/plugins/code-testing-agent/skills/tdd-loop/references/tdd-log-format.md` — shared iteration-log schema (see "Iteration Log Schema" below). `tdd-fix` will reference this in a follow-up.
- **Modify:** `kit/plugins/code-testing-agent/CHANGELOG.md` — append `feat: add tdd-loop skill (test-first feature dev with bounded autonomous loop)` under a new MINOR version heading; match the existing entry style.
- **Verify:** `kit/plugins/code-testing-agent/.claude-plugin/plugin.json` — must NOT contain a `version` field (repo convention: relative-path plugins manage version only in `marketplace.json`). Remove if present.
- **Modify:** `.claude-plugin/marketplace.json` — bump `code-testing-agent` MINOR. Bump the parent `agentics-kit` marketplace version too (e.g., `3.2.0 → 3.3.0`) since a child plugin gained a feature; confirm convention by checking past commits where a single plugin gained a feature.
- **Modify:** `CLAUDE.md` — update the `code-testing-agent` row in the reference-implementations table to mention `tdd-loop` alongside the existing skills.
- **Create (demo):** `examples/tabs-demo/{package.json,tsconfig.json,vitest.config.ts,.gitignore,src/Tabs.tsx,src/Tabs.test.tsx,README.md}`
- **Reuse (no edits):** `kit/plugins/git-agent/skills/{commit-agent,pr-agent}/SKILL.md` (subject to Build Prerequisite #1)
- **Reference pattern:** `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md` — mirror its frontmatter, STOP discipline, and hypothesis-log table.
- **Fallback harness:** `tests/demo/{calculator.sh,calculator.test.sh,run.sh}` — documented as the zero-toolchain fallback when no framework is detected.

## Skill Design (`tdd-loop/SKILL.md`)

### Frontmatter

```yaml
---
name: tdd-loop
description: >
  Use when the user asks to TDD a feature, write tests first then implement, do a
  red-green-refactor loop for a new feature, or autonomously build something
  test-first. Writes a failing suite, commits it, loops on the implementation up
  to 20 iterations, runs typecheck and lint, then commits the implementation
  separately and opens a PR. Does not fix existing bugs — use tdd-fix for that.
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, AskUserQuestion, TodoWrite, Skill
---
```

Notes:

- `AskUserQuestion` is allowed but its use is **restricted by step**: only Step 1 (framework-fallback choice if detection fails) may call it. The Step-4 loop is forbidden from calling it.
- **No `ExitPlanMode`** — the skill refuses to run in plan mode (per repo rule). Step 0 detects via the same heuristic used in `commit-agent`/`pr-agent` Step 0.
- `Skill` is included to delegate to `git-agent:commit-agent` and `git-agent:pr-agent`.

### Freedom level

**Strict.** Every step ends with **STOP immediately** and the loops have hard caps.

### Workflow (8 steps)

**Step 0 — Pre-flight & TodoWrite.**

- Plan-mode check: refuse if running in plan mode, using the same detection pattern as `commit-agent` Step 0 / `pr-agent` Step 0 (NOT a fictional flag). Tell user to exit plan mode and rerun.
- Verify clean working tree (`git status --porcelain` empty) — abort if dirty.
- Verify on a feature branch (not `main`/`master`); if on default, instruct user to invoke `git-agent:branch-agent` first.
- Seed TodoWrite with the 7 remaining phases.

**Step 1 — Parse feature spec.**

- Extract from user input: `Feature name`, `Acceptance criteria` (numbered list), `Target file(s)`, `Test framework`.
- If acceptance criteria can't be enumerated, STOP and report — never guess.
- Framework detection delegates to `running-tests` heuristics. **Unknown-framework path:** if detection returns no match (e.g., Rust/Ruby/Java/Elixir), the skill is allowed exactly **one** `AskUserQuestion` call here — choose between "use the `tests/demo/` Bash fixture pattern as fallback" or "abort, I'll add framework support first." This is the only mid-skill user prompt allowed.

**Step 2 — Write failing test suite (red).**

- Create test file(s) covering every acceptance criterion. One assertion per criterion minimum; group with `describe` blocks where idiomatic.
- Run scoped tests; require **all new tests** to fail. If any pass before implementation, STOP — the test is wrong (likely too lenient).

**Step 3 — Commit the tests.**

- Invoke `Skill(git-agent:commit-agent)` with an explicit message-type hint forcing `test:`. The exact prompt-argument format depends on the API confirmed in Build Prerequisite #1.
- On success: branch now has one new commit `test: <feature name> — failing suite`.

**Step 4 — Autonomous implementation loop (max 20 iterations).**

Each iteration:

1. Run scoped tests; capture failure output.
2. Log a one-sentence hypothesis.
3. Make a minimal edit to production code only.
4. Re-run scoped tests.
5. Append row to the iteration log (schema in `references/tdd-log-format.md`).
6. Break early when failing-count = 0 — proceed to Step 5.

**Forbidden inside the loop:**

- Deleting tests, adding `.skip`/`xfail`/`@ts-ignore`/`any`, mocking the unit under test.
- `AskUserQuestion` calls — clarification mid-loop is forbidden.
- Entering plan mode.
- Committing.

**Test-edit escape hatch (single use):**

- If, mid-loop, a test is genuinely wrong (typo, wrong assertion), **one** test edit is allowed per loop run.
- The edit must be logged with `(test edited: <reason>)` appended to the iteration row's Hypothesis cell.
- A test-edit iteration **counts as 2 iterations** against the 20-cap (penalty discourages casual use).
- Second test edit in the same run → STOP and escalate.

**Iteration-1 early-green check:**

- If failing-count was N>0 at end of Step 2 and goes to 0 after iteration 1, STOP with `EARLY_GREEN`. Dump the iteration-1 diff and report "tests went green in one iteration — likely too lenient or implementation pre-existed; review tests for adequacy before committing." Do not proceed to Step 5.

**Hard-cap behavior:**

- On iteration 20 with red still on screen → STOP, dump the full iteration log, escalate. **Do not auto-revert.** Branch is left with the `test:` commit + uncommitted changes (or partial WIP). User decides next move.

**Step 5 — Quality gates (separate budget, max 5 iterations).**

- Run typecheck if `tsconfig.json` exists (`npx tsc --noEmit`); else language-equivalent (`mypy`, `go vet`).
- Run lint if configured (`npm run lint`, `eslint`, `ruff`, `golangci-lint`).
- Run **full** test suite (not scoped) for regression sweep.
- On failure, this becomes a **separate** loop with its own cap of **5 iterations**. Each iteration: read failure → minimal edit → re-run all three gates → log. Same forbidden list as Step 4.
- On 5-cap hit, STOP and escalate. Step 4's 20-cap is unaffected.

**Step 6 — Commit the implementation.**

- Invoke `Skill(git-agent:commit-agent)` with `feat:` message-type hint.
- Result: two clean commits on the branch — `test: …` then `feat: …`.

**Step 7 — Open PR.**

- Invoke `Skill(git-agent:pr-agent)`.
- Augment the PR body with a `## TDD iterations` section containing the iteration log table from Step 4 and the gate-fix log from Step 5 (if any).

**Step 8 — STOP.**

- Print summary: Step-4 iterations used / 20, Step-5 iterations used / 5, files touched, PR URL.
- Do not poll CI, do not open another loop. (CI watching is `ship-autonomous`'s job — explicitly out of scope.)
- Document a warning: do not chain `tdd-loop` and `ship-autonomous` in the same session — both touch `gh pr checks` and may interleave state.

### Iteration Log Schema (lives in `references/tdd-log-format.md`)

```text
| #  | Phase  | Hypothesis                       | Files Touched      | Failing Before | Failing After |
|----|--------|----------------------------------|--------------------|----------------|---------------|
| 1  | impl   | Tabs need role=tablist on ul     | src/Tabs.tsx       | 7              | 5             |
| 2  | impl   | aria-selected wired to state     | src/Tabs.tsx       | 5              | 4             |
| 3* | impl   | Disabled tab — fix off-by-one (test edited: assertion expected wrong index) | src/Tabs.tsx, src/Tabs.test.tsx | 4 | 2 |
| 4  | impl   | Home/End handlers                | src/Tabs.tsx       | 2              | 0             |
| g1 | gate   | tsc: implicit any on tab.id      | src/Tabs.tsx       | typecheck:1    | typecheck:0   |
```

`Phase` is `impl` (Step 4) or `gate` (Step 5). `*` marks a test-edit iteration. `g1` numbers Step-5 iterations independently. Both `tdd-fix` and `tdd-loop` reference this file going forward.

### Why deliberate parallels to `tdd-fix`

- Same iteration-log table → reviewers already know how to read it.
- Same forced commit-type pattern via `commit-agent` → no new commit machinery.
- Same STOP-after-every-step discipline → minimizes runaway behavior.

### Differences from `tdd-fix`

| Aspect | tdd-fix | tdd-loop |
| --- | --- | --- |
| Trigger | Bug report | Feature description |
| Tests written | Reproduce a bug | Cover full acceptance criteria |
| Commit count | 1 (`fix:`) | 2 (`test:` + `feat:`) |
| Iteration cap | 10 | 20 (Step 4) + 5 (Step 5) |
| Quality gates | Regression sweep only | Typecheck + lint + full suite (own loop) |
| Mid-skill `AskUserQuestion` | Yes (clarify bug) | Only Step 1, only on framework-detection miss |
| Test edits during loop | N/A | ≤1 per run, costs 2 iterations |

## Demo: examples/tabs-demo/

### Scaffold (one-time, before invoking the skill)

- `package.json` — `react@^18`, `react-dom@^18`, `vitest`, `@testing-library/react`, `@testing-library/user-event`, `jsdom`, `typescript`, `@types/react`, `eslint`, `eslint-plugin-jsx-a11y`. Scripts: `test` (`vitest run`), `typecheck` (`tsc --noEmit`), `lint` (`eslint src/`).
- `tsconfig.json` — strict, `jsx: react-jsx`.
- `vitest.config.ts` — `environment: 'jsdom'`.
- `.gitignore` — `node_modules/`, `dist/`, `coverage/`.
- `README.md` — explicit "demo project, not part of the marketplace product surface. Run `npm install` then `npm test`."

Verify root `.gitignore` does not already exclude `examples/`. The demo directory is committed; only `examples/tabs-demo/node_modules/` is excluded via the local `.gitignore`.

### Tabs component scope (locked from interview)

- **Horizontal only.** No `aria-orientation="vertical"` support.
- **Automatic activation.** Arrow keys move focus AND activate. No manual-activation mode.
- **No RTL.** `ArrowRight` always advances regardless of `dir`.
- **No transitions.** Panel toggle via `hidden` attribute; no CSS animation; trivially passes `prefers-reduced-motion`.
- **Disabled semantics:** `aria-disabled="true"` (NOT HTML `disabled`); skipped by keyboard nav and ignores clicks.
- **Tabpanels are focusable:** `tabindex="0"` on every panel.
- **Roving tabindex:** selected tab `tabindex="0"`, others `tabindex="-1"`.
- **No visual a11y tests** (jsdom doesn't compute styles); contrast/focus-ring assertions are explicitly out of scope.

### Acceptance criteria for Tabs (drives the failing test suite written in Step 2)

1. Renders a `role="tablist"` containing N `role="tab"` elements and N `role="tabpanel"` elements.
2. Exactly one tab has `aria-selected="true"` at any time; matching panel is visible, others have the `hidden` attribute.
3. Clicking a tab selects it and shows its panel.
4. `ArrowRight` / `ArrowLeft` move focus + selection between tabs (wrap at ends).
5. `Home` / `End` jump to first / last tab.
6. Tabs link to panels via `aria-controls` ↔ panel `id`; tab is referenced from panel via `aria-labelledby`.
7. Tabs marked disabled (via prop) render with `aria-disabled="true"`, are skipped by `ArrowLeft`/`ArrowRight`/`Home`/`End`, and ignore clicks.
8. Roving tabindex: selected tab has `tabindex="0"`, all others have `tabindex="-1"`.
9. Each tabpanel has `tabindex="0"` so screen reader users can Tab into panel content.

These map 1:1 to `it()` blocks in `Tabs.test.tsx`. Criteria #8 and #9 surfaced during the plan interview.

### Running the demo

After the skill PR merges, on `main`, scaffold `examples/tabs-demo/` (commit), then invoke:

```text
/code-testing-agent:tdd-loop Implement an accessible Tabs component at
examples/tabs-demo/src/Tabs.tsx satisfying the criteria in
examples/tabs-demo/README.md. Test file: examples/tabs-demo/src/Tabs.test.tsx.
```

The skill writes the test file (Step 2), commits it (Step 3), loops (Step 4), runs typecheck + eslint-plugin-jsx-a11y + full suite (Step 5), commits the implementation (Step 6), opens PR (Step 7).

## Build Sequence (sequential PRs)

PR #1 — skill:

1. Verify Build Prerequisites 1–3; fix upstream skills if any check fails.
2. Write `kit/plugins/code-testing-agent/skills/tdd-loop/SKILL.md`.
3. Write `kit/plugins/code-testing-agent/skills/tdd-loop/references/tdd-log-format.md`.
4. Bump `code-testing-agent` MINOR in `marketplace.json` (and bump parent `agentics-kit` version per convention).
5. Append `CHANGELOG.md` entry.
6. Update `CLAUDE.md` reference table row.
7. Lint via `skill-reviewer:reviewing-skills`.
8. Ship via `git-agent:ship` (commit + push + PR).
9. **Wait for merge.**

PR #2 — demo (after PR #1 merges, on updated `main`):

1. Scaffold `examples/tabs-demo/` (all files in "Scaffold" subsection above).
2. Commit (`chore(examples): scaffold tabs-demo project`).
3. Run `npm install` inside `examples/tabs-demo/` (interactive — user runs).
4. **Invoke the new skill** with the prompt in "Running the demo." The skill produces two commits (`test:` then `feat:`) and opens PR #2.

## Verification

- **Skill structure:** `skill-reviewer:reviewing-skills` reports zero blocking issues on the new SKILL.md.
- **`allowed-tools` accuracy:** every tool listed is referenced in the body; nothing in the body uses an undeclared tool.
- **Marketplace integrity:** `.claude/settings.json` auto-validates `marketplace.json` JSON on save; no errors.
- **Loop bounds in demo run:** iteration table emitted by the demo run shows ≤20 Step-4 rows and ≤5 Step-5 rows.
- **Two-commit outcome:** `git log --oneline` on the demo branch shows `test: …` followed by `feat: …`, no other commits.
- **Quality gates ran:** Demo PR body's `## TDD iterations` section shows the gate-fix log (or "no gate failures") before the implementation commit.
- **Tests actually pass:** `cd examples/tabs-demo && npm test` is green; `npm run typecheck` is green; `npm run lint` is green.
- **Plan-mode refusal:** manually invoking the skill from plan mode produces an immediate STOP message (no edits attempted).
- **Iteration-1 early-green:** manually feed the skill a feature already implemented; expect `EARLY_GREEN` exit, no commits.

## Next Steps (out of scope)

- Backport `references/tdd-log-format.md` reference into `tdd-fix/SKILL.md` so both skills share the schema by name.
- Add `tdd-loop` to `ship-autonomous` Step-6 fix recipes (so CI failures classified as "missing test coverage" trigger a `tdd-loop` run).
- Provide a `--language=python` worked example in the skill's references.
- Ship a vertical-orientation, manual-activation, RTL-aware variant of Tabs as a follow-up demo iteration.

## Unresolved Questions

None. All decisions confirmed via the plan interview.

---

## Interview Summary

### Key Decisions Confirmed

- **Skill home**: `kit/plugins/code-testing-agent/skills/tdd-loop/` (sibling of `tdd-fix`).
- **Demo target**: New `examples/tabs-demo/` with React + Vitest + TS + jsdom + jsx-a11y.
- **"Phase 1 harness"**: Defer to `running-tests` framework detection; `tests/demo/` Bash pattern is the documented zero-toolchain fallback.
- **Commit forcing**: Via prompt argument to `commit-agent` (verify the API exists during build, otherwise extend `commit-agent`).
- **CI/node_modules**: `examples/tabs-demo/.gitignore` for `node_modules`; no CI changes; demo is opt-in via `npm install`.
- **Quality-gate feedback**: Separate budget — Step 4 cap = 20 (TDD red→green), Step 5 cap = 5 (typecheck/lint repairs).
- **PR sequencing**: Sequential — ship skill PR first, merge, then run demo on `main`.
- **Tabs scope**: horizontal-only, automatic activation, no RTL, no transitions.
- **Tabs a11y**: `aria-disabled` (not HTML `disabled`), tabpanels `tabindex=0`, roving tabindex (only selected tab tabindex=0), no visual-contrast tests in jsdom.
- **Premature green**: STOP on iteration-1 green with `EARLY_GREEN`, dump diff for review.
- **Hard-cap behavior**: Leave branch as-is, no auto-revert, user decides.
- **Test escape hatch**: ≤1 test edit per loop run, logged loudly, costs 2 iterations against the 20-cap.

### Plan Naming

| Element | Current | Issue | Resolution |
| --- | --- | --- | --- |
| Filename | `create-a-tdd-loop-skill-joyful-treehouse.md` | Random suffix unrelated to content | **Renamed** to `create-tdd-loop-skill.md` |
| H1 Heading | `# Plan: tdd-loop skill + accessible Tabs demo` | Already descriptive | No change |

### Open Risks & Concerns

- `commit-agent` message-hint API may not exist — Build Prerequisite #1.
- `running-tests` may not detect vitest — Build Prerequisite #2.
- Plan-mode detection mechanism — Build Prerequisite #3.
- `ship-autonomous` × `tdd-loop` interaction — both touch `gh pr checks`. Skill body documents "do not chain in the same session."
- Iteration-table schema drift between `tdd-fix` and `tdd-loop` — addressed by shipping `references/tdd-log-format.md` on day one and backporting to `tdd-fix` (Next Steps).
- Framework coverage gaps for Rust/Ruby/Java/Elixir — handled by the single Step-1 `AskUserQuestion` allowance for unknown-framework path.

### Recommended Next Steps (folded into plan)

All 8 amendments from the interview have been applied to the plan body above:

1. Build Prerequisites section added.
2. Force-commit mechanism specified concretely (prompt argument to `commit-agent`).
3. `references/tdd-log-format.md` shipped on day one in Critical Files + Iteration Log Schema sections.
4. `plugin.json` version handling pinned (must NOT contain `version`).
5. Marketplace parent version bump addressed.
6. Test-edit escape hatch contract defined (≤1, logged, costs 2 iterations).
7. Iteration-1 `EARLY_GREEN` exit defined.
8. Unknown-framework path covered (single `AskUserQuestion` allowance in Step 1).

### Simplification Opportunities (deferred)

- **Single-PR alternative** to sequential PRs — user chose sequential for clean review boundaries; documented as alternative not adopted.
- **Drop `eslint`** from demo to reduce dependencies — user chose to keep eslint to demonstrate the lint gate against a real React project; documented as alternative not adopted.
