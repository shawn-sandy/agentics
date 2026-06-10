# Changelog

## 2.1.0 — Findings walkthrough and --skip-analysis flag for review-plan (2026-06-10)

### Added

- **Step 6b — Walkthrough & Analysis** — new `review-plan` workflow step inserted between synthesis (Step 6) and integration (Step 7). Instead of silently auto-applying every synthesized edit, the skill now offers an interactive walkthrough of the findings before anything is written into the plan.
- **Ask-first gate** — Step 6b opens with an `AskUserQuestion` gate offering `Walk through findings` (the default), `Apply all`, and `Review only`. Declining via `Review only` applies nothing but still appends the Team Review to the plan.
- **Per-finding triage** — during the walkthrough each finding is triaged `Accept` / `Modify` / `Reject`, batched at most 4 findings per prompt. `Modify` selections are deferred and collected into a single post-walkthrough edit pass instead of interrupting the walkthrough one finding at a time.
- **`--skip-analysis` flag** — bypasses the gate and the walkthrough entirely, preserving the previous auto-apply behavior in one shot.
- **`--triage-top <N>` flag** — individually triages only the `N` highest-risk findings and batch-accepts the rest, keeping the walkthrough short on large reviews.
- **Background mode implies `--skip-analysis`** — unattended `--background` runs never block on the gate or triage prompts.
- **Source / Rationale column and Triage Outcome subsection** — the synthesis template's (`references/output-template.md`) **Inline Edits to Apply** table gains a Source / Rationale column (originating reviewer plus why), with a Triage Outcome subsection placeholder beneath it for Step 7 Pass 2 to fill.
- **README documentation** — the plan-agent README now documents the `--skip-analysis` flag and the findings walkthrough.

### Changed

- **Step 7 Pass 1** — consumes `accepted_edits` when the walkthrough ran; the full-table fallback fires only for `--skip-analysis`, background mode, or the `Apply all` gate choice.
- **Step 7 Pass 2** — the appended Team Review now records triage outcomes (accepted / modified with revised content / rejected), and the Team Review is always appended even in review-only mode.

---

## 2.0.0 — Rename craft-prompt skill to refine-prompt (2026-06-10)

### Breaking

- **`craft-prompt` → `refine-prompt`** — the prompt-crafting skill is renamed to match its originating plan (`docs/plans/create-prompt-refiner-skill.html`). Invocation changes from `/plan-agent:craft-prompt` to `/plan-agent:refine-prompt`; the skill directory moves from `skills/craft-prompt/` to `skills/refine-prompt/`. Phases, interview flow, technique matrix, and templates are unchanged.

---

## 1.11.1 — Complete craft-prompt README documentation (2026-06-10)

### Fixed

