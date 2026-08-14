# plan-agent Plugin

Plan creation and completion as a Claude Code plugin — invoke `/plan-agent:implementation-plan <objective>` to run the full Steps 0–8 planning workflow on demand, or `/plan-agent:finalize-plan` to review and mark a plan completed.

## Overview

This plugin packages the Plan Mode workflow (Steps 0 through 8, ending in Implement/Edit/Exit), required plan structure, and writing style into the `implementation-plan` skill. The skill is both **command-invocable** (`/plan-agent:implementation-plan <objective>`) and **model-invocable** — it auto-activates when you ask to create a plan document, generate an HTML plan, or write a plan file. It does not activate on generic planning questions (those route to built-in Plan Mode). Accepts GitHub/GitLab issue URLs and `#n` references to auto-seed plans from backlog items, and `.md` plan paths to convert existing markdown plans into the HTML format.

Plans are written as **self-contained `.html` files** — interactive, visually rich, and openable directly in a browser. No markdown output. Complex plans include a workflow prompt for parallel subagent orchestration via Claude Code's `/workflows` runtime.

The `review-plan` skill uses an **Agent Team** (seven core reviewers plus three UI-conditional reviewers) to review implementation plans in parallel, synthesize findings, and apply improvements directly in place. Detects UI signals (React, Vue, buttons, modals, etc.) and conditionally runs UX, accessibility, and frontend reviewers when present. Requires Agent Teams feature flag and Claude Code ≥ 2.1.32.

The `finalize-plan` skill reviews a plan for codebase implementation evidence, verifies each acceptance criterion individually, and marks the plan completed.

It also ships two `PostToolUse` hooks: one enforces `verb-target` kebab-case filenames on plan files, and another auto-regenerates the plans gallery index when plans change.

Installers get on-demand planning with argument support, issue ingestion, built-in interviews, acceptance criteria verification, agent-team–powered review, and filename guardrails without maintaining a global `~/.claude/rules/plan-mode.md` file by hand.

## Features

| Component | Type | Activation |
|-----------|------|-----------|
| `implementation-plan` | Skill | Command (`/plan-agent:implementation-plan <objective>`) or auto-activates on plan-document intent |
| `build-proposal` | Skill | Command (`/plan-agent:build-proposal <idea>`) or auto-activates on idea / "should-we" / compare-and-align intent — converges on a saved prompt at `docs/prompts/proposal-<slug>.md` |
| `build-feature` | Skill | Command (`/plan-agent:build-feature <feature idea>`) or auto-activates on feature-doc / break-into-plans intent — converges on a feature doc at `docs/features/<slug>.md` plus per-sub-feature prompts at `docs/prompts/feature-<slug>-<sub-slug>.md` |
| `build` | Skill | Command (`/plan-agent:build [<plan>] [<objective>] [--type <kind>]`) or auto-activates on "implement / build this plan" intent — implements a plan and runs its gates; with no plan named, the command form authors one first through proposal → plan → review |
| `build-fleet` | Skill | Command (`/plan-agent:build-fleet [<plan> ...] [--max N]`) or auto-activates on "implement the backlog in parallel" intent — one worktree subagent per `todo` plan, each running `build` → `ship-autonomous` to a green PR |
| `fix` | Command | Typed entry point — `/plan-agent:fix <objective>` runs the `build` chain with `--type fix` |
| `refactor` | Command | Typed entry point — `/plan-agent:refactor <objective>` runs the `build` chain with `--type refactor` |
| `review-plan` | Skill | Manual only — invoke as `/plan-agent:review-plan [plan-path]` or auto-activates when you ask to review a plan (requires Agent Teams) |
| `review-plan-bg` | Command | Background dispatcher — invoke as `/plan-agent:review-plan-bg <path>` to run the review team without blocking |
| `finalize-plan` | Skill (`disable-model-invocation`) | Manual only — invoke as `/plan-agent:finalize-plan [plan-filename.html] [--all]` |
| `prompt` | Skill (`disable-model-invocation`) + Command | Invoke as `/plan-agent:prompt [type] [intent] [--out <path>] [--answers-gathered]`; a leading `system`/`task`/`creative`/`analytical` token pins the type. A fifth token, `proposal`, is caller-only — it counts just alongside `--answers-gathered`, since Phase 2 has no proposal question set. The command wrapper also makes it reachable from other skills, which the flag alone blocks |
| `plans-library` | Skill | Auto-activates on "browse plans", "view plan history", "open plans index" intent |
| `plans-open` | Skill | Auto-activates on "open the gallery", "show the plans page" — opens without rebuilding |
| `setup-sites` | Skill | Command (`/plan-agent:setup-sites`) or auto-activates on "set up / publish GitHub Pages" intent — scaffolds the deploy pipeline into any repo |
| `prototype` | Skill | Command (`/plan-agent:prototype <plan.html \| idea \| image \| figma-url>`) or auto-activates on "prototype this plan / idea / screenshot" intent — generates a runnable static-HTML prototype under `docs/prototypes/` |
| `dispatch` | Hook (`PostToolUse`) | The plugin's only registered hook. Fires on `Write`/`Edit`/`MultiEdit`, path-gates once, and fans out to the four below only for plan/prototype writes |
| `validate-plan-filename` | Child of `dispatch` | Validates plan filenames; exits 2 to block a badly-named plan |
| `rebuild-plans-index` | Child of `dispatch` | Regenerates the plans gallery for non-index `.html` plans |
| `build-prototypes-index` | Child of `dispatch` | Regenerates the prototypes gallery for `docs/prototypes/` writes |
| `check-prototype-drift` | Child of `dispatch` | Reports when a prototype has drifted from its own data model or its plan's copy |

**Built-in interview:** the planning workflow includes a structured interview step (Step 5b) that stress-tests your plan before committing. For deeper reviews, use the `review-plan` Agent Team. Note: `plan-agent:plan-status` currently operates on `.md`/YAML plans only and does not support `.html` plans yet.

## Installation

**Requires:** Claude Code 1.0.33 or later.

### Via Marketplace (recommended)

```bash
/plugin install plan-agent@agentics-kit
```

### Local Development

```bash
claude --plugin-dir ./kit/plugins/plan-agent
```

## Usage

### Skills

#### `implementation-plan` — Command or auto-activate

Creates implementation plans from a free-text objective. Enforces verb-target filenames, structure, and HTML metadata.

Invoke explicitly via `/plan-agent:implementation-plan <objective>`, or let it auto-activate when you ask to create a plan document, generate an HTML plan, convert a markdown plan to an HTML implementation plan, or write a plan file. Generic planning questions ("plan how to do X") route to built-in Plan Mode, not this skill.

```
/plan-agent:implementation-plan create a todo app for ravens
/plan-agent:implementation-plan fix the login redirect bug in auth middleware
/plan-agent:implementation-plan refactor the user settings module into smaller services
/plan-agent:implementation-plan docs/plans/distribute-skills-via-skill-box-catalog.md
```

At Step 8 the skill offers to open a tracking issue for the finished plan,
delegating to `git-agent:create-issue` with the plan as its source and
recording the resulting URL as the spec's `issue:` frontmatter key. The
renderer turns that key into a `plan-issue` meta tag and a header link on the
HTML, so the plan and its ticket stay reachable from each other. When the plan
is later marked `completed` — by `build`'s completion gate or by
`finalize-plan` — that link is what gets acted on: the skill offers to close
the ticket with a summary comment, or, if the plan lands `in-progress`
instead, posts the summary as a comment and leaves it open. It is
skipped when the spec already carries `issue:`, and if `git-agent` is not
installed the skill notes it in one line and continues — issue creation never
blocks the plan flow.

Passing a `.md` plan path enters **conversion mode**: the markdown is treated as authoritative, pre-validated content — Clarify/Align/Interview are skipped, sections map 1:1 to the HTML structure, frontmatter (`created`, `status`) carries over, the output filename swaps the extension to `.html`, and Step 8 asks whether to keep or remove the source `.md`. If the path is missing locally, the skill checks the plan roots and the default branch before asking for direction.

