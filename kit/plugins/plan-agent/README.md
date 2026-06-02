# plan-agent Plugin

Plan creation and completion as a Claude Code plugin — invoke `/plan-agent:implementation-plan <objective>` to run the full Steps 0–8 planning workflow on demand, or `/plan-agent:finalize-plan` to review and mark a plan completed.

## Overview

This plugin packages the Plan Mode workflow (Steps 0 through 8, ending in Implement/Edit/Exit), required plan structure, and writing style into a **manual-invoke** skill (`implementation-plan`, `disable-model-invocation: true`). Planning only happens when you explicitly call it — the skill does not auto-activate on ambient intent. Accepts GitHub/GitLab issue URLs and `#n` references to auto-seed plans from backlog items.

Plans are written as **self-contained `.html` files** — interactive, visually rich, and openable directly in a browser. No markdown output. Complex plans include a workflow prompt for parallel subagent orchestration via Claude Code's `/workflows` runtime.

The `finalize-plan` skill reviews a plan for codebase implementation evidence, verifies each acceptance criterion individually, and marks the plan completed.

It also ships two `PostToolUse` hooks: one enforces `verb-target` kebab-case filenames on plan files, and another auto-regenerates the plans gallery index when plans change.

Installers get on-demand planning with argument support, issue ingestion, built-in interviews, acceptance criteria verification, and filename guardrails without maintaining a global `~/.claude/rules/plan-mode.md` file by hand.

## Features

| Component | Type | Activation |
|-----------|------|-----------|
| `implementation-plan` | Skill (`disable-model-invocation`) | Manual only — invoke as `/plan-agent:implementation-plan <objective>` |
| `finalize-plan` | Skill (`disable-model-invocation`) | Manual only — invoke as `/plan-agent:finalize-plan [plan-filename.html]` |
| `plans-library` | Skill | Auto-activates on "browse plans", "view plan history", "open plans index" intent |
| `plans-open` | Skill | Auto-activates on "open the gallery", "show the plans page" — opens without rebuilding |
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
claude --plugin-dir ~/devbox/agentics/kit/plugins/plan-agent
```

## Usage

### Skills

#### `implementation-plan` — Manual invoke only

Creates implementation plans from a free-text objective. Enforces verb-target filenames, structure, and HTML metadata.

Manual invoke only — use `/plan-agent:implementation-plan` explicitly. This skill has `disable-model-invocation: true` and will not auto-activate on ambient intent.

```
/plan-agent:implementation-plan create a todo app for ravens
/plan-agent:implementation-plan fix the login redirect bug in auth middleware
/plan-agent:implementation-plan refactor the user settings module into smaller services
```

**Full invocation syntax:**

```
/plan-agent:implementation-plan <objective> [--quick] [--no-clarify] [--no-align] [--no-interview] [--type feature|fix|refactor|docs|chore] [--template default] [--dir <path>] [--priority low|medium|high|critical]
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

**Examples with flags:**

```
/plan-agent:implementation-plan --quick --type fix patch the login redirect
/plan-agent:implementation-plan --no-clarify add dark mode toggle
/plan-agent:implementation-plan --dir tmp/plans add dark mode toggle
/plan-agent:implementation-plan --no-interview fix a config typo
```

**Smart defaults when flags are absent:** `--type` is inferred from the leading verb (`add`/`create`/`build` → `feature`; `fix`/`patch` → `fix`; `refactor`/`rename` → `refactor`; `document`/`docs` → `docs`). All skip-flags (`--quick`, `--no-clarify`, `--no-align`, `--no-interview`) are opt-in only and are never inferred automatically.

The skill enforces the full Steps 1–8 workflow:

1. **Clarify** — resolves ambiguous requirements (skipped with `--quick`)
2. **Create** — places the plan in the right directory with a `verb-target.html` filename
3. **Frontmatter** — writes HTML `<meta>` tags: `plan-status`, `plan-type`, `plan-created`, `plan-repo`
4. **Rename** — ensures the filename is meaningful before committing
5. **Align** — confirms each step matches the objective (skipped with `--quick`)
5b. **Interview** — structured interview to stress-test the plan (skipped with `--quick` or `--no-interview`)
6. **Commit** — commits the plan alongside related changes
7. **Status** — tracks `todo` → `in-progress` → `completed` via `<html data-status>` and `<meta name="plan-status">`
8. **Open** — opens the plan in a browser to confirm it renders correctly