- **README `craft-prompt` section** — the overview now hyperlinks [Anthropic's official Claude Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) guide (previously mentioned with no URL); the usage block gains a Before/After example showing a vague request ("write me a prompt to summarize stuff") transformed into the structured XML-layered prompt the skill produces; and a technique-matrix table (mirroring `skills/craft-prompt/SKILL.md`) now maps each prompt type (`system`, `task`, `creative`, `analytical`) to the best-practices techniques it applies.

---

## 1.11.0 — Review option in the plan exit step (2026-06-09)

### Added

- **`Review the plan` option in Step 8 exit menu** — every freshly-generated plan now offers a one-click path to the `review-plan` Agent Team. Selecting it presents a foreground-or-background sub-choice: foreground runs `Skill(skill: "plan-agent:review-plan", args: "<path>")` in-session and loops back to the menu after the review completes; background dispatches `Skill(skill: "plan-agent:review-plan", args: "<path> --background")` and returns to the menu immediately. Agent-Teams-unavailable hard-stop is handled gracefully — guidance is relayed and the menu is restored without crashing the flow. Plan status stays `todo` throughout reviewing.
- **`--background` flag for `review-plan` skill** — when present, the skill requires an explicit plan path, skips all `AskUserQuestion` prompts, defaults to update-in-place mode, and is safe for unattended execution.
- **`/plan-agent:review-plan-bg <path>` command** — thin background dispatcher that validates the plan path argument, spawns `agent-review-plan` with `run_in_background: true`, and returns an ack immediately.
- **`agent-review-plan` background agent** — fire-and-forget agent that confirms the plan file exists, invokes the `review-plan` skill with `--background`, and reports the updated path on completion. Runs on Sonnet with a 30-turn cap.

### Changed

- **Adaptive menu swap in Step 8** — the `AskUserQuestion` tool is capped at 4 options. When a workflow prompt is present, `Edit the plan` yields its slot to `Review the plan`: `Implement now` / `Run as workflow` / `Review the plan` / `Exit`. Without a workflow prompt all four options are present: `Implement now` / `Review the plan` / `Edit the plan` / `Exit`.

---

## 1.10.1 — Stable plan-created sort in auto-rebuild hook (2026-06-08)

### Fixed
- `hooks/build-index.sh`: replaced `os.path.getmtime` sort with `plan-created` meta sort so the auto-rebuild hook produces the same date-descending order as the `plans-library` skill. Editing a plan no longer promotes it to the top of the gallery.

## 1.10.0 — End-to-end self-verification gate (2026-06-08)

### Added

- **End-to-end verification gate in the implement-now flow** (`implementation-plan` Step 8) — after the acceptance-criteria gate and before the completion-checklist gate, Claude now runs the plan's objective-verification test plus the Verification section's end-to-end steps as a holistic check. On failure it diagnoses, fixes the source, and re-verifies in a bounded loop (up to 3 attempts), then asks the user how to proceed if still failing.
- **Objective-verification test run in `finalize-plan`** (Step 3c) — finalize-plan now executes the `.objective-test-card` **Run** command as an end-to-end pass/fail signal, surfaces the result in the findings summary, warns before completing on failure, and records failures in the Completion Report.

### Changed

- Consolidated unreleased changelog entries.

---

## Unreleased — Remove review artifact emission from review-plan

### Removed

- **Step 8 (Artifact)** — the skill no longer emits a standalone `*-review.html` file. All review findings are now placed directly into the source plan via the collapsible `<details class="team-review">` block appended in Step 7.
- **`SendUserFile`** removed from `allowed-tools` — no separate file is delivered.

### Changed

- **Step numbering** — cleanup is now Step 8 (was Step 9); total workflow steps reduced from 9 to 8.

---

## v1.9.0 — 2026-06-06 — Agent Team–based plan review skill

### Added

- **`/plan-agent:review-plan` skill** — new skill that spawns a seven-reviewer Agent Team (5 core + 2 UI-conditional) to review implementation plans, synthesize findings, apply improvements in place, and emit shareable HTML review artifacts. Detects UI signals (React, Vue, Svelte, buttons, modals, forms, etc.) and conditionally runs UX and accessibility reviewers when present.
- **Seven reviewer agent definitions** under `agents/`:
  - **Core reviewers** (always spawned): `plan-reviewer-architecture`, `-completeness`, `-testability`, `-risk`, `-conventions`
  - **UI-conditional reviewers** (spawned when UI signals detected): `plan-reviewer-ux`, `-accessibility`
- **Reference files** under `skills/review-plan/references/`:
  - **`role-prompts.md`** — seven lens-specific spawn prompts for Agent Team briefing, with template placeholders for plan path substitution.
  - **`output-template.md`** — synthesis report structure with Executive Summary, Role-by-Role findings, Agreements/Conflicts, Highest-Risk Issues, and the critical **Inline Edits to Apply** table that maps each improvement to a concrete HTML target element and action.
- **Agent Teams support** — hard-gates on `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` and Claude Code ≥ 2.1.32; requires feature flag and version check before spawning.

### Changed

- **Plugin description** — updated marketplace.json and plugin.json descriptions to include the new `review-plan` skill alongside `implementation-plan`, `finalize-plan`, and `craft-prompt` skills.
- **Version bump** — from 1.8.0 to 1.9.0 (MINOR bump per marketplace.md — new skill added).

---

## v1.8.0 — 2026-06-06 — Mandatory Tests section in implementation plans

### Added

- **Tests section** — every generated plan now includes a Tests section between Steps and Acceptance Criteria with a two-tier depth model: Tier 1 (code-touching plans) includes unit, integration, E2E, and objective-verification tests; Tier 2 (non-code plans) includes only the objective-verification test.
- **Objective-verification test** — mandatory for both tiers, renders as a green hero card (`.objective-test-card`) before the test list. Asserts the plan's stated objective is accomplished.
- **Test badge CSS** — `.test-badge-unit` (blue), `.test-badge-integration` (amber), `.test-badge-e2e` (purple), `.test-badge-objective` (green) with design-token-based colors.
- **`#ic-beaker` SVG icon** — added to the icon sprite sheet for the Tests nav link and section heading.
- **Purple design tokens** — `--purple`, `--purple-bg`, `--purple-border` added to `:root` for E2E badge styling.
- **Step 5c** — new test-generation workflow step that classifies the tier from step content, generates the objective-verification test from the plan objective, and produces unit/integration/E2E test entries for Tier 1 plans.

### Changed

- **`implementation-plan` SKILL.md** — Required Structure now includes `tests`; HTML Output Requirements document the Tests section rendering; Step 5c added to the workflow between Interview and Status.
- **`SKELETON.html`** — nav sidebar includes Tests link; Tests section HTML with tier label, objective-test card, and test-list placeholders.

---

## v1.7.0 — 2026-06-06 — Copyable plan file name and relative path in HTML output

### Added

- **Plan source block** — every generated plan now renders a `.plan-source` block below the implement/workflow rows with two copyable rows: the plan **File** name (basename) and its relative **Path**, each with a Copy button. Gives users the plan's name and relative URL to paste into docs and prompts. Stays visible when the plan is `completed`; hidden in print.
- **`plan-file` and `plan-path` meta tags** — added `<meta name="plan-file">` and `<meta name="plan-path">` to the plan `<head>` for machine readability.
- **`copyPath()`** helper in `SKELETON.html` to copy either field to the clipboard (with `execCommand` fallback).

### Changed

- **`implementation-plan` SKILL.md** — Step 2 now computes `{plan-filename}` and `{plan-path}` placeholders; Step 3 frontmatter and the HTML Output Requirements document the new meta tags and the plan source block.

---

## v1.6.0 — 2026-06-06 — Auto-generate Files file-tree from plan steps

### Added

- **File-Tree Auto-Generation** — new subsection in `implementation-plan` SKILL.md that automatically extracts file references from drafted steps, classifies each as `new`/`modified`/`deleted`/`generated` based on action verbs, groups by directory, and populates `{file-tree-rows}` — eliminating manual file-tree construction.

### Changed

- **`implementation-plan` SKILL.md** — the Files section (`section.card-files#files`) is now auto-generated instead of opt-in. Updated the Visual Sections heading, HTML Output Requirements, Visual Components table/rules, and Skeleton instructions to reflect the new behavior. File-tree is always included when ≥1 file is referenced; only deleted for purely conceptual plans.

---

## v1.5.1 — 2026-06-05 — Use portable plugin-dir path in README

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/plan-agent` path instead of an author-specific home directory.

---

## v1.5.0 — 2026-06-05 — Add visual components (file-tree, diagrams, charts, tables) to plan template

### Added

- **`reference/SKELETON.html`** — four opt-in, pure-CSS visual components, each shipped as a `<body>` block behind a removal comment (kept and filled when relevant, deleted with its sidebar nav link otherwise):
  - **File-tree** (`.file-tree`) — a `Files to Modify` section (`section.card-files#files`, between Context and Steps) listing files with `file-badge-new` / `file-badge-modified` / `file-badge-deleted` / `file-badge-generated` badges.
  - **Flow / pipeline diagram** (`.pipeline`) and **comparison grid** (`.compare-grid`, with `compare-col-add` / `compare-col-neutral` / `compare-col-remove` variants) — a `Diagram` section (`section.card-diagram#diagram`). Ported and generalized from the hand-authored components in `docs/plans/build-clean-plugin-dist.html`.
  - **Bar chart** (`.bar-chart`) — horizontal bars sized by an inline `style="--val:NN%"` custom property; script-free, with a visible `.bar-value` and a descriptive container `aria-label`.
  - **Data table** (`.plan-table`) — accessible table styling requiring `<caption>` and `<th scope="col">` headers.
- New `:root` tokens (`--green-border`, `--amber-bg`, `--amber-border`, `--red`, `--red-bg`, `--red-border`) so all visuals theme consistently; new `#ic-folder` icon symbol; conditional `Files` and `Diagram` sidebar nav links.

### Changed

- **`implementation-plan` SKILL.md** — documented the visual components: added an *Optional visual sections* subsection to **Required Structure**, an opt-in/accessibility bullet to **HTML Output Requirements**, a new **Visual Components** reference section (per-component triggers + rules), and a note in **Skeleton** that unused visual blocks are removed like `.plan-workflow`. All visuals stay pure CSS / inline SVG (no CDN); the gallery scanner is unaffected (it reads only meta tags + `<title>`).

---

## v1.4.1 — 2026-06-04 — craft-prompt: save prompt output to file

### Changed

- **`craft-prompt` SKILL.md** — added **Phase 7 — Save**: after delivering the prompt in Phase 6, the skill saves it as a markdown file with a `{type}-{intent-slug}-{YYYY-MM-DD}.md` filename and YAML frontmatter (`type`, `intent`, `techniques`, `created`). Output directory resolution (first match wins): (1) `promptsDirectory` from `.claude/settings.json` (project then global); (2) `{git-root}/docs/prompts/` anchored via `git rev-parse --show-toplevel`; (3) `docs/prompts/` relative to `$PWD` if not in a git repo. Includes a uniqueness guard: appends `-2`, `-3`, etc. if the target file already exists.
- `allowed-tools` extended with `Write`, `Bash(git *)`, and `Bash(mkdir *)` for repo-root detection, directory creation, and file save.

---

## v1.4.0 — 2026-06-04 — Add craft-prompt skill

### Added

- **`/plan-agent:craft-prompt [intent]`** — new skill (`disable-model-invocation: true`) that interviews users about their prompting need and generates a copy-pasteable AI prompt grounded in Anthropic's official Claude Prompting Best Practices.
  - **Phase 1 — Classify**: identifies the prompt type (system, task, creative, analytical) and applies a technique matrix mapping each type to its applicable best-practice layers.
  - **Phase 2 — Interview**: uses `AskUserQuestion` with type-specific questions derived from the technique matrix; always asks the user's *why* (per "Add context to improve performance"); offers progressive depth on user opt-in.
  - **Phase 3 — Structure**: maps interview answers to XML layers — `<role>`, `<instructions>`, `<constraints>`, `<context>`, `<example>`, `<thinking>`, `<document>` — applying only the techniques selected for the classified type.
  - **Phase 4 — Draft**: reads the appropriate template from `references/` (`system-prompt-template.md`, `task-prompt-template.md`, `creative-prompt-template.md`, `analytical-prompt-template.md`) and substitutes structured content into placeholders.
  - **Phase 5 — Recommend**: uses `ToolSearch` to surface 1–3 installed skills/agents that may achieve the goal directly, with invocation syntax and rationale.
  - **Phase 6 — Deliver**: presents the assembled prompt in a fenced block with technique header and tool recommendations.
- **`references/best-practices-reference.md`** — distilled summary of all eight core techniques from Anthropic's Claude Prompting Best Practices guide, organized by technique name with actionable implementation notes and applied-in phase references.
- **`references/system-prompt-template.md`** — parameterized template with `<role>`, `<instructions>`, `<constraints>` XML structure plus placeholder guide and assembled example.
- **`references/task-prompt-template.md`** — parameterized template with `<context>`, `<example>`, `<thinking>` scaffolding, CoT steps, and output format section; includes realistic refactoring example.
- **`references/creative-prompt-template.md`** — parameterized template with role assignment, voice description, context block, and style requirements; positive framing throughout.
- **`references/analytical-prompt-template.md`** — parameterized template with `<document>` grounding, `<thinking>` CoT, quote-extraction instruction, self-check, and output format.

---

## v1.3.2 — 2026-06-04 — Revert sort-by-created-date to mtime

### Fixed

- **build-index.sh**: reverts gallery sort back to filesystem mtime (newest-modified first); removes the `plan-created` metadata sort introduced in v1.3.1.
- **plans-library SKILL.md**: Step 3 reverts to `xargs ls -t` mtime sort; removes the collect-then-sort-by-created-date instruction from Step 4.

---

## v1.3.0 — 2026-06-04 — Rich implementation prompt with plan context

### Changed

- **SKELETON.html**: `copyCmd()` now calls `buildImplementPrompt()` which builds a concise action-oriented prompt from the plan's live DOM state — includes the short implement prompt, a status summary with step/criteria progress counts, and numbered instructions directing the implementer to read the plan, implement todo steps, verify criteria, and complete the checklist directly in the plan file.
- **SKELETON.html**: workflow prompt row converted from a static `<div>` to an expandable `<details>` element — collapsed by default with summary "Run as workflow — launch parallel subagents", reducing visual clutter while keeping the workflow option accessible.
- **SKILL.md Step 2**: documented the new "Full implementation prompt (Copy behavior)" paragraph explaining the DOM-driven rich prompt.
- **SKILL.md flags**: added `--workflow` flag to force workflow prompt generation, bypassing the complexity heuristic.

---

## v1.2.0 — 2026-06-04 — Make implementation-plan model-invocable

### Changed

- **`implementation-plan` skill**: removed `disable-model-invocation: true` — the skill is now both command-invocable (`/plan-agent:implementation-plan <objective>`) and model-invocable (auto-activates on plan-document intent).
- **`implementation-plan` description**: rewritten to a narrow, artifact-scoped three-part trigger ("generate an HTML implementation-plan document … Use when the user asks to create a plan document, generate an HTML plan, or write a plan file") that avoids colliding with built-in Plan Mode.
- **`implementation-plan` Invocation & Arguments**: documents both activation paths — command (with `$ARGUMENTS` and flags) and model (derives objective from conversation context, runs full workflow by default).
- **README.md**: updated all `implementation-plan` sections to reflect dual-mode activation; `finalize-plan` manual-only status unchanged.

---

## v1.1.0 — 2026-06-03 — Add mandatory completion checklist and report to plans

### Added

- **SKELETON.html**: new "Completion Checklist" section between Verification and Next Steps with three `disabled` checkboxes — (1) all step TODOs marked as done, (2) all acceptance criteria verified and checked, (3) plan status updated to `completed`. Checkboxes auto-update via JavaScript based on DOM state. Amber border transitions to green when all conditions are met.
- **SKELETON.html**: new "Completion Report" sub-section inside the checklist. Initially shows "No items to report"; populated with a `<dl>` detailing each incomplete item and the reason it could not be completed when the plan is finalized with unresolved items.
- **SKELETON.html**: new `ic-clipboard-check` SVG icon symbol and sidebar nav entry for the Completion section.
- **SKILL.md**: `completion-checklist` added to the Required Structure list as a mandatory (never-optional) section.
- **SKILL.md Step 8**: new "Completion checklist gate" runs after the acceptance criteria gate — verifies all three completion requirements, checks them off, and populates the Completion Report with specific details for any items that could not be completed.
- **finalize-plan SKILL.md**: new Steps 5d (completion checklist checkboxes) and 5e (completion report population) handle the checklist during plan finalization, with defensive skip when the section doesn't exist in older plans.

---

## v1.0.1 — 2026-06-03 — Pin implementation-plan skill to Opus model

### Changed

- **`implementation-plan` skill**: added `model: opus` to frontmatter so the skill always runs on the latest Opus model regardless of the session's default model.

---

## v1.0.0 — 2026-06-02 — Rename `complete-plan` skill to `finalize-plan`

### Breaking Changes

- **`complete-plan` → `finalize-plan`**: the skill directory and invocation path have changed. Update any existing invocations from `/plan-agent:complete-plan` to `/plan-agent:finalize-plan`. Functionality is identical.

---

## v0.23.2 — 2026-06-02 — Fix plans-open trigger ambiguity

### Fixed

- **`plans-open` description**: restored "without a rebuild" qualifier to the trigger phrase so it no longer overlaps with `plans-library`'s "browse plans" trigger, preventing mis-routing of first-time or rebuild-needed gallery requests.

---

## v0.23.1 — 2026-06-02 — Optimize skill descriptions to three-part format

### Changed

- Rewrote `description` fields in `complete-plan`, `implementation-plan`, `plans-library`, and `plans-open` to the three-part format (short label ≤80 chars + capability sentence + trigger phrase, total ≤200 chars) for improved skill discoverability.

---

## v0.23.0 — 2026-06-01 — Rename `planning` skill to `implementation-plan`

### Changed

- **Renamed the `planning` skill to `implementation-plan`.** Invocation is now `/plan-agent:implementation-plan <objective>` (previously `/plan-agent:planning`). The skill directory moved from `skills/planning/` to `skills/implementation-plan/`; all behavior, arguments, and workflow steps are unchanged. Update any saved commands or aliases that referenced the old name.

---

## v0.22.0 — 2026-06-01 — Add acceptance criteria verification gate

### Changed

- **`planning` Step 8 "Implement now"** — added mandatory acceptance criteria gate after all steps are implemented. Each criterion is individually verified against the codebase before being checked off. Unverifiable criteria are flagged to the user; the plan stays `in-progress` unless all criteria are checked.
- **`complete-plan` Step 3** — new sub-step 3b maps implementation evidence to individual acceptance criteria, classifying each as `verified` or `unverified`.
- **`complete-plan` Step 4** — summary now shows per-criterion verification status and offers three completion options: check all, only auto-check verified, or cancel.
- **`complete-plan` Step 5b** — respects the user's Step 4 choice: checks only verified criteria when the user opts to auto-check verified only, and downgrades status to `in-progress` accordingly.
- **`complete-plan` Step 6** — delivery message reflects whether all criteria were verified or some remain open.

---

## v0.21.0 — 2026-06-01 — Add /workflows support for complex plans

### Added

- **Workflow prompt row** — complex plans now include a `<div class="plan-workflow">` element below the implement prompt with a "Run a workflow to implement the plan at …" prompt and copy button. Triggers Claude Code's `/workflows` runtime when pasted, launching parallel subagent orchestration for large-scale implementations.
- **`<meta name="plan-workflow">` tag** — machine-readable workflow prompt in the plan `<head>` for gallery extraction.
- **`copyWorkflow()` JS function** — dedicated clipboard handler for the `<code id="workflow-cmd">` element.
- **Step 8 "Run as workflow" option** — when a workflow prompt was generated, the post-planning prompt offers a fourth choice to launch a dynamic workflow instead of sequential implementation.

### Changed

- **SKILL.md Step 2 (Create)** — now assesses plan complexity to decide whether to generate a `{workflow-prompt}` alongside `{implement-prompt}`. Workflow prompts are generated when plans touch 5+ files across 3+ directories, involve repetitive per-file changes, include parallelizable steps, or require cross-checking.
- **SKILL.md Step 3 (Frontmatter)** — includes `<meta name="plan-workflow">` when a workflow prompt was generated.
- **SKILL.md next-steps** — next-step prompts can now use "Run a workflow to …" prefix for items that benefit from workflow orchestration.
- **SKELETON.html** — added `.plan-workflow` CSS (blue accent), HTML row with `{workflow-prompt}` placeholder, and `copyWorkflow()` JS function. Row is conditionally removed when no workflow prompt is generated.
- **CLAUDE.md** — fixed branch naming example from `add-reinvoke-prompt` to `add-implement-prompt`.

## v0.20.0 — 2026-06-01 — Add complete-plan skill

### Added

- **`/plan-agent:complete-plan [plan-filename.html]`** — new skill (`disable-model-invocation: true`) that reviews an HTML plan for codebase implementation evidence, presents a confirmation summary, then marks all acceptance-criteria checkboxes as checked, adds the `completed` class to every step card, and updates all three status representations (`<html data-status>`, `<meta name="plan-status">`, visible badge) to `completed`.

---

## v0.19.0 — 2026-06-01 — Replace reinvoke prompt with implement prompt

### Changed

- **Plan output** — the copy/paste prompt below the objective now generates an implementation prompt (e.g. `Read and implement all steps in the plan at docs/plans/add-dark-mode-toggle.html`) instead of a re-invoke command that re-runs the planning skill
- **SKELETON.html** — `.plan-reinvoke` CSS/HTML/JS renamed to `.plan-implement` with green accent styling; label changed from "Re-invoke" to "Implement"
- **Meta tag** — `<meta name="plan-reinvoke">` replaced with `<meta name="plan-implement">`
- **SKILL.md** — Steps 2, 3, and HTML Output Requirements updated; `{reinvoke-cmd}` placeholder replaced with `{implement-prompt}`; scope constraint reordered to prioritize `plansDirectory` setting over hardcoded `docs/plans`

## v0.18.2 — 2026-06-01 — Add ExitPlanMode error handling; planning workflow improvements

### Fixed

- fix: add ExitPlanMode error handling — treat 'not in plan mode' error as success
- Remove auto-commit step from planning skill (step 6 removed)
- Add 'Edit the plan' option to post-planning prompt (step 8)

## v0.18.1 — 2026-06-01 — Fix reinvoke command: strip .html token before objective extraction

### Fixed

- **Argument parser — `.html` plan file detection**: A leading `.html` token (e.g. `add-dark-mode-toggle.html`) is now stripped from `$ARGUMENTS` before the objective is extracted, preventing the filename from polluting the objective when the re-invoke command is pasted verbatim. The stripped value is stored as `$PLAN_FILE`; when no remaining objective text exists, the plan's existing `<title>` tag is used as the objective fallback.

---

## v0.18.0 — 2026-06-01 — Add re-invoke prompt to every generated plan

### Added

- **Re-invoke prompt row** — every generated plan HTML now includes a `<div class="plan-reinvoke">` element immediately below the objective card. Shows the `/plan-agent:planning <filename> <short-objective>` command with a copy button so developers can resume or reference the plan without reconstructing the command.
- **`copyCmd()` JS function** — dedicated clipboard handler for the `<code id="reinvoke-cmd">` element, separate from the existing `copyPrompt()` which targets `<pre>` blocks.
- **`<meta name="plan-reinvoke">` tag** — machine-readable reinvoke command in the plan `<head>` for plans-library gallery extraction.

### Changed

- **`SKILL.md` Step 2 (Create)** — now instructs the model to compute `{reinvoke-cmd}` = `/plan-agent:planning <filename> <short-objective≤60chars>` and fill the skeleton placeholder.
- **`SKILL.md` Step 3 (Frontmatter)** — now requires `<meta name="plan-reinvoke" content="…">` alongside the other required meta tags.
- **`SKILL.md` HTML Output Requirements** — new bullet documents the reinvoke row as a required element.

### UX

- Reinvoke command text soft-wraps (`word-break: break-all`) for long objectives.
- Copy button is hidden via CSS when `data-status="completed"` — no copy affordance for plans that are done.
- Row is suppressed in `@media print`.

---

## v0.17.1 — 2026-06-01 — Minor wording corrections

### Fixed

- `planning` and `plans-library` skills: minor description wording corrections.

---

## v0.17.0 — 2026-05-31 — Add plans-open skill (open gallery without rebuild)

### Added

- **`plans-open` skill** — opens the existing `index.html` gallery directly without scanning plan files, parsing metadata, or writing any files. Resolves `plansDirectory` from settings (same as `plans-library`). If `index.html` does not exist, tells the user to run `/plan-agent:plans-library` first.

---

## v0.16.0 — 2026-05-31 — Fix Step 9 status sync and commit instructions

### Fixed

- **Step 9 `Implement now` — status sync**: Now updates all three status representations together (`<html data-status>`, `<meta name="plan-status">`, and visible badge text), mirroring Step 7's sync rules. Previously only `<meta name="plan-status">` was mentioned.
- **Step 9 `Implement now` — commit instruction**: Now explicitly commits source file changes together with the updated plan file. Previously only the plan file was mentioned, leaving source changes potentially uncommitted.
- **Step 9 `Exit` — state model clarity**: Clarifies that `todo` is the correct terminal state for an unimplemented plan and that no status update is needed on exit, resolving ambiguity with Step 7's `todo → in-progress → completed` progression.

---

## v0.15.0 — 2026-05-31 — Add issue ingestion to /plan-agent:planning

### Added

- **Issue reference detection** — `$ARGUMENTS` is now scanned for a GitHub/GitLab issue URL or bare `#n`/integer before flag parsing. When detected, the reference is stripped from the argument string and stored as `$ISSUE_REF`.
- **Step 0.5 — Issue Ingestion** — New workflow step that fires when `$ISSUE_REF` is set. Runs `gh issue view` (GitHub) or `glab issue view` (GitLab), maps `title` → objective, `body` → context block, `labels` → type hint, `url` → plan frontmatter. Falls back gracefully to plain-objective mode on any CLI error.
- **`<meta name="plan-issue">` tag** — Plans seeded from an issue reference now include the source issue URL in the HTML `<head>` for machine readability by the gallery index and downstream tooling.
- **`argument-hint` updated** — Now reads `<issue-url|#n> | <objective> [flags…]` to expose the new entry point at autocomplete time.

### Example

```
/plan-agent:planning https://github.com/shawn-sandy/agentics/issues/205
/plan-agent:planning #205
/plan-agent:planning #205 focus on the auth layer --quick
```

---

## v0.14.1 — 2026-05-31 — Fix MultiEdit path extraction and bundle build-index.sh

### Fixed

- **P2 — MultiEdit `file_path`**: `file_path` is a top-level key on `tool_input` for all tool types including `MultiEdit`; the previous code incorrectly read it from inside `edits[0]`, causing MultiEdit events to always produce an empty path and exit without rebuilding.
- **P1 — Bundle `build-index.sh` with plugin**: `docs/plans/build-index.sh` is not shipped inside the `plan-agent` plugin directory, so consumer projects that install via the marketplace had no rebuild script and the hook silently exited. Added `hooks/build-index.sh` (identical logic, accepts `PROJECT_ROOT` as `$1`) and updated the hook to prefer the bundled copy via `$CLAUDE_PLUGIN_ROOT`, falling back to a local `build-index.sh` in the plans directory for projects that have it.

---

## v0.14.0 — 2026-05-30 — Add PostToolUse hook to auto-rebuild plans index

### Added

- **`hooks/rebuild-plans-index.py`** — PostToolUse hook that fires on every `Write|Edit` to a non-`index.html` `.html` file inside the configured plans directory. Calls `docs/plans/build-index.sh` to regenerate the gallery index automatically. Always exits 0 so index-rebuild failures never block plan writes.
- **`docs/plans/build-index.sh`** — self-contained shell entry point that regenerates `docs/plans/index.html` without Claude. Finds the `plans-gallery.html` template via the same plugin-discovery strategy as `plans-library`; falls back to a minimal embedded styled gallery if the template is unavailable.
- Registered `rebuild-plans-index.py` as a second `PostToolUse` entry in `hooks.json` with `Write|Edit` matcher and a 30-second timeout.

## v0.13.0 — 2026-05-31 — Add plans-library skill and gallery template

### Added

- **`plans-library` skill** — scans the configured `plansDirectory`, parses each plan's metadata, and writes a filterable HTML gallery (`index.html`) with status/type chips, title search, and grid/list views. Opened in the browser on completion.
- **`plans-gallery.html` template** — standalone gallery template with versioned cache path, JSON-safe title parsing, and an explicit `GENERATED_AT` timestamp.

### Fixed

- **`plans-library` xargs** — replaced `xargs ls -t` with `xargs -0 ls -t` (null-delimited) to handle plan paths that contain spaces.
- **`plans-library` template discovery** — versioned cached templates are now sorted by version descending (`sort -rV`) before `head -1`, making the selection deterministic when multiple cached versions exist.
- **`planning` Step 0 bootstrap wording** — clarified that the `ToolSearch(select:ExitPlanMode)` preflight runs as part of Step 0 (not before it); removed the contradictory "before any other action" phrase.
- **`planning` preflight echo** — moved the resolved-objective echo to after the Step 0 bootstrap so no user output precedes `ExitPlanMode`.

---

## v0.12.1 — 2026-05-30 — Fix section sign rendering

### Fixed

- Replaced `§` (section sign) characters with plain text ("Step N", "Steps N–M") across SKILL.md, README.md, and CHANGELOG.md to fix rendering issues in terminals and markdown viewers.

---

## v0.12.0 — 2026-05-30 — Codebase exploration, Grep, and browser fallback

### Added

- **Step 0b Explore** — new codebase research step after the self-bootstrap and before Clarify. Uses `Glob`, `Grep`, and `Read` to build context on entry points, existing patterns, tests, and configuration before drafting steps. Exploration depth scales with plan scope. Skipped by `--quick`.
- **`Grep`** added to `allowed-tools` — enables first-class codebase symbol and pattern search without permission prompts during exploration and plan drafting.
- **Step 8 browser fallback** — when the browser MCP server is unavailable (headless/web environments), falls back to `SendUserFile` with the file path, ensuring plan delivery always works.

### Changed

- **Description tightened** — first sentence shortened to fit within the ≤80-char guideline.

---

## v0.11.2 — 2026-05-30 — Add scope constraint: plans only, no implementation

### Added

- **Scope Constraint section** — explicit rule block inserted before the Workflow prohibiting the skill from editing source files or applying any change described in the plan's steps. The plan is the deliverable; implementation is a separate, user-initiated step. Addresses a case where the skill implemented a fix rather than writing a plan for it.

---

## v0.11.1 — 2026-05-30 — Fix: self-bootstrap out of harness plan mode

### Fixed

- **Step 0 self-bootstrap** — Added unconditional `ExitPlanMode` call as the first step of the workflow. When the harness enters plan mode on "planning"-keyword commands it forces `.md` output to a random-slug path, overriding the skill's `.html` guarantee. Calling `ExitPlanMode` immediately exits harness plan mode so the skill writes directly to disk as designed. Root cause: v0.8.0 removed `ExitPlanMode` from `allowed-tools` but left no escape hatch for harness-triggered plan mode.
- **`allowed-tools`**: added `ExitPlanMode`, `WebFetch`, `WebSearch`, `SendUserFile`.

---

## v0.11.0 — 2026-05-30 — Add plans-library skill and web research tools

### Added

- **`plans-library` skill** — scans every HTML plan in the plans directory, parses `<meta>` tags (`plan-status`, `plan-type`, `plan-created`) and `<title>`, populates a gallery template, writes `docs/plans/index.html`, and opens it in the browser. Filterable by status (todo / in-progress / completed) and type (feature / fix / refactor / docs / chore) with a title search box. Excludes `index.html` and `archive/` subdirectory.
- **`templates/plans-gallery.html`** — self-contained gallery template (no external CSS/JS/CDN) with light theme; grid and list views; client-side filtering.
- **`WebFetch`, `WebSearch`, `SendUserFile`** added to `allowed-tools` — enables research during Clarify (verifying APIs, checking library versions) and delivers the finished plan file to the user in Step 8 Open.

---

## v0.10.0 — 2026-05-30 — Add built-in structured interview step

### Added

- **Step 5b Interview** — new standard workflow step between Align and Commit. Analyzes plan content to classify complexity (short/medium/complex), detects UI signals, then runs 1–3 interview rounds via `AskUserQuestion` with dynamically generated questions. Round 1 (Technical & Trade-offs) always runs; Round 2a (UI/UX) and 2b (Accessibility) run for medium+ plans or when UI signals are detected; Round 3 (Edge Cases) runs for complex plans only. Post-interview summary offers to update the plan HTML before committing.
- **`--no-interview` flag** — skips Step 5b Interview for pre-validated or time-critical plans.

### Changed

- **`--quick` expanded** — now shorthand for `--no-clarify --no-align --no-interview` (previously only `--no-clarify --no-align`).

### Removed

- **`--interview` flag** — the external delegation to `plan-interview:plan-interview` after Step 8 is replaced by the built-in Step 5b step. The `plan-interview` plugin remains available as a standalone deep-interview tool.

---

## v0.9.0 — 2026-05-30 — Add mandatory Step 8 Open step with browser verification

### Added

- **Step 8 Open** — new mandatory final workflow step that opens the committed plan in a browser to confirm it renders correctly. Steps: find a free port via `python3 -c "import socket…"`, start `python3 -m http.server <port>` in the background from the plan's parent directory, load browser tools via `ToolSearch`, navigate to `http://localhost:<port>/<plan-filename>`, take and send a screenshot, report the URL to the user, and leave the server running. Cannot be skipped.
- **`allowed-tools` expanded** — added `ToolSearch`, `mcp__claude-in-chrome__tabs_context_mcp`, `mcp__claude-in-chrome__tabs_create_mcp`, `mcp__claude-in-chrome__navigate`, and `mcp__claude-in-chrome__computer` so browser automation tools are pre-approved and never prompt mid-run.

---

## v0.8.0 — 2026-05-30 — Remove plan-mode handshake; tighten skill consistency

### Changed

- **Remove `EnterPlanMode`/`ExitPlanMode` handshake** — the skill now writes its HTML plan file directly instead of entering harness plan mode, restoring its two output guarantees: `verb-target` kebab-case filename and self-contained `.html` output. Root cause: `EnterPlanMode` handed control to the harness, which forced markdown to a random-slug path, contradicting the skill's own "no plan mode for write operations" rule.
- **`--template` flag**: trimmed to `default` only in `argument-hint`; `minimal`, `adr`, and `spike` are documented as planned but not yet implemented.
- **Skeleton variants deleted**: `reference/SKELETON-minimal.md`, `reference/SKELETON-adr.md`, `reference/SKELETON-spike.md` removed — they were markdown files and violated the "always write HTML" rule. `reference/SKELETON.html` remains the sole supported skeleton.
- **`allowed-tools`** pruned: `EnterPlanMode`, `ExitPlanMode`, `ToolSearch`, `TodoWrite`, and `Grep` removed (dead weight after plan-mode removal or unreferenced in body).
- **Heading hierarchy**: body H1 (`# Plan Agent — Planning`) lowered to H2.
- **Freedom level**: `## Workflow` opens with "Follow these steps exactly." to prevent guardrail-skipping on a process-critical sequential skill.
- **Frontmatter description**: rewritten with capability statement, user-intent trigger, and scope-exclusion sentence (≤1024 chars, third person).
- **`$ARGUMENTS` clarifying note**: added to `Invocation & Arguments` explaining why this command-only construct is valid here.

---

## v0.7.1 — README: correct --template flag docs; fix planAgent.extraFrontmatter key

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## 0.7.0 — 2026-05-29

### Added

- **Copy prompt buttons**: each `<pre>` prompt block in the Next Steps (including Wish List items) and Unresolved Questions sections now has a "Copy prompt" button. Clicking copies the prompt text to the clipboard; the button shows "Copied ✓" for 2 seconds then reverts. Uses the Clipboard API with a textarea fallback for `file://` protocol. Hidden in print.
- `copyPrompt` global JS function added to `SKELETON.html` (outside the IIFE so inline `onclick` handlers can resolve it).
- `.copy-prompt-btn` CSS class: blue-accent pill matching the document design tokens; green `.copied` state mirrors existing completion colours.
- SKILL.md updated to mandate copy buttons on every prompt `<pre>` in generated plans and to warn against removing them when filling placeholders.

---

## 0.6.0 — 2026-05-29

### Added

- **Sticky sidebar navigation**: two-column layout (200px sidebar + content) with "On this page" section links; collapses to single-column on narrow viewports.
- **Scroll rail**: animated 3px progress indicator on the left edge of the sidebar tracks page scroll position in real time.
- **Scroll spy**: `IntersectionObserver`-powered active link highlighting (left-border indicator) in the sidebar as sections enter the viewport.
- **CSS step timeline**: vertical connector line with circle nodes on each step card; nodes turn green when all criteria are checked (via CSS `.step-card.completed`).
- **Step chips**: `<span class="step-chip">todo</span>` decorates each step action with a pill badge; turns green when the step card is marked complete.
- **localStorage persistence**: acceptance-criteria checkbox state saved to `localStorage` keyed by page title — survives page refresh.
- **Print styles**: sidebar, scroll rail, and step chips hidden in print; single-column layout.
- **Inline SVG icons**: Heroicons `<symbol>`/`<use>` pattern replaces emoji; zero external dependencies.
- **Pulsing in-progress dot**: status badge dot pulses when `data-status="in-progress"`; respects `prefers-reduced-motion`.
- **Accessibility baseline**: skip link, `aria-labelledby` on every section, `role="progressbar"` attributes, `aria-live="polite"` region for criteria announcements, `min-height: 44px` touch targets on nav links.
- **Tone guidance in SKILL.md**: writing-style addendum encouraging rallying-statement objectives and imperative-verb step actions.

### Changed

- `SKELETON.html`: professional document aesthetic — white page, white header with a single 3px blue accent stripe, "Implementation Plan" doc-type label above the plan title.
- Sections rendered as flat ruled document sections separated by `border-top` lines (no card shadows or rounded corners).
- `<div class="section-card">` elements converted to `<section>` with `id` and `aria-labelledby` for improved semantics.
- Step number badges simplified to a plain grey circle (no gradient).
- Criteria items styled as individual bordered rows.
- Progress bar thinned to 6px with a solid blue fill.
- `--radius: 4px` throughout for a sharper document feel.

---

## 0.5.0 — 2026-05-28

### Added

- **HTML output** (default): the `planning` skill now writes every plan as a self-contained `.html` file — no markdown, no external dependencies.
  - Rich layout: status badge, objective highlight card, numbered step cards with expandable *Verify* disclosures, interactive acceptance-criteria checkboxes with live progress bar, collapsible Next Steps and Unresolved Questions sections.
  - **Wish List subsection**: blue-sky / visionary ideas in `next-steps` are automatically labelled `🔭 Wish List` and rendered with a distinct dashed-border, muted-colour treatment so they read as non-committal aspirations.
  - Plan metadata stored in `<meta>` tags (`plan-status`, `plan-type`, `plan-created`, `plan-repo`) for machine readability.
  - Minimal inline JavaScript (progress bar on checkbox change); fully functional without JS.
- `reference/SKELETON.html`: new bundled HTML plan template replacing `SKELETON.md` — all required sections pre-wired with placeholders in `{curly braces}`.

### Changed

- **Step 2 Create**: plan filename extension changed from `.md` to `.html`.
- **Step 3 Frontmatter**: metadata now stored in HTML `<meta>` tags instead of YAML frontmatter.
- **Step 7 Status**: status updates now edit `<html data-status="…">` and the badge element instead of YAML.
- `validate-plan-filename.py` hook updated to accept both `.html` (primary) and `.md` (legacy) plan files; `_is_completed` now reads `<meta name="plan-status" content="completed">` for HTML files.

### Fixed (in this release)

- Status `<html data-status="…">` attribute is on the `<html>` element (not `<body>`); SKILL.md Step 7 and CHANGELOG wording corrected to match the skeleton.
- SKILL.md Step 7 now instructs updating **both** `<html data-status>` and `<meta name="plan-status">` so CSS badge colour and the hook's completion check stay in sync.
- SKILL.md Step 3 no longer mentions a redundant `<script type="application/json" id="plan-meta">` block; `<meta>` tags are the sole metadata channel.
- SKELETON.html `<ul class="next-steps-list">` changed to `<div>` — `<details>` and `<div>` are not valid `<ul>` children per HTML spec.
- SKILL.md HTML Output Requirements now mandates HTML-escaping all user-supplied placeholder values (`&`, `<`, `>`, `"`, `'`).
- SKILL.md frontmatter description updated from "plan-mode frontmatter" to "HTML metadata".
- SKILL.md Step 7 cross-plugin note clarifies that `plan-interview:plan-status` operates on `.md`/YAML only and should not be used for HTML plans until updated.
- README.md updated to reflect HTML output, `SKELETON.html`, `.html` hook firing, and HTML metadata (replacing YAML frontmatter references).

---

## 0.3.0 — 2026-05-28

### Added

- **Hook extensibility** — `validate-plan-filename.py` now reads `planAgent.additionalVerbs`, `planAgent.additionalStopWords`, and `planAgent.additionalPlaceholders` from `.claude/settings.json` (project first, then global). Domain-specific verbs and custom extensions can be merged with the hardcoded sets without editing the Python source.
- **Plan templates** (`--template default|minimal|adr|spike`) — three new skeleton variants: `SKELETON-minimal.md` (Context + Steps + Criteria only), `SKELETON-adr.md` (Architecture Decision Record), `SKELETON-spike.md` (time-boxed investigation). Template selected at Step 2 Create.
- **`--no-clarify` flag** — skips Step 1 Clarify independently of Step 5 Align.
- **`--no-align` flag** — skips Step 5 Align independently of Step 1 Clarify.
- **`--priority` flag** (`low|medium|high|critical`) — writes `priority:` to plan frontmatter without requiring settings config.
- **`planAgent.extraFrontmatter` config** — project or global `.claude/settings.json` can inject arbitrary key-value pairs (e.g. `team`, `milestone`) into every plan's YAML frontmatter after the standard fields.

### Changed (non-breaking)

- `--quick` is now purely opt-in. The previous heuristic that auto-applied `--quick` for objectives ≥ 8 words with concrete names has been removed. `--quick` is documented as shorthand for `--no-clarify --no-align`.
- `argument-hint` updated to include all new flags.
- `classify_filename()` signature now accepts optional `verbs`, `stop_words`, and `placeholders` parameters (all default to module-level constants — backwards-compatible).

## 0.2.0 — 2026-05-27

### Changed (BREAKING)

- **Plugin renamed** `plan-mode` → `plan-agent`. Install id is now `plan-agent@agentics-kit`.
- **Skill renamed** `authoring-plans` → `author`. Explicit invocation is now `/plan-agent:author <objective>`.
- **Activation model changed**: `author` skill is now manual-invoke only (`disable-model-invocation: true`). It no longer auto-activates on planning intent — use `/plan-agent:author` explicitly.

### Added

- `$ARGUMENTS` parsing: reads a free-text objective plus flags (`--quick`, `--type`, `--dir`, `--interview`) from the invocation line.
- Smart `--type` inference from the leading verb of the objective when the flag is absent.
- Smart `--quick` inference for detailed, specific objectives.
- `EnterPlanMode` entry — the skill flips the session into real plan mode on invocation.
- `EnterPlanMode` added to `allowed-tools`.
- `--interview` flag: after the plan is written, optionally runs `plan-interview:plan-interview` before `ExitPlanMode`.

### Unchanged

- `validate-plan-filename` hook — logic, exit codes, and `hooks.json` registration are identical. Only the stderr citation was updated to reference `plan-agent` `/plan-agent:author`.
- Full Steps 0–7 workflow body, Required Structure, Writing Style, and Skeleton sections.

## 0.1.0 — 2026-05-27

### Added

- `authoring-plans` skill: auto-activating Plan Mode conventions covering the full Steps 0–7 workflow, required plan structure, and writing style
- `reference/SKELETON.md`: bundled plan skeleton with all required sections and per-step *Why*/*Verify* structure
- `validate-plan-filename.py` hook: `PostToolUse` enforcement of `verb-target` kebab-case plan filenames — rejects non-conforming names at write time (exit 2), skips `status: completed` plans
- `hooks.json`: registers the filename hook on `Write|Edit` events with a 5-second timeout
- Resolves `plansDirectory` from project `.claude/settings.json` first, global `~/.claude/settings.json` second, `docs/plans` as final fallback