**Full invocation syntax:**

```
/plan-agent:implementation-plan <issue-url|#n> | <plan.md> | <objective> [--quick] [--no-clarify] [--no-align] [--no-interview] [--workflow] [--tdd|--no-tdd] [--from-prompt <path>] [--type feature|fix|refactor|docs|chore] [--template default] [--dir <path>] [--priority low|medium|high|critical]
```

**Flags:**

| Flag | Effect |
|------|--------|
| `--quick` | Shorthand for `--no-clarify --no-align --no-interview`; skip Step 1, Step 5, and Step 5b |
| `--no-clarify` | Skip Step 1 Clarify only |
| `--no-align` | Skip Step 5 Align only |
| `--no-interview` | Skip Step 5b Interview (built-in structured interview) |
| `--from-prompt <path>` | **Prompt-source mode.** Read a saved proposal prompt for context, then author through the normal drafting workflow. Not conversion mode: proposal headings are input, not a step list to transcribe. Passing the same path positionally instead would trigger conversion mode, which is the bug this flag exists to prevent; the two are mutually exclusive and an ambiguous mix is rejected |
| `--type <kind>` | Set plan `type` in HTML metadata (`feature`, `fix`, `refactor`, `docs`, `chore`) |
| `--template <name>` | Reserved — only `default` is currently supported; additional variants are planned |
| `--dir <path>` | Override directory resolution; write the plan to this path |
| `--priority <level>` | Write `priority` to plan HTML metadata (`low`, `medium`, `high`, `critical`) |
| `--workflow` | Always generate a workflow prompt, bypassing the complexity heuristic (writes `workflow: always`) |
| `--tdd` | Force the RED/GREEN/VERIFY/SHIP phase shape, skipping the Step 2 detection |
| `--no-tdd` | Suppress it — draft single-pass steps with the normal Tests section |

**Examples with flags:**

```
/plan-agent:implementation-plan --quick --type fix patch the login redirect
/plan-agent:implementation-plan --no-clarify add dark mode toggle
/plan-agent:implementation-plan --dir tmp/plans add dark mode toggle
/plan-agent:implementation-plan --no-interview fix a config typo
/plan-agent:implementation-plan --workflow migrate all API endpoints to v2
/plan-agent:implementation-plan add SSO to the admin console --from-prompt docs/prompts/proposal-admin-sso.md
```

**Smart defaults when flags are absent:** `--type` is inferred from the leading verb (`add`/`create`/`build` → `feature`; `fix`/`patch` → `fix`; `refactor`/`rename` → `refactor`; `document`/`docs` → `docs`). All skip-flags (`--quick`, `--no-clarify`, `--no-align`, `--no-interview`) and `--workflow` are opt-in only and are never inferred automatically.

**Red-green-verify detection:** unlike the skip-flags, the RED/GREEN/VERIFY/SHIP shape *is* inferred. Step 2 applies it when the plan's steps touch application source and Step 0b found a test runner; it skips it for docs, plans, and metadata work, which has nothing to fail. Borderline cases — Tier 1 with no runner, config-only edits, spikes — trigger a single `AskUserQuestion` rather than a guess. `--tdd` and `--no-tdd` settle it without asking. See `guidelines/red-green-verify.md` for the per-phase step content, the 8-iteration GREEN cap, the DOM-assertion rule for UI work, and the foreground Node driver that replaces `&`/`nohup`.

The skill enforces the full Steps 1–8 workflow:

1. **Clarify** — resolves ambiguous requirements (skipped with `--quick`)
2. **Create** — places the plan in the right directory with a `verb-target.html` filename
3. **Frontmatter** — writes HTML `<meta>` tags: `plan-status`, `plan-type`, `plan-created`, `plan-repo`, `plan-file`, `plan-path`
4. **Rename** — ensures the filename is meaningful before committing
5. **Align** — confirms each step matches the objective (skipped with `--quick`)
5b. **Interview** — structured interview to stress-test the plan (skipped with `--quick` or `--no-interview`)
6. **Commit** — commits the plan alongside related changes
7. **Status** — tracks `todo` → `in-progress` → `completed` via `<html data-status>` and `<meta name="plan-status">`
8. **Open** — opens the plan in a browser and presents a next-action menu: **Implement now**, **Run as workflow** (complex plans), **Review the plan**, **Edit the plan**, or **Exit**

**Step 8 exit menu — Implement now option:**

`Implement now` triggers a this-session-or-fresh-session sub-choice:

- **This session:** invokes `Skill(skill: "plan-agent:build", args: "<spec path>")` and builds immediately, with the whole planning conversation still loaded.
- **Fresh session:** sets status to `in-progress`, prints the implement prompt, and stops so you can `/clear` and paste it into a clean context window. The prompt names the markdown spec, and the spec carries the whole plan, so nothing from the planning conversation is lost. Claude cannot clear its own context — `/clear` is a client command you type.

**Step 8 exit menu — Review the plan option:**

The exit menu always offers `Review the plan` as a one-click path to critique the freshly-generated plan before implementing it. Selecting it triggers a foreground-or-background sub-choice:

- **Run now (foreground):** invokes `Skill(skill: "plan-agent:review-plan", args: "<plan path>")`, runs the ten-reviewer Agent Team in-session, then re-renders the updated plan and loops back to the menu.
- **Background:** invokes `Skill(skill: "plan-agent:review-plan-bg", args: "<plan path>")`, dispatches the review team detached via `agent-review-plan`, and returns to the menu immediately; reopen the plan after completion to view applied updates.

**Adaptive menu swap:** The `AskUserQuestion` tool is capped at 4 options. When a workflow prompt is present the menu would otherwise have 5 slots, so `Edit the plan` is dropped from that variant — the full ordering becomes: `Implement now` / `Run as workflow` / `Review the plan` / `Exit`. Without a workflow prompt all four options appear: `Implement now` / `Review the plan` / `Edit the plan` / `Exit`.

If Agent Teams are unavailable (Claude Code < 2.1.32 or `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` unset), selecting `Review the plan` surfaces `review-plan`'s guidance and returns to the menu without crashing the planning flow. Plan status stays `todo` throughout — reviewing is not implementing.

### HTML plan output

Every plan is a single self-contained `.html` file (no CDN links, no external assets):

- **Compute-on-read spec** — the visible plan DOM is the single source of truth; `node <path-to-plan-agent-plugin>/scripts/extract-plan-spec.mjs <plan>` derives a spec-only markdown rendition on demand (objective, context, files, steps with why/verify, tests, acceptance criteria, verification) — a few thousand tokens of spec instead of the full ~21k styled HTML. New plans embed nothing; legacy plans that still carry a `<script type="text/markdown" id="plan-digest">` block are read from it verbatim (un-guarded). Status, checkbox, and progress state are never part of the spec
- **Status badge** — colour-coded: grey = todo, amber = in-progress, green = completed
- **Objective card** — prominent highlighted block at the top
- **Implement prompt** — Copy button produces a concise action-oriented prompt with plan status, step/criteria progress counts, and numbered instructions to implement directly from the plan file
- **Goal prompt** *(expandable)* — collapsible "Pursue as goal" section that reveals an outcome-driven prompt ("Achieve this goal: … — use the plan as reference, but optimize for the outcome"), giving the implementer latitude to deviate from the steps when a better path to the same outcome exists. **Always present** — every plan gets one, no flag required. On plans that also get a workflow prompt, it adds "Fan out across parallel subagents where that serves the outcome" after the latitude clause and the section is labelled "Pursue as goal — optimize for the outcome, in parallel", so fan-out is offered as a license the goal grants rather than a method fixed before the work is understood. References the plan by path like the implement prompt — self-contained, no repo-local script required
- **Workflow prompt** *(expandable)* — collapsible "Run as workflow" section that reveals a copy-paste prompt for parallel subagent orchestration via `/workflows`. Generated automatically only when the plan touches 4+ files across 2+ top-level directories. The other complexity triggers — repetitive per-file changes, parallelizable steps, adversarial review needs — are not detected automatically; opt in with `--workflow` or `workflow: always`
- **Step cards** — numbered, each with an expandable *Verify* disclosure
- **Interactive checkboxes** — acceptance criteria the user can tick in the browser, with a live progress bar
- **Wish List** — blue-sky / visionary next-steps rendered with a distinct dashed-border treatment
- **Collapsible sections** — Next Steps and Unresolved Questions use `<details>` for progressive disclosure
- **Prototype link** *(conditional)* — when the spec's frontmatter carries a `prototype:` key (a repo-relative path, written by `/plan-agent:prototype`), the header actions row gains a **View prototype** link and the `<head>` gains `<meta name="plan-prototype">`. The href is computed with `path.relative()` from the rendered plan's own output directory, so it resolves from a custom or nested `plansDirectory` — never a hard-coded `../prototypes/`. The plans gallery reads the same meta tag and shows a text-bearing `prototype` chip on the card. A spec without the key renders exactly as before