### HTML plan output

Every plan is a single self-contained `.html` file (no CDN links, no external assets):

- **Status badge** — colour-coded: grey = todo, amber = in-progress, green = completed
- **Objective card** — prominent highlighted block at the top
- **Implement prompt** — copy-paste prompt to begin sequential implementation
- **Workflow prompt** *(complex plans only)* — copy-paste prompt prefixed with "Run a workflow to …" that triggers Claude Code's `/workflows` runtime for parallel subagent orchestration. Generated when a plan touches 5+ files across 3+ directories, involves repetitive per-file changes, includes parallelizable steps, or requires cross-checking.
- **Step cards** — numbered, each with an expandable *Verify* disclosure
- **Interactive checkboxes** — acceptance criteria the user can tick in the browser, with a live progress bar
- **Wish List** — blue-sky / visionary next-steps rendered with a distinct dashed-border treatment
- **Collapsible sections** — Next Steps and Unresolved Questions use `<details>` for progressive disclosure

Open the `.html` file directly in any browser. No server required.

#### `finalize-plan` — Manual invoke only

Reviews an HTML plan for codebase implementation evidence, verifies each acceptance criterion individually, then marks the plan as completed. Each criterion is classified as `verified` or `unverified` based on actual codebase evidence. Offers three completion options: check all criteria, only auto-check verified ones, or cancel.

```
/plan-agent:finalize-plan add-dark-mode-toggle.html
/plan-agent:finalize-plan
```

When invoked without arguments, prompts for the plan file. The skill:
1. Reads the plan's acceptance criteria
2. Searches the codebase for implementation evidence per criterion
3. Presents a summary showing which criteria are verified vs unverified
4. On confirmation: checks acceptance-criteria boxes, adds `completed` class to step cards, updates all status representations (`<html data-status>`, `<meta name="plan-status">`, visible badge)

#### `plans-open` — Auto-activates

Opens the existing plans gallery (`index.html`) directly without scanning, parsing, or writing any files. If `index.html` does not exist, tells the user to run `/plan-agent:plans-library` first.

```
open the plans gallery
show the plans page
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
    finalize-plan/
      SKILL.md              — Plan completion review and acceptance criteria verification
    plans-library/
      SKILL.md              — Gallery scan/parse/render workflow
    plans-open/
      SKILL.md              — Open existing gallery without rebuild
  templates/
    plans-gallery.html      — Static gallery template (substituted by plans-library)
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

Manual-invoke only (`disable-model-invocation: true`). Triggered as `/plan-agent:implementation-plan <objective>`.

- **Invocation & Arguments** — reads `$ARGUMENTS`; parses objective + `--quick`/`--no-clarify`/`--no-align`/`--no-interview`/`--type`/`--template`/`--dir`/`--priority` flags with smart defaults
- **Workflow Steps 1–8** — Clarify, Create, Frontmatter, Rename, Align, Interview (Step 5b), Commit, Status, Open
- **Required Structure** — context, objective, steps (with per-step *why*/*verify*), acceptance criteria, verification, next-steps (with Wish List), unresolved-questions
- **Writing Style** — direct, imperative, developer-friendly; HTML-escapes all user-supplied content
- **Skeleton reference** — points to `reference/SKELETON.html` (only supported template; `minimal`, `adr`, and `spike` are planned)

### `finalize-plan` Skill

Manual-invoke only (`disable-model-invocation: true`). Triggered as `/plan-agent:finalize-plan [plan-filename.html]`.

Reviews an HTML plan for codebase implementation evidence with per-criterion verification:
1. Reads the plan's acceptance criteria
2. Maps implementation evidence to individual criteria, classifying each as `verified` or `unverified`
3. Presents a confirmation summary with per-criterion verification status
4. Offers three completion options: check all, only auto-check verified, or cancel
5. On confirmation: checks acceptance-criteria boxes, adds `completed` class to step cards, updates `<html data-status>`, `<meta name="plan-status">`, and visible badge
6. If only verified criteria are checked, status is set to `in-progress` rather than `completed`

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
