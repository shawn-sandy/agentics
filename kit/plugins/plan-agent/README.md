# plan-agent Plugin

Explicit plan authoring as a Claude Code plugin — invoke `/plan-agent:author <objective>` to run the full §0–§7 planning workflow on demand, plus an automatic filename validation hook.

## Overview

This plugin packages the Plan Mode workflow (§0 Assess through §7 Status), required plan structure, and writing style into a **manual-invoke** skill (`author`, `disable-model-invocation: true`). Planning only happens when you explicitly call it — the skill does not auto-activate on ambient intent.

It also ships a `PostToolUse` hook that enforces `verb-target` kebab-case filenames on plan files the moment they are written.

Installers get on-demand planning with argument support and the filename guardrail without maintaining a global `~/.claude/rules/plan-mode.md` file by hand.

## Features

| Component | Type | Activation |
|-----------|------|-----------|
| `author` | Skill (`disable-model-invocation`) | Manual only — invoke as `/plan-agent:author <objective>` |
| `validate-plan-filename` | Hook (`PostToolUse`) | Fires automatically on every `Write`/`Edit` — validates plan filenames |

**Optional pairing:** install `plan-interview` to get `/plan-interview:plan-status` for automating the `status` frontmatter updates referenced in §7, and to enable the `--interview` flag.

## Installation

**Requires:** Claude Code 1.0.33 or later.

```
/plugin marketplace add shawn-sandy/agentics
/plugin install plan-agent@agentics-kit
```

Or load directly for local testing:

```bash
claude --plugin-dir ./kit/plugins/plan-agent
```

## Usage

### Skill (explicit invocation)

Invoke `/plan-agent:author` with a free-text objective:

```
/plan-agent:author create a todo app for ravens
/plan-agent:author fix the login redirect bug in auth middleware
/plan-agent:author refactor the user settings module into smaller services
```

**Flags:**

| Flag | Effect |
|------|--------|
| `--quick` | Skip §1 Clarify and §5 Align |
| `--type <kind>` | Preset frontmatter `type:` (`feature`, `fix`, `refactor`, `docs`, `chore`) |
| `--dir <path>` | Override directory resolution; write the plan to this path |
| `--interview` | After writing the plan, run `plan-interview:plan-interview` before `ExitPlanMode` (requires `plan-interview` plugin) |

**Examples with flags:**

```
/plan-agent:author --quick --type fix patch the login redirect
/plan-agent:author --dir tmp/plans add dark mode toggle
/plan-agent:author --interview create a new payment integration
```

**Smart defaults when flags are absent:** `--type` is inferred from the leading verb (`add`/`create`/`build` → `feature`; `fix`/`patch` → `fix`; `refactor`/`rename` → `refactor`; `document`/`docs` → `docs`). A detailed, specific objective (≥ 8 words with concrete names) is treated as `--quick` automatically.

The skill enforces the full §0–§7 workflow:

1. **Assess** — determines whether a plan is warranted
2. **Clarify** — resolves ambiguous requirements (skipped with `--quick`)
3. **Create** — places the plan in the right directory with a `verb-target` filename
4. **Frontmatter** — adds `status`, `type`, `created`, `repo-name`
5. **Rename** — ensures the filename is meaningful before committing
6. **Align** — confirms each step matches the objective (skipped with `--quick`)
7. **Commit** — commits the plan alongside related changes
8. **Status** — tracks `todo` → `in-progress` → `completed`

### Hook (automatic filename validation)

The `validate-plan-filename` hook fires on every `Write`/`Edit` that touches a `.md` file in the configured plans directory. It exits 2 (actionable feedback) when the filename violates `verb-target` kebab-case, and exits 0 silently on a valid name.

**Valid names:** `add-dark-mode-toggle`, `fix-login-redirect`, `refactor-auth-module`

**Rejected patterns:**
- Non-kebab-case or uppercase letters
- Harness-generated hex suffixes (e.g. `fix-auth-a3f9b2c1`)
- Trailing dates in the filename (use frontmatter `created:` instead)
- Generic placeholders (`plan`, `untitled`, `draft`, `temp`)
- First token is not an imperative verb
- Second token is a stop-word (`the`, `a`, `an`, `this`, ...)

Plans with `status: completed` in frontmatter are skipped (no rename required for shipped work).

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

## Plugin Structure

```
plan-agent/
  .claude-plugin/
    plugin.json             — Plugin manifest
  skills/
    author/
      SKILL.md              — Plan Mode workflow, arguments, structure, writing style
      reference/
        SKELETON.md         — Starter template for new plans
  hooks/
    validate-plan-filename.py  — PostToolUse filename enforcement script
  hooks.json                — Hook registration (Write|Edit matcher)
  README.md
  CHANGELOG.md
```

## Components

### `author` Skill

Manual-invoke only (`disable-model-invocation: true`). Triggered as `/plan-agent:author <objective>`.

- **Invocation & Arguments** — reads `$ARGUMENTS`; parses objective + `--quick`/`--type`/`--dir`/`--interview` flags with smart defaults
- **Enter plan mode** — bootstraps `EnterPlanMode` via `ToolSearch` and calls it before drafting
- **Workflow §0–§7** — Assess, Clarify, Create, Frontmatter, Rename, Align, Commit, Status
- **Required Structure** — context, objective, steps (with per-step *why*/*verify*), acceptance criteria, verification, next-steps, unresolved-questions
- **Writing Style** — direct, imperative, developer-friendly
- **Skeleton reference** — points to `reference/SKELETON.md` one level deep

Both `EnterPlanMode` and `ExitPlanMode` are deferred tools. The skill loads them via `ToolSearch` (`select:EnterPlanMode`, `select:ExitPlanMode`) before calling each.

### `validate-plan-filename` Hook

Pure Python 3 stdlib — no external dependencies, portable across install locations. Uses `${CLAUDE_PLUGIN_ROOT}` for the script path so it works regardless of where the plugin is installed.

The `classify_filename()` function checks:
1. Strict kebab-case (lowercase letters, digits, hyphens only)
2. No harness hex suffix
3. No trailing date
4. Not a generic placeholder name
5. First token is in the imperative verb set
6. Second token is not a stop-word

### Optional: `plan-interview` pairing

The `author` skill §7 references `plan-interview:plan-status` as an optional cross-plugin helper for automating status updates, and `--interview` runs the full stress-test interview. Install both plugins to get the full authoring + lifecycle management experience:

```
/plugin install plan-agent@agentics-kit
/plugin install plan-interview@agentics-kit
```
