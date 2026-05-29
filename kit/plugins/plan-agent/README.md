# plan-agent Plugin

Explicit plan creation as a Claude Code plugin — invoke `/plan-agent:planning <objective>` to run the full §0–§7 planning workflow on demand, plus an automatic filename validation hook.

## Overview

This plugin packages the Plan Mode workflow (§0 Assess through §7 Status), required plan structure, and writing style into a **manual-invoke** skill (`planning`, `disable-model-invocation: true`). Planning only happens when you explicitly call it — the skill does not auto-activate on ambient intent.

Plans are written as **self-contained `.html` files** — interactive, visually rich, and openable directly in a browser. No markdown output.

It also ships a `PostToolUse` hook that enforces `verb-target` kebab-case filenames on plan files the moment they are written.

Installers get on-demand planning with argument support and the filename guardrail without maintaining a global `~/.claude/rules/plan-mode.md` file by hand.

## Features

| Component | Type | Activation |
|-----------|------|-----------|
| `planning` | Skill (`disable-model-invocation`) | Manual only — invoke as `/plan-agent:planning <objective>` |
| `validate-plan-filename` | Hook (`PostToolUse`) | Fires automatically on every `Write`/`Edit` — validates plan filenames |

**Optional pairing:** install `plan-interview` to enable the `--interview` flag for post-plan stress-testing. Note: `plan-interview:plan-status` currently operates on `.md`/YAML plans only and does not support `.html` plans yet.

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
/plan-agent:planning <objective> [--quick] [--no-clarify] [--no-align] [--type feature|fix|refactor|docs|chore] [--template default|minimal|adr|spike] [--dir <path>] [--priority low|medium|high|critical] [--interview]
```

**Flags:**

| Flag | Effect |
|------|--------|
| `--quick` | Shorthand for `--no-clarify --no-align`; skip both §1 Clarify and §5 Align |
| `--no-clarify` | Skip §1 Clarify only |
| `--no-align` | Skip §5 Align only |
| `--type <kind>` | Set plan `type` in HTML metadata (`feature`, `fix`, `refactor`, `docs`, `chore`) |
| `--template <name>` | Reserved — only `default` is currently supported; additional variants are planned |
| `--dir <path>` | Override directory resolution; write the plan to this path |
| `--priority <level>` | Write `priority` to plan HTML metadata (`low`, `medium`, `high`, `critical`) |
| `--interview` | After writing the plan, run `plan-interview:plan-interview` before `ExitPlanMode` (requires `plan-interview` plugin) |

**Examples with flags:**

```
/plan-agent:planning --quick --type fix patch the login redirect
/plan-agent:planning --no-clarify add dark mode toggle
/plan-agent:planning --dir tmp/plans add dark mode toggle
/plan-agent:planning --interview create a new payment integration
```

**Smart defaults when flags are absent:** `--type` is inferred from the leading verb (`add`/`create`/`build` → `feature`; `fix`/`patch` → `fix`; `refactor`/`rename` → `refactor`; `document`/`docs` → `docs`). All skip-flags (`--quick`, `--no-clarify`, `--no-align`) are opt-in only and are never inferred automatically.

The skill enforces the full §0–§7 workflow:

1. **Assess** — determines whether a plan is warranted
2. **Clarify** — resolves ambiguous requirements (skipped with `--quick`)
3. **Create** — places the plan in the right directory with a `verb-target.html` filename
4. **Metadata** — writes HTML `<meta>` tags: `plan-status`, `plan-type`, `plan-created`, `plan-repo`
5. **Rename** — ensures the filename is meaningful before committing
6. **Align** — confirms each step matches the objective (skipped with `--quick`)
7. **Commit** — commits the plan alongside related changes
8. **Status** — tracks `todo` → `in-progress` → `completed` via `<html data-status>` and `<meta name="plan-status">`

### HTML plan output

Every plan is a single self-contained `.html` file (no CDN links, no external assets):

- **Status badge** — colour-coded: grey = todo, amber = in-progress, green = completed
- **Objective card** — prominent highlighted block at the top
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
  hooks/
    validate-plan-filename.py  — PostToolUse filename enforcement script
  hooks.json                — Hook registration (Write|Edit matcher)
  README.md
  CHANGELOG.md
```

## Components

### `planning` Skill

Manual-invoke only (`disable-model-invocation: true`). Triggered as `/plan-agent:planning <objective>`.

- **Invocation & Arguments** — reads `$ARGUMENTS`; parses objective + `--quick`/`--no-clarify`/`--no-align`/`--type`/`--template`/`--dir`/`--priority`/`--interview` flags with smart defaults
- **Enter plan mode** — bootstraps `EnterPlanMode` via `ToolSearch` and calls it before drafting
- **Workflow §0–§7** — Assess, Clarify, Create, Metadata, Rename, Align, Commit, Status
- **Required Structure** — context, objective, steps (with per-step *why*/*verify*), acceptance criteria, verification, next-steps (with Wish List), unresolved-questions
- **Writing Style** — direct, imperative, developer-friendly; HTML-escapes all user-supplied content
- **Skeleton reference** — points to `reference/SKELETON.html` (default) or the matching `SKELETON-<template>.md` for `minimal`, `adr`, and `spike` templates

Both `EnterPlanMode` and `ExitPlanMode` are deferred tools. The skill loads them via `ToolSearch` (`select:EnterPlanMode`, `select:ExitPlanMode`) before calling each.

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

### Optional: `plan-interview` pairing

The `--interview` flag runs the full stress-test interview after writing the plan. Install both plugins for the full planning experience:

```
/plugin install plan-agent@agentics-kit
/plugin install plan-interview@agentics-kit
```
