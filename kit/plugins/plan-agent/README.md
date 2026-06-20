# plan-agent Plugin

Plan creation and completion as a Claude Code plugin — invoke `/plan-agent:implementation-plan <objective>` to run the full Steps 0–8 planning workflow on demand, or `/plan-agent:finalize-plan` to review and mark a plan completed.

## Overview

This plugin packages the Plan Mode workflow (Steps 0 through 8, ending in Implement/Edit/Exit), required plan structure, and writing style into the `implementation-plan` skill. The skill is both **command-invocable** (`/plan-agent:implementation-plan <objective>`) and **model-invocable** — it auto-activates when you ask to create a plan document, generate an HTML plan, or write a plan file. It does not activate on generic planning questions (those route to built-in Plan Mode). Accepts GitHub/GitLab issue URLs and `#n` references to auto-seed plans from backlog items, and `.md` plan paths to convert existing markdown plans into the HTML format.

Plans are written as **self-contained `.html` files** — interactive, visually rich, and openable directly in a browser. No markdown output. Complex plans include a workflow prompt for parallel subagent orchestration via Claude Code's `/workflows` runtime.

The `review-plan` skill uses an **Agent Team** (five core reviewers plus two UI-conditional reviewers) to review implementation plans in parallel, synthesize findings, and apply improvements directly in place. Detects UI signals (React, Vue, buttons, modals, etc.) and conditionally runs UX and accessibility reviewers when present. Requires Agent Teams feature flag and Claude Code ≥ 2.1.32.

The `finalize-plan` skill reviews a plan for codebase implementation evidence, verifies each acceptance criterion individually, and marks the plan completed.

It also ships two `PostToolUse` hooks: one enforces `verb-target` kebab-case filenames on plan files, and another auto-regenerates the plans gallery index when plans change.

Installers get on-demand planning with argument support, issue ingestion, built-in interviews, acceptance criteria verification, agent-team–powered review, and filename guardrails without maintaining a global `~/.claude/rules/plan-mode.md` file by hand.

## Features

| Component | Type | Activation |
|-----------|------|-----------|
| `implementation-plan` | Skill | Command (`/plan-agent:implementation-plan <objective>`) or auto-activates on plan-document intent |
| `build-proposal` | Skill | Command (`/plan-agent:build-proposal <idea>`) or auto-activates on idea / "should-we" / compare-and-align intent |
| `review-plan` | Skill | Manual only — invoke as `/plan-agent:review-plan [plan-path]` or auto-activates when you ask to review a plan (requires Agent Teams) |
| `review-plan-bg` | Command | Background dispatcher — invoke as `/plan-agent:review-plan-bg <path>` to run the review team without blocking |
| `finalize-plan` | Skill (`disable-model-invocation`) | Manual only — invoke as `/plan-agent:finalize-plan [plan-filename.html]` |
| `refine-prompt` | Skill (`disable-model-invocation`) | Manual only — invoke as `/plan-agent:refine-prompt [intent]` |
| `plans-library` | Skill | Auto-activates on "browse plans", "view plan history", "open plans index" intent |
| `plans-open` | Skill | Auto-activates on "open the gallery", "show the plans page" — opens without rebuilding |
| `setup-sites` | Skill | Command (`/plan-agent:setup-sites`) or auto-activates on "set up / publish GitHub Pages" intent — scaffolds the deploy pipeline into any repo |
| `validate-plan-filename` | Hook (`PostToolUse`) | Fires automatically on every `Write`/`Edit` — validates plan filenames |
| `rebuild-plans-index` | Hook (`PostToolUse`) | Fires on `Write`/`Edit`/`MultiEdit` to non-index `.html` plans — auto-regenerates gallery |

**Built-in interview:** the planning workflow includes a structured interview step (Step 5b) that stress-tests your plan before committing. For deeper standalone reviews, install `plan-interview` separately. Note: `plan-interview:plan-status` currently operates on `.md`/YAML plans only and does not support `.html` plans yet.

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

Passing a `.md` plan path enters **conversion mode**: the markdown is treated as authoritative, pre-validated content — Clarify/Align/Interview are skipped, sections map 1:1 to the HTML structure, frontmatter (`created`, `status`) carries over, the output filename swaps the extension to `.html`, and Step 8 asks whether to keep or remove the source `.md`. If the path is missing locally, the skill checks the plan roots and the default branch before asking for direction.