Open the `.html` file directly in any browser. No server required.

#### Extracting the spec

Read a plan's spec without paying for the styled HTML:

```bash
# Run from your own shell, with a literal path to the installed plugin.
# Claude Code's Bash tool rejects commands containing shell expansion, so an
# agent cannot invoke this via a plugin-root variable — see CHANGELOG 8.2.1.
#
# Resolve exactly one script first: the cache can hold several plan-agent
# versions (and several marketplace copies), and a bare glob would expand to
# every match — node would run the first and silently read the second as the
# plan path. Sorting on the version segment (not the whole path) is what makes
# newest actually win: 8.10.0 must beat 8.9.0 even under a later marketplace
# directory. Newest version wins, as the gallery hook also does.
EXTRACTOR="$(ls -1 ~/.claude/plugins/cache/*/plan-agent/*/scripts/extract-plan-spec.mjs 2>/dev/null \
  | awk -F/ '{print $(NF-2)"\t"$0}' | sort -V | tail -1 | cut -f2)"
# PLAN.html is a stand-in for your plan's filename — angle-bracket placeholders
# cannot be used here, since the shell reads `<` as an input redirection.
node "$EXTRACTOR" docs/plans/PLAN.html
```

The extractor reads an embedded `#plan-digest` block when one is present (legacy plans, un-guarded to clean markdown) and otherwise derives the spec from the visible DOM — so every plan resolves the same way, old or new. Each plan is a single self-contained HTML file, so the implement, goal, and workflow prompts it ships reference the plan **by path** — Claude reads the HTML directly, with no dependency on this script in the target repo. The extractor is a token-efficiency tool for callers that have it on hand (the review team, or manual inspection): roughly an order of magnitude fewer tokens than the full styled HTML, with a full-HTML fallback when it isn't available. **Caveat:** new plans embed no digest, so the old `awk '…id="plan-digest"…'` one-liner returns empty on them — use the extractor (or read the HTML) instead. Legacy embedded plans can still be re-seeded with `node scripts/backfill-plan-digests.mjs [--dry-run]` (idempotent; skips plans it cannot fully parse rather than emitting partial digests).

#### `review-plan` — Manual invoke or auto-activate

Reviews implementation plans using a ten-reviewer Agent Team (seven core reviewers plus three UI-conditional reviewers). Detects UI signals and conditionally spawns UX, accessibility, and frontend reviewers when present. Synthesizes findings and applies improvements directly to the source plan in place.

Reviewers read the full plan HTML. They are scoped to `Bash(git *)` and do **not** run the spec extractor: Claude Code's Bash tool rejects any command containing `${...}` shell expansion before permission rules are consulted, so a `${CLAUDE_PLUGIN_ROOT}`-anchored invocation is unrunnable by any agent at any permission level — no `tools:` grant can enable it. To get the cheaper spec read, run the extractor yourself with a literal path (see above) and paste the output into the review. See CHANGELOG 8.2.1.

**Requires:** Agent Teams enabled (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `~/.claude/settings.json`) and Claude Code ≥ 2.1.32.

```
/plan-agent:review-plan
/plan-agent:review-plan add-dark-mode-toggle.html
/plan-agent:review-plan --dir docs/plans/
/plan-agent:review-plan docs/plans/add-dark-mode-toggle.html --background
/plan-agent:review-plan docs/plans/add-dark-mode-toggle.html --skip-analysis
/plan-agent:review-plan docs/plans/add-dark-mode-toggle.html --triage-top 3
```

**Background mode (`--background`):** When the flag is present, the skill requires an explicit plan path, skips all interactive prompts, and defaults to update-in-place. Safe for unattended execution. Typically invoked via the `/plan-agent:review-plan-bg` command rather than directly.

**Findings walkthrough:** By default, after the team synthesizes findings, the skill presents an ask-first gate with three options: `Walk through findings` / `Apply all` / `Review only`. Walking through triages each finding individually — Accept / Modify / Reject — batched at most 4 per prompt, with each finding shown alongside its source reviewer and rationale. Choosing Modify defers revisions to a single post-walkthrough edit pass where you revise the kept edits directly in the plan.

- `--skip-analysis` — bypasses the gate and walkthrough entirely, preserving the previous auto-apply behavior
- `--triage-top <N>` — individually triages only the N highest-risk findings and batch-accepts the rest
- `--background` — implies `--skip-analysis`, so unattended runs never block on a prompt

#### `review-plan-bg` — Background command

Dispatches the `agent-review-plan` background agent to run the full ten-reviewer team without blocking the session. Returns an ack immediately; you are notified when it completes.

```
/plan-agent:review-plan-bg docs/plans/add-dark-mode-toggle.html
```

The skill spawns the following reviewers:

- **Core reviewers** (always spawned):
  - Architecture — component boundaries, layer separation, system integration, design patterns
  - Completeness — step specificity, file coverage, acceptance criteria clarity, verification feasibility
  - Testability — test coverage, test specificity, objective-verification test, acceptance criteria verifiability
  - Risk — breaking changes, data safety, concurrency, dependency hazards, rollback feasibility
  - Conventions — naming, file organization, code style, dependency organization, testing patterns

- **UI-conditional reviewers** (spawned only when UI signals detected):
  - UX — user flows, error states, loading states, interaction clarity, responsive design, discoverability
  - Accessibility — WCAG 2.1 AA compliance, keyboard navigation, screen reader support, semantic HTML, motion

**UI signal detection:** Scans the plan HTML for references to React, Vue, Svelte, `.tsx`/`.jsx`/`.css`/`.html`, `className`, `style`, Tailwind, buttons, modals, forms, dialogs, dropdowns, pages, components. If 2+ signals or UI-specific keywords are found, the UX, accessibility, and frontend reviewers are spawned.

The workflow:

1. **Resolve** — locates the HTML plan (`--dir` override, or glob `docs/plans/*.html` excluding `index.html`, or newest recent)
2. **Verify** — confirms Agent Teams are available (feature flag + version check)
3. **Detect** — scans plan HTML for UI signals to determine reviewer roster
4. **Spawn** — creates the team and spawns 7 core + optional 3 UI reviewers in parallel
5. **Collect** — waits for all reviewers to report findings
6. **Synthesize** — aggregates findings into a structured report (Executive Summary, Role-by-Role, Agreements/Conflicts, Highest-Risk Issues)
7. **Update** — applies inline edits to the plan HTML (step refinements, criteria corrections, verification improvements) and appends a collapsible "Team Review" section
8. **Cleanup** — tears down the Agent Team

On success:

```
Reviewing plan: docs/plans/add-dark-mode-toggle.html
UI signals detected — running 10 reviewers
Plan updated in place: docs/plans/add-dark-mode-toggle.html
```

#### `finalize-plan` — Manual invoke only

Reviews a plan for codebase implementation evidence, verifies each acceptance criterion individually, runs the plan's objective-verification test as an end-to-end signal, then marks the plan as completed. Each criterion is classified as `verified` or `unverified` based on actual codebase evidence. Offers three completion options: check all criteria, only auto-check verified ones, or cancel.

