# plan-agent Plugin

Explicit plan creation as a Claude Code plugin — invoke `/plan-agent:planning <objective>` to run the full Steps 0–7 planning workflow on demand, plus an automatic filename validation hook.

## Overview

This plugin packages the Plan Mode workflow (Step 0 Assess through Step 7 Status), required plan structure, and writing style into a **manual-invoke** skill (`planning`, `disable-model-invocation: true`). Planning only happens when you explicitly call it — the skill does not auto-activate on ambient intent.

Plans are written as **self-contained `.html` files** — interactive, visually rich, and openable directly in a browser. No markdown output.

It also ships a `PostToolUse` hook that enforces `verb-target` kebab-case filenames on plan files the moment they are written.

Installers get on-demand planning with argument support and the filename guardrail without maintaining a global `~/.claude/rules/plan-mode.md` file by hand.

## Features

| Component | Type | Activation |
|-----------|------|-----------|
| `planning` | Skill (`disable-model-invocation`) | Manual only — invoke as `/plan-agent:planning <objective>` |
| `plans-library` | Skill | Auto-activates on "browse plans", "view plan history", "open plans index" intent |
| `validate-plan-filename` | Hook (`PostToolUse`) | Fires automatically on every `Write`/`Edit` — validates plan filenames |

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

#### `planning` — Manual invoke only

Creates implementation plans from a free-text objective. Enforces verb-target filenames, structure, and HTML metadata.

Manual invoke only — use `/plan-agent:planning` explicitly. This skill has `disable-model-invocation: true` and will not auto-activate on ambient intent.

```
/plan-agent:planning create a todo app for ravens
/plan-agent:planning fix the login redirect bug in auth middleware
/plan-agent:planning refactor the user settings module into smaller services
```

**Full invocation syntax:**

```
/plan-agent:planning <objective> [--quick] [--no-clarify] [--no-align] [--no-interview] [--type feature|fix|refactor|docs|chore] [--template default] [--dir <path>] [--priority low|medium|high|critical]
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
/plan-agent:planning --quick --type fix patch the login redirect
/plan-agent:planning --no-clarify add dark mode toggle
/plan-agent:planning --dir tmp/plans add dark mode toggle
/plan-agent:planning --no-interview fix a config typo
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

### Hook (automatic filename validation)

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
    planning/
      SKILL.md              — Plan Mode workflow, arguments, structure, writing style
      reference/
        SKELETON.html       — Default full-plan HTML template
        SKELETON-minimal.md — Minimal template (context + steps + criteria + verification)
        SKELETON-adr.md     — Architecture Decision Record template
        SKELETON-spike.md   — Spike / time-boxed investigation template
    plans-library/
      SKILL.md              — Gallery scan/parse/render workflow
  templates/
    plans-gallery.html      — Static gallery template (substituted by plans-library)
  hooks/
    validate-plan-filename.py  — PostToolUse filename enforcement script
  hooks.json                — Hook registration (Write|Edit matcher)
  README.md
  CHANGELOG.md
```

## Components

### `planning` Skill

Manual-invoke only (`disable-model-invocation: true`). Triggered as `/plan-agent:planning <objective>`.

- **Invocation & Arguments** — reads `$ARGUMENTS`; parses objective + `--quick`/`--no-clarify`/`--no-align`/`--no-interview`/`--type`/`--template`/`--dir`/`--priority` flags with smart defaults
- **Workflow Steps 1–8** — Clarify, Create, Frontmatter, Rename, Align, Interview (Step 5b), Commit, Status, Open
- **Required Structure** — context, objective, steps (with per-step *why*/*verify*), acceptance criteria, verification, next-steps (with Wish List), unresolved-questions
- **Writing Style** — direct, imperative, developer-friendly; HTML-escapes all user-supplied content
- **Skeleton reference** — points to `reference/SKELETON.html` (only supported template; `minimal`, `adr`, and `spike` are planned)

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

The skill scans all `.html` plan files in the plans directory (resolves the same `plansDirectory` setting as the `planning` skill), reads each plan's `<meta>` tags and `<title>`, renders them into a filterable gallery, writes `docs/plans/index.html`, and opens it in the browser.

**Gallery features:**
- Filter chips for status: **All / Todo / In Progress / Completed**
- Filter chips for type: **All / Feature / Fix / Refactor / Docs / Chore**
- Title search box
- Grid and list view toggle
- Each card links directly to the underlying plan file

The scan always excludes `index.html` itself and the `docs/plans/archive/` subdirectory.

### Optional: `plan-interview` pairing

The built-in Step 5b Interview runs a lightweight stress-test during plan creation. For deeper standalone reviews (multi-round interviews with product-plan routing, plan-name validation, and HTML artifact generation), install the `plan-interview` plugin:

```
/plugin install plan-interview@agentics-kit
```