**Full invocation syntax:**

```
/plan-agent:implementation-plan <issue-url|#n> | <plan.md> | <objective> [--quick] [--no-clarify] [--no-align] [--no-interview] [--workflow] [--type feature|fix|refactor|docs|chore] [--template default] [--dir <path>] [--priority low|medium|high|critical]
```

**Flags:**

| Flag | Effect |
|------|--------|
| `--quick` | Shorthand for `--no-clarify --no-align --no-interview`; skip Step 1, Step 5, and Step 5b |
| `--no-clarify` | Skip Step 1 Clarify only |
| `--no-align` | Skip Step 5 Align only |
| `--no-interview` | Skip Step 5b Interview (built-in structured interview) |
| `--type <kind>` | Set plan `type` in HTML metadata (`feature`, `fix`, `refactor`, `docs`, `chore`) |
| `--template <name>` | Reserved — only `default` is currently supported; additional variants are planned |
| `--dir <path>` | Override directory resolution; write the plan to this path |
| `--priority <level>` | Write `priority` to plan HTML metadata (`low`, `medium`, `high`, `critical`) |
| `--workflow` | Always generate a workflow prompt, bypassing the complexity heuristic |

**Examples with flags:**

```
/plan-agent:implementation-plan --quick --type fix patch the login redirect
/plan-agent:implementation-plan --no-clarify add dark mode toggle
/plan-agent:implementation-plan --dir tmp/plans add dark mode toggle
/plan-agent:implementation-plan --no-interview fix a config typo
/plan-agent:implementation-plan --workflow migrate all API endpoints to v2
```

**Smart defaults when flags are absent:** `--type` is inferred from the leading verb (`add`/`create`/`build` → `feature`; `fix`/`patch` → `fix`; `refactor`/`rename` → `refactor`; `document`/`docs` → `docs`). All skip-flags (`--quick`, `--no-clarify`, `--no-align`, `--no-interview`) and `--workflow` are opt-in only and are never inferred automatically.

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

**Step 8 exit menu — Review the plan option:**

The exit menu always offers `Review the plan` as a one-click path to critique the freshly-generated plan before implementing it. Selecting it triggers a foreground-or-background sub-choice:

- **Run now (foreground):** invokes `Skill(skill: "plan-agent:review-plan", args: "<plan path>")`, runs the seven-reviewer Agent Team in-session, then re-renders the updated plan and loops back to the menu.
- **Background:** invokes `Skill(skill: "plan-agent:review-plan-bg", args: "<plan path>")`, dispatches the review team detached via `agent-review-plan`, and returns to the menu immediately; reopen the plan after completion to view applied updates.

**Adaptive menu swap:** The `AskUserQuestion` tool is capped at 4 options. When a workflow prompt is present the menu would otherwise have 5 slots, so `Edit the plan` is dropped from that variant — the full ordering becomes: `Implement now` / `Run as workflow` / `Review the plan` / `Exit`. Without a workflow prompt all four options appear: `Implement now` / `Review the plan` / `Edit the plan` / `Exit`.

If Agent Teams are unavailable (Claude Code < 2.1.32 or `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` unset), selecting `Review the plan` surfaces `review-plan`'s guidance and returns to the menu without crashing the planning flow. Plan status stays `todo` throughout — reviewing is not implementing.

### HTML plan output

Every plan is a single self-contained `.html` file (no CDN links, no external assets):