```
/plan-agent:finalize-plan add-dark-mode-toggle.md
/plan-agent:finalize-plan
/plan-agent:finalize-plan --all
```

When invoked without arguments, prompts for the plan file. The skill:
1. Reads the plan's acceptance criteria
2. Searches the codebase for implementation evidence per criterion
3. Runs the objective-verification test (the Tests section's **Run** command) for an end-to-end pass/fail signal
4. Presents a summary showing which criteria are verified vs unverified, plus the objective-test result
5. On confirmation: writes the completion state to the plan's **Markdown spec** (`status:` frontmatter, `- [x]` criteria flips, `[x]` step markers, a `## Completion Report` section when gaps remain) and re-renders the HTML with `build-plan-html.mjs` — the renderer derives the checked boxes, completed step cards, status representations, and completion checklist. Legacy plans without a sibling spec fall back to direct HTML attribute edits.

**Sweep mode (`--all`)** finds plans that are implemented but never marked completed. It scans the plans directory for every plan carrying a `<meta name="plan-status">` tag whose value is `todo` or `in-progress` (non-plan HTML without the tag is ignored), runs the cheap token-evidence scan on each, and presents a candidate table — plans with 80%+ evidence are flagged as "done but not marked". One multi-select prompt picks which plans to finalize (plus a single criteria mode for the whole batch); full per-criterion verification and the objective test then run only on the selected plans before the status writes.

####  `prompt` — Manual invoke only

Interviews users about their prompting need and generates a copy-pasteable AI prompt grounded in [Anthropic's official Claude Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices). Applies the right combination of techniques (clarity, XML structure, role assignment, few-shot examples, chain-of-thought scaffolding, and output formatting) based on the classified prompt type.

```
/plan-agent:prompt
/plan-agent:prompt system prompt for a customer support chatbot
/plan-agent:prompt refactor Python code task prompt
```

**Before / after** — a vague request in, a structured prompt out:

Before:

```
write me a prompt to summarize stuff
```

After (classified as `task` — clarity, XML structure, CoT scaffolding, and output format applied):

```text
Summarize the meeting notes below in exactly 3 bullet points for a busy engineering manager.

<context>
The summary feeds a weekly status email. Missing a blocker is worse than
including an extra detail.
</context>

<thinking>
Before answering, list every decision, blocker, and date in the notes.
</thinking>

<example>
- API migration blocked on pending auth review
- Launch date moved to July 14
- Q3 roadmap approved
</example>

Output format: exactly 3 bullets, each under 20 words, blockers first.
```

The skill runs a six-phase pipeline:

1. **Classify** — identifies the prompt type (system, task, creative, analytical) and selects the applicable technique matrix
2. **Interview** — gathers context with type-specific `AskUserQuestion` batches; always asks the user's *why*; offers progressive depth
3. **Structure** — maps interview answers to XML layers (`<role>`, `<instructions>`, `<constraints>`, `<context>`, `<example>`, `<thinking>`, `<document>`) — only techniques from the matrix
4. **Draft** — reads the matching template from `references/` and substitutes structured content into placeholders
5. **Recommend** — uses `ToolSearch` to surface 1–3 installed skills/agents that may achieve the goal directly
6. **Deliver** — presents the assembled prompt in a fenced block with technique header and recommendations

**Technique matrix** — which best-practices techniques each prompt type applies:

| Prompt type | Applied techniques |
|-------------|--------------------|
| `system` | Role assignment, XML structure (`<instructions>`, `<constraints>`), output format, guardrails |
| `task` | Clarity/directness, XML structure (`<context>`, `<example>`), thinking/CoT scaffolding, output format |
| `creative` | Role assignment, tone/voice instructions, context/motivation, output format, positive framing |
| `analytical` | Long-context patterns (`<document>`, `<quote>`), thinking/CoT, self-check, output format |
| `proposal` | Long-context grounding (`<context>`, `<finding>`, `<decisions>`), comparison tables, positive framing, output format |

Invoke only via `/plan-agent:prompt` — auto-activation is disabled because "prompt" is too common a word in coding contexts. `disable-model-invocation: true` blocks *programmatic* `Skill()` invocation too, not merely ambient activation, so a thin `commands/prompt.md` wrapper exists to let other skills reach it; the flag stays on. The wrapper **reads `skills/prompt/SKILL.md` by path rather than delegating with `Skill(skill: "plan-agent:prompt")`**: the command shadows the skill of that name, so delegating would return the wrapper again and none of the seven phases would load.

**Core plus references.** The skill body is a 343-line core; the per-run detail loads on demand from `references/` — `best-practices-reference.md` (the authoritative technique catalog, led by section 0's Claude 5 calibration), `interview-questions.md` (Phase 2's four type-specific question sets), `structuring-and-drafting.md` (Phase 3's seven generic XML layers, Phase 4's path resolution and writing rules), `saving-prompts.md` (Phase 7's directory precedence and filename derivation), plus the five `<type>-prompt-template.md` files. A single run reads section 0, one question set, and one template.

**Drafting is calibrated for Claude 5 generation models.** Phase 3 reads section 0 of `best-practices-reference.md` before choosing layers, built from [the new rules of context engineering](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models). The technique matrix still selects *which* layers apply; section 0 decides how much each earns — trust over constraint, one authoritative source per instruction, an output contract in place of stacked examples, and hard constraints only at boundaries that are genuinely critical. Phase 4 then runs a calibration pass over the assembled draft: cut duplicated instructions, drop scaffolding the interview never asked for, and prefer a schema, failing test, or mockup over prose describing one. Every template slot still ships, but `system`'s `<constraints>` block and `task`'s `<example>` and `<thinking>` blocks are optional — deleted rather than filled with an invented guardrail or filler reasoning step. Pinned by `tests/plugins/test-prompt-calibration.sh`. What stays in the core is what `tests/plugins/test-write-prompt-proposal-type.sh` pins per phase: the `--out` contract, the living-document rules, the proposal framing line, the clarify-menu exclusion, the `--answers-gathered` bypass, and Phase 3's proposal-grounding layer.

**A leading type token pins the type.** If the first token of `$ARGUMENTS` exactly matches one of the four author-facing type names, that is the type and Phase 1 does not infer — `/plan-agent:prompt creative a bedtime story about a lighthouse keeper`. Bare intent text still infers as before. The fifth name, `proposal`, is honoured only when `--answers-gathered` rides along; typed alone it falls through to the clarify menu, because its interview cannot run without a caller supplying the answers. The type token and both flags are stripped before the remaining text is read as the intent.

**An inferred type is confirmed before Phase 2.** The type selects the technique matrix *and* the whole type-specific question set, so a wrong type means the wrong interview, discovered only after it has been answered. Exactly one `AskUserQuestion` fires: the four-option clarify menu when the input does not clearly match a type, or — when it does — a four-option gate offering **Looks right** plus the three other author-facing types, so changing the type needs no second question. Both are skipped when the type arrived as a leading token, or when `--answers-gathered` is present. In a non-interactive session the skill proceeds rather than blocking — Phase 2's interview needs the same tool — and lists the assumed answers as a correctable table.

**The `proposal` type is caller-driven.** It is never offered in the clarify menu — `plan-agent:build-proposal` names it explicitly, passing the proposal content plus two flags:

| Flag | Effect |
|------|--------|
| `--out <path>` | Write to exactly this path, overriding Phase 7's own directory resolution **and** its 3-5 word intent-slug derivation. The caller dictates the path so both sides agree by construction rather than by coincidence. |
| `--answers-gathered` | Skip the Phase 2 interview entirely — zero `AskUserQuestion` calls. The caller already resolved every decision with the human. |

Proposal prompts are living documents: they carry `status:` (`gathering` | `converged`), `modified:`, and `generated-sha:` frontmatter, use the date-free filename `proposal-<slug>.md`, and are rewritten **in place** on later rounds. Before overwriting, the skill compares the body's sha256 against the recorded `generated-sha:` and asks first when they differ — a hand edit. The check is anchored to that key rather than to a git baseline because `build-proposal` only *offers* to commit each round, so an uncommitted previous round would otherwise look hand-edited every time.

#### `plans-open` — Auto-activates

Opens the existing plans gallery (`index.html`) directly without scanning, parsing, or writing any files. If `index.html` does not exist, tells the user to run `/plan-agent:plans-library` first.

```
open the plans gallery
show the plans page
```

#### `setup-sites` — Command or auto-activate

Scaffolds the GitHub Pages deploy pipeline into the **current repo** so anything generated under `docs/` (plan galleries, social cards, any static HTML) publishes to a public URL. Drops four idempotent artifacts — `.github/workflows/deploy-pages.yml`, `docs/.nojekyll`, a parameterized landing hub `docs/index.html`, and `scripts/serve-docs.sh` — without clobbering files that already exist. Computes the live `https://<owner>.github.io/<repo>/` URL from the `origin` remote, warns when `plansDirectory` points outside `docs/`, and guides the one-time **Settings → Pages → Source → GitHub Actions** step. It scaffolds and verifies only — you commit and push when ready.

Invoke explicitly via `/plan-agent:setup-sites`, or let it auto-activate:

```
set up GitHub Pages for this repo
publish my plans to GitHub Pages
```

#### `prototype` — Command or auto-activate

Turns a completed HTML plan, a one-line idea, an image (screenshot/mockup), or a Figma design into a runnable static-HTML prototype under `docs/prototypes/` so you can click through the real data shapes and core flow before writing production code. The prototype is one self-contained file — inline CSS + vanilla JS, an inline JSON seed, and a per-prototype `localStorage` store — with **no CDN, no framework, no build**, so it opens by double-click on `file://` and publishes to GitHub Pages. Output is HTML-escaped and rendered via `textContent`, and the skeleton bakes in labeled inputs, a semantic table, real buttons, form validation, a confirm-guarded reset, and an `aria-live` status region. A `PostToolUse` hook auto-rebuilds the Prototypes gallery, reachable from the docs hub.

```
/plan-agent:prototype docs/plans/add-fitness-tracker.html
/plan-agent:prototype "track gym workouts"
/plan-agent:prototype ~/Desktop/dashboard-mockup.png
/plan-agent:prototype https://figma.com/file/...
prototype this plan
```

Given a plan path it extracts the data model directly; given a raw idea it runs a 3-question interview (entity, action, success signal). Given an **image** it reads the mockup/screenshot and infers the model from the UI shown; given a **Figma URL** it loads the Figma MCP tools to read a screenshot + layer metadata and infers the same way (asking for a screenshot if no Figma MCP server is connected). It then echoes the derived model back for confirmation and writes `docs/prototypes/<verb-target>.html`.

#### `build` — Command or auto-activate

Implements a plan and runs it to done. `implementation-plan` authors the plan and stops; `build` picks it up — in the same session or three days later — walks its steps, ticks the markdown spec, re-renders the HTML, and runs the three completion gates. `status: completed` is written only after end-to-end verification passes, and the skill stops without committing.

Named no plan, the **command form** authors one instead of stopping: it asks whether to start with a proposal or go straight to plan authoring, delegates to `build-proposal` and `implementation-plan`, and implements what comes back. Model invocation is unchanged — it still requires an existing plan and routes to `/plan-agent:implementation-plan` when there is none.

```
/plan-agent:build docs/plans/add-fitness-tracker.md
/plan-agent:build add-fitness-tracker.html
/plan-agent:build add a health check endpoint
/plan-agent:build --dir tmp/plans
/plan-agent:build
implement the plan at docs/plans/add-fitness-tracker.md
```

With an objective and no path it skips discovery entirely and enters the chain. With neither, it **offers** the newest `todo` / `in-progress` specs in the plans directory (skipping `archive/`) — at most three, plus `None of these — author a new plan`, stating how many were suppressed — rather than adopting one silently. `--dir <path>` overrides the plans directory; an explicit path is honored as given, so plans outside the default root resolve without it, and a path that does not resolve stops rather than authoring a plan on a typo. A dirty working tree is surfaced before any of this runs; once a plan is resolved, an already-`completed` plan prompts rather than being silently redone and `[x]` steps are resumed past rather than reapplied.

### Hooks

#### Filename validation (automatic)

The `validate-plan-filename` hook fires on every `Write`/`Edit` that touches a `.html` or `.md` file in the configured plans directory. It exits 2 (actionable feedback) when the filename violates `verb-target` kebab-case, and exits 0 silently on a valid name.

**Valid names:** `add-dark-mode-toggle.html`, `fix-login-redirect.html`, `refactor-auth-module.html`

**Rejected patterns:**
- Non-kebab-case or uppercase letters
- Harness-generated hex suffixes (e.g. `fix-auth-a3f9b2c1`)
- Trailing dates in the filename (use `<meta name="plan-created">` instead)
- Generic placeholders (`plan`, `untitled`, `draft`, `temp`)
- First token is not an imperative verb
- Second token is a stop-word (`the`, `a`, `an`, `this`, ...)

HTML plans with `<meta name="plan-status" content="completed">` are skipped (no rename required for shipped work).

#### Gallery index rebuild (automatic)

`rebuild-plans-index` runs when `dispatch.py` sees a write to a non-`index.html` `.html` file inside the configured plans directory. It calls `build-index.sh` to regenerate the gallery index automatically. Always exits 0 so index-rebuild failures never block plan writes.

#### Prototypes gallery rebuild (automatic)

`build-prototypes-index` runs when `dispatch.py` sees a write under `docs/prototypes/`, leaving the plans gallery untouched. It calls `build-prototypes-index.sh` to regenerate `docs/prototypes/index.html` (newest-first, escaped). Always exits 0.

#### Prototype drift check (automatic)

`check-prototype-drift` runs after `build-prototypes-index` on the same `docs/prototypes/` write. It reads the prototype's `<script type="application/json" id="proto-model">` block — the durable copy of the data model `/plan-agent:prototype` derived — and compares it two ways:

1. **Against the prototype's own DOM** — the `<th data-field>` headers and form field `name`/`id` attributes. This is the check that catches a human hand-editing the prototype.
2. **Against its plan's copy** — the `proto-model:` frontmatter of the Markdown spec named in the prototype's `<meta name="proto-source">`.

Each warning names both files, the diverging field, and what to re-run. It is deliberately narrow: structure only (copy, styling, and seed-value edits are not drift), and one direction only — a hand-edited plan desyncs with no signal, because plans are user-owned prose rather than generated output.

It stays silent whenever there is nothing to compare — no model block, no plan, no `proto-model:` line, malformed JSON, or a `proto-source` resolving outside the plans directory — and **always exits 0**, so a drift report about one plan never interrupts work on another.

The comparison only reports; reconciling the two sides is a judgment call left to a human.

#### Hook dispatch

`hooks.json` registers exactly one PostToolUse hook: `hooks/dispatch.py`. Registering the four hooks separately spawned four interpreters on *every* file edit in *every* session, purely so each could discover the file was not a plan and exit. The `matcher` field is a tool-name regex and cannot express a path condition, so the gate lives in `dispatch.py`: it reads the payload once, does one cheap path check, and for the common case exits without spawning anything.

The children remain independently runnable and testable — each re-applies its own filter — so `python3 hooks/validate-plan-filename.py < payload.json` still works standalone. The children share the dispatcher's single 60s budget (they run sequentially), rather than each holding an independent one as before.

### Plans directory resolution

The hook resolves `plansDirectory` in priority order:

1. Project `.claude/settings.json` (`plansDirectory` key)
2. `~/.claude/settings.json` (global fallback)
3. `docs/plans` (hardcoded fallback)

To use a custom directory, add to your project's `.claude/settings.json`:

```json
{
  "plansDirectory": "path/to/your/plans"
}
```

### Plugin configuration (`planAgent.*`)

The hook and skill both read a `planAgent` object from `.claude/settings.json` (project first, then global `~/.claude/settings.json`, first-match-wins):

```json
{
  "planAgent": {
    "additionalVerbs": ["onboard", "publish", "ingest"],
    "additionalStopWords": ["new", "better"],
    "additionalPlaceholders": ["scratch", "wip", "idea"],
    "extraFrontmatter": {
      "team": "engineering",
      "milestone": "Q3-2026",
      "priority": "medium"
    }
  }
}
```

| Key | Type | Effect |
|---|---|---|
| `additionalVerbs` | `string[]` | Merged with the built-in imperative verb set; custom verbs are accepted as valid first tokens |
| `additionalStopWords` | `string[]` | Merged with the built-in stop-word set; custom tokens are rejected as second tokens |
| `additionalPlaceholders` | `string[]` | Merged with generic placeholder names (`plan`, `draft`, etc.); listed names are rejected as full filenames |
| `extraFrontmatter` | `object` | Key-value pairs written as additional `<meta>` tags in every new plan's HTML `<head>`. `--priority` overrides any `priority` key here. |

## Plugin Structure

```
plan-agent/
  .claude-plugin/
    plugin.json             — Plugin manifest
  bin/                      — On the Bash tool's PATH; invoke by bare name, never by path
    plan-agent-render            — Renders a plan spec (wraps scripts/build-plan-html.mjs)
    plan-agent-prototypes-index  — Rebuilds the prototypes gallery (wraps hooks/build-prototypes-index.sh)
    plan-agent-plans-index       — Rebuilds the plans gallery (wraps hooks/build-index.sh)
  skills/
    implementation-plan/
      SKILL.md              — Workflow, arguments, spec authoring, render pipeline
      guidelines/
        planning-principles.md — What every good plan says (falsifiable done, what/why/verify)
        section-catalog.md     — Section menu: purpose, when it earns its place, exact spec syntax
        right-sizing.md        — Minimal / standard / deep depth profiles
        red-green-verify.md    — RED/GREEN/VERIFY/SHIP phases, when a plan requires them
        writing-style.md       — Tone, plain language, objective-vs-glance
      reference/
        SKELETON.html       — Legacy full-plan HTML template (kept for reference/tests)
        SKELETON.md         — Markdown plan-spec starter (the format build-plan-html.mjs parses)
    build/
      SKILL.md              — Implements an existing plan: steps, spec ticks, three gates, re-render
    build-proposal/
      SKILL.md              — Idea→prompt loop (Tier gate, 8 steps, dual-write resolver)
      references/
        artifact-shape.md             — Canonical proposal shape + section-to-slot mapping
        operating-principles.md       — Ten principles + capability map
        example-design-md-spec-alignment.md   — Trimmed Tier 2 worked exemplar
        example-proposal-builder-skill.md     — Trimmed recursive worked exemplar
    review-plan/
      SKILL.md              — Agent Team review workflow (supports --background)
      references/
        role-prompts.md     — Spawn-prompt templates for each reviewer
        output-template.md  — Synthesis report structure
    finalize-plan/
      SKILL.md              — Plan completion review and acceptance criteria verification
    plans-library/
      SKILL.md              — Gallery scan/parse/render workflow
    plans-open/
      SKILL.md              — Open existing gallery without rebuild
    setup-sites/
      SKILL.md              — Scaffold the GitHub Pages deploy pipeline into any repo
    prompt/
      SKILL.md              — 7-phase prompt authoring (classify, interview, structure, draft, save)
      references/
        system-prompt-template.md     — system-type template
        task-prompt-template.md       — task-type template
        creative-prompt-template.md   — creative-type template
        analytical-prompt-template.md — analytical-type template
        proposal-prompt-template.md   — proposal-type template (11 proposal-shaped slots)
        best-practices-reference.md   — Anthropic prompting guidance
  agents/
    plan-reviewer-*.md      — Ten reviewer agent definitions (7 core + 3 UI-conditional)
    agent-review-plan.md    — Background agent for fire-and-forget review
  commands/
    review-plan-bg.md       — Background review dispatcher command
    prompt.md               — Skill wrapper unblocking programmatic invocation
  templates/
    plans-gallery.html      — Static gallery template (substituted by plans-library)
    pages/
      deploy-pages.yml      — GitHub Pages deploy workflow (SHA-pinned)
      hub.html              — Parameterized landing-hub template (setup-sites)
      serve-docs.sh         — Local docs/ preview server (setup-sites)
  hooks/
    dispatch.py                — The one registered PostToolUse hook; path-gates, then fans out
    validate-plan-filename.py  — Filename enforcement script (child of dispatch)
    rebuild-plans-index.py     — Gallery index auto-rebuild (child of dispatch)
    build-index.sh             — Shell entry point for gallery rebuild
  hooks.json                — Hook registration (one PostToolUse entry: dispatch.py)
  README.md
  CHANGELOG.md
```

## Components

### `implementation-plan` Skill

Command-invocable via `/plan-agent:implementation-plan <objective>` and model-invocable on plan-document intent (scoped to artifact requests — does not trigger on generic planning questions).

- **Invocation & Arguments** — on command invocation, reads `$ARGUMENTS` and parses objective + flags (`--quick`/`--no-clarify`/`--no-align`/`--no-interview`/`--tdd`/`--no-tdd`/`--type`/`--template`/`--dir`/`--priority`); on model invocation, derives the objective from conversation context and runs the full workflow by default
- **Workflow Steps 1–8** — Clarify, Create, Frontmatter, Rename, Align, Interview (Step 5b), Commit, Status, Open
- **Implement-now handoff** (Step 8) — `Implement now` delegates to the `build` skill, which owns the implementation loop and its three gates. `implementation-plan` itself never writes source files; its Scope Constraint is never lifted
- **Markdown-spec pipeline** — the agent authors a compact Markdown plan spec (the committed source of truth) and renders it deterministically with the bundled `plan-agent-render` (a `bin/` wrapper around `scripts/build-plan-html.mjs`); the renderer owns all presentation (CSS, JS, meta tags, derived implement/goal/workflow prompts, effort level, file-tree) *and* all progress state: `- [x]` criteria bullets, `[x]` step markers, and an optional `## Completion Report` section render as checked boxes, completed step cards, the derived completion checklist, and the report list — status/checkbox changes are Markdown edits plus a re-render, never HTML surgery
- **Guidelines library** — `guidelines/planning-principles.md`, `section-catalog.md`, `right-sizing.md`, `red-green-verify.md`, and `writing-style.md` drive judgment-based structure: the required core (objective, steps, acceptance criteria, verification) is always present, everything else earns its place per plan (`minimal`/`adr`/`spike` ship as right-sizing guidance, not extra templates)
- **Spec starter** — `reference/SKELETON.md` is the copyable spec skeleton in the exact format the renderer parses
- **`--check` (verify, write nothing)** — `plan-agent-render "<stem>.md" -o "<stem>.html" --check` proves the rendered HTML is current and that a finished spec is internally consistent, without inspecting the rendered markup:

  ```bash
  plan-agent-render docs/plans/my-plan.md -o docs/plans/my-plan.html --check
  ```

  | Row | Asserts | Skipped when |
  |-----|---------|--------------|
  | `html` | the file on disk is byte-identical to a fresh in-memory render | never |
  | `steps` | every numbered step carries `[x]` | `status:` is not `completed` |
  | `criteria` | every `## Acceptance Criteria` bullet is `- [x]` | `status:` is not `completed` |

  Rows always print in that order. Exit is 0 only when nothing fails; a stale
  `html` row names the first differing line, column, and a 40-character window
  of each side, and a missing HTML file names the render command that produces
  it rather than throwing. A failure is always fixed in the **spec** — re-render
  rather than editing the HTML, and never promote `status:` to satisfy it.
  Run by `build` Step 5.3 and `finalize-plan` Step 5e; it replaced a gate that
  named CSS selectors as evidence and was reached with `Grep`, which searches
  source markup instead of evaluating anything and reported drift that was not
  there.

### `build` Skill

Command-invocable via `/plan-agent:build [<plan>] [<objective>]` and
model-invocable on "implement the plan at …" intent. It is the **downstream**
layer to `implementation-plan`: that skill decides *how* and stops; `build`
executes it — and, from the command form only, can enter the authoring chain
when no plan was named.

- **Input** — a `.md` spec or `.html` plan path (resolved as given, then by
  basename under the plans directory), a free-text objective, or no argument at
  all. A leading token is an objective only when it has no `.md`/`.html` suffix
  and no `/`. Argument-less discovery never descends into `archive/`; an
  explicitly passed path is honored as given, archived or not, and stops when it
  does not resolve
- **No-plan chain (command only)** — with no path, it asks
  `Start with a proposal` / `Straight to plan authoring`, delegates to
  `build-proposal` and `implementation-plan`, then re-resolves the produced spec
  by path and implements it. `Exit — I'll implement later` and `Run as workflow`
  at the chained Step 8 both terminate the chain without writing source
- **Preconditions** — surfaces a dirty working tree before anything else, chain
  included; then refuses to silently redo a `completed` plan and resumes from
  the first unmarked step
- **Three gates** — an **acceptance-criteria gate** (verify and check off each
  criterion), an **end-to-end verification gate** (run the objective test and
  walk the Verification section; on failure, fix and re-verify up to 3 times),
  and a **completion-checklist gate** (steps, criteria, and status agree).
  `status: completed` is written only after end-to-end verification passes
- **Handoff** — stops without committing; the source changes, updated spec, and
  re-rendered HTML are left in the working tree

### `build-fleet` Skill

Command-invocable via `/plan-agent:build-fleet [<plan> ...]` and model-invocable
on "ship the backlog in parallel" intent. It is `build` fanned out: `build`
ships one plan on the current branch, `build-fleet` ships N plans on N branches.

It **dispatches only**. Every step of the work belongs to `plan-agent:build` and
`git-agent:ship-autonomous`, so both are inherited rather than restated —
including the completion gates, the browser verification, the CI autofix, and
the review triage.

- **Candidates** — non-flag arguments are an explicit plan list; with none, it
  discovers every `status: todo` spec under the plans directory, skipping
  `archive/` and `artifacts/`. Only frontmatter is read here; the fleet agents
  read the bodies
- **Picker** — a single `multiSelect` `AskUserQuestion` over the newest four
  candidates, stating how many were suppressed. The ticked boxes *are* the
  confirmation, since the question says each selection opens one pull request;
  an explicit plan list skips the picker, and an empty selection, a dismissed
  question, or a headless run all cancel
- **Base branch** — resolved from `refs/remotes/origin/HEAD` in Step 1 and
  carried into every agent prompt, never assumed to be `main`; an unset
  `origin/HEAD` asks rather than guessing
- **Isolation** — one `Agent` per plan with `isolation: "worktree"`, so the
  harness creates each worktree and removes it if left unchanged. No
  `git worktree add`, no cleanup pass
- **Blast-radius guards** — a mandatory confirmation naming the number of PRs
  that will open, `--max` defaulting to 3, `completed` plans excluded even when
  named, and a headless run that cancels rather than defaulting
- **Stops at green** — a background agent cannot answer `ship-autonomous`'s
  merge gate, so the fleet ends at green PRs and merging stays a human step via
  `/git-agent:merge`. The repo's `marketplace.json` and gallery `index.html`
  merge drivers already resolve the conflicts sibling PRs actually produce

```bash
/plan-agent:build-fleet                    # every todo plan, max 3
/plan-agent:build-fleet --max 5
/plan-agent:build-fleet docs/plans/add-foo.md docs/plans/add-bar.md
```

### `build-proposal` Skill

Command-invocable via `/plan-agent:build-proposal <idea>` and model-invocable on idea / "should-we" / compare-and-align intent. It is the **upstream** layer to `implementation-plan`: it decides *should-we + what* and hands off the *how*. Its three-part description shares no trigger phrase with `implementation-plan`, so the two never collide on the model-invocation path.

- **Right-sizing triage** — Step 1 picks a **Tier**: Tier 0 (answer directly, no loop), Tier 1 (one research pass, short proposal), Tier 2 (full 8-step loop + canonical artifact). The tier escalates or de-escalates as research reveals scope.
- **8-step loop** — Frame → **Confirm the ask (Step 1b gate)** → Fan out research (parallel) → Synthesize the core finding → Separate facts from decisions → Resolve decisions (recommendation-first) → Author the artifact → Deepen on request → Converge & hand off. Step 0 self-bootstraps out of plan mode.
- **Step 1b confirms the objective before any research runs** — the restated one-liner, domains, and tier go back to the human as an `AskUserQuestion` (**Looks right** / **Refine it**) at Tier 1 and 2; Tier 0 has already answered and skips it. Refining is bounded at two rounds, after which the human's latest wording is used verbatim. Step 1 also forbids *enriching* the restatement — adding a downstream purpose or success condition the human never stated is the specific drift the gate exists to catch, since the entire fan-out then researches the invention.
- **Artifact resolution (dual-write, 6.0.0)** — the deliverable is a **saved prompt** at `<prompts-dir>/proposal-<slug>.md`, authored by delegating to `prompt`; the legacy `<proposals-dir>/<slug>.md` copy is still written for one deprecation release carrying a banner naming the prompt as authoritative, and is removed in 6.1.0. The prompts directory resolves `--dir` → `promptsDirectory` (settings precedence: project-local `.claude/settings.local.json` → project `.claude/settings.json` → global `~/.claude/settings.json`) → `${PWD}/docs/prompts/` — the same key `prompt` and `artifact-tools:prompt-artifact` read. **`--dir` follows the authoritative artifact, so since 6.0.0 it names the prompts directory, not the proposals one**; the deprecated proposals root still resolves from `planAgent.proposalsDirectory` → `${PWD}/docs/proposals/`, seeded by a committed `docs/proposals/.gitkeep`.
- **The prompt filename carries no date** — `proposal-<slug>.md`. It is a living document that deepens over rounds, and a dated name would resolve to a different path the moment a loop crossed midnight, forking it in two. The slug is the identity; `created:` and `modified:` carry the dates, and round two rewrites the same file in place rather than minting a `-2` variant.
- **The caller dictates the path** — Step 6 passes `--out <path>` (and `--answers-gathered`, so the human is not re-interviewed) to `prompt`. `Skill()` has no documented return value, and `prompt`'s own Phase 7 would resolve a different directory and a different intent slug, so an independently derived path would name a file that was never written.
- **`deep-research` is optional** — the web-research phase can delegate to the `deep-research` skill when available, falling back to `WebSearch`/`WebFetch` + `Agent` (`Explore`) breadth otherwise. No hard dependency.
- **References (one level deep)** — `references/artifact-shape.md` (canonical section order + skeleton), `references/operating-principles.md` (ten principles + capability map), `references/artifact-resolution.md` (the runnable directory resolver, read at Step 6), and two trimmed worked exemplars (`example-design-md-spec-alignment.md`, `example-proposal-builder-skill.md`) stamped with source URL + commit SHA/date.
- **Always offers the artifact** — Step 8 asks once, every converged run, whether to publish the proposal as a shareable claude.ai artifact; on yes it loads the bundled `artifact-design` skill to calibrate the page, then publishes with the `Artifact` tool. The offer is **not** suppressed by a blanket "no more questions" or by `--answers-gathered` — those cover the proposal's decisions, and publishing is the one action a human cannot undo by editing a file. It never publishes without an explicit yes, and Tier 0 never reaches the offer because it writes no artifact at all.
- **Handoff** — at convergence it sets the prompt's `status:` to `converged`, stops, and points to `/plan-agent:implementation-plan author an execution plan from the proposal prompt at <prompts-dir>/proposal-<slug>.md`. It leads with an objective rather than a bare `.md` token: a bare token triggers `implementation-plan`'s 1:1 conversion mode (which maps `Changes/Steps` → step cards), and a proposal has only `Workstreams`/`Roadmap` — so leading with the objective keeps the full planning pass that drafts real, actionable steps.

Usage:

```text
/plan-agent:build-proposal should we adopt DESIGN.md for our component tokens
/plan-agent:build-proposal compare our state management to Zustand and align
/plan-agent:build-proposal --dir docs/rfcs how would we add offline support   # --dir names the prompts dir
```

### `build-feature` Skill

Command-invocable via `/plan-agent:build-feature <feature idea>` and model-invocable on feature-doc / break-into-plans intent. The sibling of `build-proposal` with a different seam: a proposal answers *should-we*; a feature doc answers *what are we building, and how does it split into plans?* Its three-part description shares no trigger phrase with either sibling, so the three never collide on the model-invocation path.

- **Right-sizing triage** — Tier 0 (**plan-sized**: the feature would yield one plan, so it hands the user the exact `/plan-agent:implementation-plan <idea>` command and writes no artifact), Tier 1 (focused: one research pass, short shape), Tier 2 (full shape, deepened over rounds).
- **Same loop as build-proposal** — Frame → Confirm the ask (Step 1b gate, two-round refine bound) → Fan out research in parallel (codebase `Agent` in flight before the first fetch) → Synthesize the feature's shape and its **seams** → Separate facts from decisions → Resolve decisions (recommendation-first) → Author the doc → Deepen → Converge & hand off.
- **Dual deliverable** — the team feature doc at `<features-dir>/<slug>.md` (written in place each round; `--dir` → `planAgent.featuresDirectory` via settings precedence → `${PWD}/docs/features/`) plus, **only at convergence**, one saved prompt per sub-feature at `<prompts-dir>/feature-<slug>-<sub-slug>.md`, authored by delegating to `prompt` through its standard path with an explicit `--out` and `--answers-gathered` — no `proposal` type, no changes to the `prompt` skill. Prompts are not written per round because the breakdown can merge or split mid-loop.
- **Recommend-only breakdown** — the doc's Sub-feature breakdown carries a rationale, S/M/L size, dependency order, prompt path, and a paste-ready `/plan-agent:implementation-plan … --from-prompt <prompt path>` command per sub-feature. Running them, in dependency order, is the user's step — the skill never invokes plan generation itself.
- **Reference (one level deep)** — `references/feature-doc-shape.md`: the canonical section order, the breakdown entry format with its fenced prompt skeleton, and the S/M/L sizing guide.

Usage:

```text
/plan-agent:build-feature bulk CSV export for the reports dashboard
/plan-agent:build-feature --tier 2 offline support across the mobile app
/plan-agent:build-feature --dir docs/rfcs dark mode          # --dir names the features dir
```

### `finalize-plan` Skill

Manual-invoke only (`disable-model-invocation: true`). Triggered as `/plan-agent:finalize-plan [plan-file.md|.html] [--all] [--dir <path>]`.

Reviews a plan for codebase implementation evidence with per-criterion verification:
1. Reads the plan's acceptance criteria (from the Markdown spec when one exists; from the HTML for legacy plans)
2. Maps implementation evidence to individual criteria, classifying each as `verified` or `unverified`
3. Runs the objective-verification test (the Tests section's **Run** command) for an end-to-end pass/fail signal
4. Presents a confirmation summary with per-criterion verification status plus the objective-test result
5. Offers three completion options: check all, only auto-check verified, or cancel
6. On confirmation — **spec mode** (sibling `<stem>.md` spec exists): sets `status:` frontmatter, flips `- [x]` criteria bullets and `[x]` step markers, writes a `## Completion Report` section for any gaps, and re-renders the HTML via `build-plan-html.mjs`; **legacy mode** (no spec): checks acceptance-criteria boxes, adds `completed` class to step cards, and updates `<html data-status>`, `<meta name="plan-status">`, and the visible badge directly
7. If only verified criteria are checked, status is set to `in-progress` rather than `completed`

With `--all`, the skill runs in sweep mode: it discovers every non-completed plan in the plans directory (`grep -l` for a `plan-status` meta tag valued `todo` or `in-progress`, excluding `index.html` and `archive/`; HTML without the tag is never a candidate), scores each with the cheap token-evidence pass (non-interactive — token-less plans score 0% instead of prompting), batch-confirms via one multi-select prompt, then runs the full per-criterion verification, objective test, and status writes on the selected plans only.

### `plans-open` Skill

Auto-activates on "open the gallery", "show the plans page" intent. Opens the existing `index.html` gallery directly without scanning, parsing, or writing any files. Resolves `plansDirectory` from settings (same as `plans-library`). If `index.html` does not exist, tells the user to run `/plan-agent:plans-library` first.

### `validate-plan-filename` Hook

Pure Python 3 stdlib — no external dependencies, portable across install locations. Uses `${CLAUDE_PLUGIN_ROOT}` for the script path so it works regardless of where the plugin is installed.

Accepts `.html` plan files (primary) and `.md` plan files (legacy). The `classify_filename()` function checks:
1. Strict kebab-case (lowercase letters, digits, hyphens only)
2. No harness hex suffix
3. No trailing date
4. Not a generic placeholder name
5. First token is in the imperative verb set
6. Second token is not a stop-word

Completion is detected via `<meta name="plan-status" content="completed">` for HTML files, or `status: completed` YAML frontmatter for legacy `.md` files.

### `plans-library` Skill

Auto-activates when user intent matches browsing or organising existing plans (e.g. "browse my plans", "show the plans library", "open the plans index").

```
browse my plans
view plan history
open the plans index
```

The skill scans all `.html` plan files in the plans directory (resolves the same `plansDirectory` setting as the `implementation-plan` skill), reads each plan's `<meta>` tags and `<title>`, renders them into a filterable gallery, writes `<PLANS_DIR>/index.html`, and opens it in the browser.

**Gallery features:**
- Filter chips for status: **All / Todo / In Progress / Completed**
- Filter chips for type: **All / Feature / Fix / Refactor / Docs / Chore**
- Title search box
- Grid and list view toggle
- Each card links directly to the underlying plan file

The scan always excludes `index.html` itself and the `docs/plans/archive/` subdirectory.

### `rebuild-plans-index` Hook

PostToolUse hook that fires on every `Write`/`Edit`/`MultiEdit` to a non-`index.html` `.html` file inside the configured plans directory. Calls `build-index.sh` (bundled at `hooks/build-index.sh`) to regenerate the gallery index automatically. Always exits 0 so index-rebuild failures never block plan writes.

### Merged from `plan-interview` (v4.0.0)

As of v4.0.0, `plan-agent` absorbs the former `plan-interview` plugin — there is no separate install. The stress-test surface is covered by the built-in **Step 5b Interview** during plan creation and the **`review-plan`** Agent Team for deeper reviews. The unique capabilities `plan-interview` carried are now first-class plan-agent skills and commands:

| Was | Now |
|-----|-----|
| `/plan-interview:documenting-plans` | `/plan-agent:documenting-plans` (+ `plan-documenter` batch agent) |
| `/plan-interview:markdown-to-html` | `/plan-agent:markdown-to-html` |
| `/plan-interview:plan-status` | `/plan-agent:plan-status` (`.md`/YAML plans; single file or `--all` bulk) |
| `/plan-interview:update-plan-status` | `/plan-agent:plan-status <dir> --all` (folded into `plan-status`) |
| `/plan-interview:plan-maintenance` | `/plan-agent:plan-maintenance` |
| `/plan-interview:deep-grill` | `/plan-agent:deep-grill` |
| ExitPlanMode stress-test nudge | `hooks.json` `ExitPlanMode` PostToolUse matcher |
| `/plan-interview:plan-interview`, `plan-to-html`, `plan-hygiene`, `review-rename-plans` | dropped — covered by the built-in interview, `review-plan`, `markdown-to-html`, and the `validate-plan-filename` hook |

If you previously had `plan-interview@agentics-kit` installed, uninstall it and ensure `plan-agent` is at v4.0.0 or later.