- **Compute-on-read spec** — the visible plan DOM is the single source of truth; `node scripts/extract-plan-spec.mjs <plan>` derives a spec-only markdown rendition on demand (objective, context, files, steps with why/verify, tests, acceptance criteria, verification) — a few thousand tokens of spec instead of the full ~21k styled HTML. New plans embed nothing; legacy plans that still carry a `<script type="text/markdown" id="plan-digest">` block are read from it verbatim (un-guarded). Status, checkbox, and progress state are never part of the spec
- **Status badge** — colour-coded: grey = todo, amber = in-progress, green = completed
- **Objective card** — prominent highlighted block at the top
- **Implement prompt** — Copy button produces a concise action-oriented prompt with plan status, step/criteria progress counts, and numbered instructions to implement directly from the plan file
- **Goal prompt** *(expandable)* — collapsible "Pursue as goal" section that reveals an outcome-driven prompt ("Achieve this goal: … — use the plan as reference, but optimize for the outcome"), giving the implementer latitude to deviate from the steps when a better path to the same outcome exists. **Always present** — every plan gets one, no flag required. References the plan by path like the implement prompt — self-contained, no repo-local script required
- **Workflow prompt** *(expandable)* — collapsible "Run as workflow" section that reveals a copy-paste prompt for parallel subagent orchestration via `/workflows`. Generated automatically for complex plans (5+ files across 3+ directories, repetitive per-file changes, parallelizable steps, or adversarial review needs) or explicitly with `--workflow`
- **Step cards** — numbered, each with an expandable *Verify* disclosure
- **Interactive checkboxes** — acceptance criteria the user can tick in the browser, with a live progress bar
- **Wish List** — blue-sky / visionary next-steps rendered with a distinct dashed-border treatment
- **Collapsible sections** — Next Steps and Unresolved Questions use `<details>` for progressive disclosure

Open the `.html` file directly in any browser. No server required.

#### Extracting the spec

Read a plan's spec without paying for the styled HTML:

```bash
node scripts/extract-plan-spec.mjs docs/plans/<plan>.html
```

The extractor reads an embedded `#plan-digest` block when one is present (legacy plans, un-guarded to clean markdown) and otherwise derives the spec from the visible DOM — so every plan resolves the same way, old or new. Each plan is a single self-contained HTML file, so the implement, goal, and workflow prompts it ships reference the plan **by path** — Claude reads the HTML directly, with no dependency on this script in the target repo. The extractor is a token-efficiency tool for callers that have it on hand (the review team, or manual inspection): roughly an order of magnitude fewer tokens than the full styled HTML, with a full-HTML fallback when it isn't available. **Caveat:** new plans embed no digest, so the old `awk '…id="plan-digest"…'` one-liner returns empty on them — use the extractor (or read the HTML) instead. Legacy embedded plans can still be re-seeded with `node scripts/backfill-plan-digests.mjs [--dry-run]` (idempotent; skips plans it cannot fully parse rather than emitting partial digests).

#### `review-plan` — Manual invoke or auto-activate

Reviews implementation plans using a seven-reviewer Agent Team (five core reviewers plus two UI-conditional reviewers). Detects UI signals and conditionally spawns UX and accessibility reviewers when present. Synthesizes findings and applies improvements directly to the source plan in place.

Reviewers read the plan's spec via `node scripts/extract-plan-spec.mjs` rather than the full HTML — roughly an order of magnitude fewer tokens per reviewer per cycle — falling back to the full HTML if the extractor can't run. The lead keeps reading the full HTML for selector-based edits.

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

Dispatches the `agent-review-plan` background agent to run the full seven-reviewer team without blocking the session. Returns an ack immediately; you are notified when it completes.

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

**UI signal detection:** Scans the plan HTML for references to React, Vue, Svelte, `.tsx`/`.jsx`/`.css`/`.html`, `className`, `style`, Tailwind, buttons, modals, forms, dialogs, dropdowns, pages, components. If 2+ signals or UI-specific keywords are found, UX and accessibility reviewers are spawned.

The workflow:

1. **Resolve** — locates the HTML plan (`--dir` override, or glob `docs/plans/*.html` excluding `index.html`, or newest recent)
2. **Verify** — confirms Agent Teams are available (feature flag + version check)
3. **Detect** — scans plan HTML for UI signals to determine reviewer roster
4. **Spawn** — creates the team and spawns 5 core + optional 2 UI reviewers in parallel
5. **Collect** — waits for all reviewers to report findings
6. **Synthesize** — aggregates findings into a structured report (Executive Summary, Role-by-Role, Agreements/Conflicts, Highest-Risk Issues)
7. **Update** — applies inline edits to the plan HTML (step refinements, criteria corrections, verification improvements) and appends a collapsible "Team Review" section
8. **Cleanup** — tears down the Agent Team

On success:

```
Reviewing plan: docs/plans/add-dark-mode-toggle.html
UI signals detected — running 7 reviewers
Plan updated in place: docs/plans/add-dark-mode-toggle.html
```

#### `finalize-plan` — Manual invoke only

Reviews an HTML plan for codebase implementation evidence, verifies each acceptance criterion individually, runs the plan's objective-verification test as an end-to-end signal, then marks the plan as completed. Each criterion is classified as `verified` or `unverified` based on actual codebase evidence. Offers three completion options: check all criteria, only auto-check verified ones, or cancel.

```
/plan-agent:finalize-plan add-dark-mode-toggle.html
/plan-agent:finalize-plan
```

When invoked without arguments, prompts for the plan file. The skill:
1. Reads the plan's acceptance criteria
2. Searches the codebase for implementation evidence per criterion
3. Runs the objective-verification test (the `.objective-test-card` **Run** command) for an end-to-end pass/fail signal
4. Presents a summary showing which criteria are verified vs unverified, plus the objective-test result
5. On confirmation: checks acceptance-criteria boxes, adds `completed` class to step cards, updates all status representations (`<html data-status>`, `<meta name="plan-status">`, visible badge)

#### `refine-prompt` — Manual invoke only

Interviews users about their prompting need and generates a copy-pasteable AI prompt grounded in [Anthropic's official Claude Prompting Best Practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices). Applies the right combination of techniques (clarity, XML structure, role assignment, few-shot examples, chain-of-thought scaffolding, and output formatting) based on the classified prompt type.

```
/plan-agent:refine-prompt
/plan-agent:refine-prompt system prompt for a customer support chatbot
/plan-agent:refine-prompt refactor Python code task prompt
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

Invoke only via `/plan-agent:refine-prompt` — auto-activation is disabled because "prompt" is too common a word in coding contexts.

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

The `rebuild-plans-index` hook fires on every `Write`/`Edit`/`MultiEdit` to a non-`index.html` `.html` file inside the configured plans directory. It calls `build-index.sh` to regenerate the gallery index automatically. Always exits 0 so index-rebuild failures never block plan writes.

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
  skills/
    implementation-plan/
      SKILL.md              — Plan Mode workflow, arguments, structure, writing style
      reference/
        SKELETON.html       — Default full-plan HTML template
        SKELETON.md         — Markdown skeleton reference
    build-proposal/
      SKILL.md              — Idea→proposal loop (Tier gate, 8 steps, artifact resolver)
      references/
        artifact-shape.md             — Canonical proposal-artifact template
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
  agents/
    plan-reviewer-*.md      — Seven reviewer agent definitions (5 core + 2 UI-conditional)
    agent-review-plan.md    — Background agent for fire-and-forget review
  commands/
    review-plan-bg.md       — Background review dispatcher command
  templates/
    plans-gallery.html      — Static gallery template (substituted by plans-library)
    pages/
      deploy-pages.yml      — GitHub Pages deploy workflow (SHA-pinned)
      hub.html              — Parameterized landing-hub template (setup-sites)
      serve-docs.sh         — Local docs/ preview server (setup-sites)
  hooks/
    validate-plan-filename.py  — PostToolUse filename enforcement script
    rebuild-plans-index.py     — PostToolUse gallery index auto-rebuild
    build-index.sh             — Shell entry point for gallery rebuild
  hooks.json                — Hook registration (Write|Edit and Write|Edit|MultiEdit matchers)
  README.md
  CHANGELOG.md
```

## Components

### `implementation-plan` Skill

Command-invocable via `/plan-agent:implementation-plan <objective>` and model-invocable on plan-document intent (scoped to artifact requests — does not trigger on generic planning questions).

- **Invocation & Arguments** — on command invocation, reads `$ARGUMENTS` and parses objective + flags (`--quick`/`--no-clarify`/`--no-align`/`--no-interview`/`--type`/`--template`/`--dir`/`--priority`); on model invocation, derives the objective from conversation context and runs the full workflow by default
- **Workflow Steps 1–8** — Clarify, Create, Frontmatter, Rename, Align, Interview (Step 5b), Commit, Status, Open
- **Implement-now gates** (Step 8) — when implementing in-session, three sequential gates run before completion: an **acceptance-criteria gate** (verify and check off each criterion), an **end-to-end verification gate** (run the plan's objective-verification test + walk the Verification section; on failure, fix and re-verify up to 3 times), and a **completion-checklist gate** (confirm step TODOs, criteria, and status)
- **Required Structure** — context, objective, steps (with per-step *why*/*verify*), acceptance criteria, verification, next-steps (with Wish List), unresolved-questions
- **Writing Style** — direct, imperative, developer-friendly; HTML-escapes all user-supplied content
- **Skeleton reference** — points to `reference/SKELETON.html` (only supported template; `minimal`, `adr`, and `spike` are planned)

### `build-proposal` Skill

Command-invocable via `/plan-agent:build-proposal <idea>` and model-invocable on idea / "should-we" / compare-and-align intent. It is the **upstream** layer to `implementation-plan`: it decides *should-we + what* and hands off the *how*. Its three-part description shares no trigger phrase with `implementation-plan`, so the two never collide on the model-invocation path.

- **Right-sizing triage** — Step 1 picks a **Tier**: Tier 0 (answer directly, no loop), Tier 1 (one research pass, short proposal), Tier 2 (full 8-step loop + canonical artifact). The tier escalates or de-escalates as research reveals scope.
- **8-step loop** — Frame → Fan out research (parallel) → Synthesize the core finding → Separate facts from decisions → Resolve decisions (recommendation-first) → Author the artifact → Deepen on request → Converge & hand off. Step 0 self-bootstraps out of plan mode.
- **Artifact-dir resolution** — `--dir` → `planAgent.proposalsDirectory` (settings precedence: project-local `.claude/settings.local.json` → project `.claude/settings.json` → global `~/.claude/settings.json`) → `${PWD}/docs/proposals/`; `mkdir -p`s the resolved dir and writes `<slug>.md`. A committed `docs/proposals/.gitkeep` seeds the default.
- **`deep-research` is optional** — the web-research phase can delegate to the `deep-research` skill when available, falling back to `WebSearch`/`WebFetch` + `Agent` (`Explore`) breadth otherwise. No hard dependency.
- **References (one level deep)** — `references/artifact-shape.md` (canonical section order + skeleton), `references/operating-principles.md` (ten principles + capability map), and two trimmed worked exemplars (`example-design-md-spec-alignment.md`, `example-proposal-builder-skill.md`) stamped with source URL + commit SHA/date.
- **Handoff** — at convergence it stops and points to `/plan-agent:implementation-plan author an execution plan from the proposal at docs/proposals/<slug>.md`. It leads with an objective rather than a bare `.md` token: a bare token triggers `implementation-plan`'s 1:1 conversion mode (which maps `Changes/Steps` → step cards), and a proposal has only `Workstreams`/`Roadmap` — so leading with the objective keeps the full planning pass that drafts real, actionable steps.

Usage:

```text
/plan-agent:build-proposal should we adopt DESIGN.md for our component tokens
/plan-agent:build-proposal compare our state management to Zustand and align
/plan-agent:build-proposal --dir docs/rfcs how would we add offline support
```

### `finalize-plan` Skill

Manual-invoke only (`disable-model-invocation: true`). Triggered as `/plan-agent:finalize-plan [plan-filename.html]`.

Reviews an HTML plan for codebase implementation evidence with per-criterion verification:
1. Reads the plan's acceptance criteria
2. Maps implementation evidence to individual criteria, classifying each as `verified` or `unverified`
3. Runs the objective-verification test (the `.objective-test-card` **Run** command) for an end-to-end pass/fail signal
4. Presents a confirmation summary with per-criterion verification status plus the objective-test result
5. Offers three completion options: check all, only auto-check verified, or cancel
6. On confirmation: checks acceptance-criteria boxes, adds `completed` class to step cards, updates `<html data-status>`, `<meta name="plan-status">`, and visible badge
7. If only verified criteria are checked, status is set to `in-progress` rather than `completed`

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

### Optional: `plan-interview` pairing

The built-in Step 5b Interview runs a lightweight stress-test during plan creation. For deeper standalone reviews (multi-round interviews with product-plan routing, plan-name validation, and HTML artifact generation), install the `plan-interview` plugin:

```
/plugin install plan-interview@agentics-kit
```
