---
status: in-progress
created: 2026-02-23
---

# Plan: Plugin Development Guide

## Context

The repo has excellent AI-facing instructions (CLAUDE.md) and plugin-specific READMEs, but no
single human-facing reference guide for creating Claude Code plugins. The gap is particularly
acute for schema validation rules — we discovered three "unrecognized key" errors the hard way
during marketplace registration (`"components"` in marketplace.json, `"category"` in plugin.json).
A focused guide should surface those rules up front and consolidate the practical workflow.

Existing docs to draw from (do not duplicate, reference or link instead):
- `CLAUDE.md` — plugin structure, component patterns, metadata conventions
- `plugins/README.md` — testing workflow, contributing guidelines
- `plugins/hello-world/README.md` — minimal plugin reference
- `plugins/dev-tools/README.md` — multi-component plugin reference
- `CHANGELOG.md` — schema field reference table already written

---

## Output File

`docs/creating-plugins.md`

---

## Steps

1. **Create `docs/` directory** (doesn't exist yet)

2. **Write `docs/creating-plugins.md`** with the following sections:

   ### 1. Prerequisites
   - Claude Code CLI ≥ 1.0.33
   - How to verify: `claude --version`

   ### 2. Plugin Structure
   Canonical directory layout with annotations:
   ```
   my-plugin/
   ├── .claude-plugin/
   │   └── plugin.json     # required manifest
   ├── commands/           # slash commands
   ├── skills/             # auto-activated capabilities
   ├── agents/             # long-running subprocesses
   └── hooks/              # event handlers
   ```

   ### 3. The Manifest (`plugin.json`)
   - Required fields: `name`, `version` (semver X.Y.Z), `description`
   - Optional fields: `author`, `license`
   - **Explicitly forbidden fields** (schema rejects them): `category`, `tags`, `components`
   - Minimal valid example (draw from `tests/fixtures/valid-plugin/plugin.json`)
   - Full example with optional fields (draw from `plugins/hello-world/.claude-plugin/plugin.json`)

   ### 4. Commands
   - File location: `commands/<name>.md`
   - Invocation: `/plugin-name:command-name [args]`
   - Required frontmatter: `description`
   - Variables: `$ARGUMENTS`, `$PWD`
   - Pattern with annotated example (draw from `plugins/hello-world/commands/greet.md`)
   - Multi-step command pattern (draw from `plugins/dev-tools/commands/format.md`)
   - Using `AskUserQuestion` for interactive commands (draw from `plan-review.md`)

   ### 5. Skills
   - File location: `skills/<name>/SKILL.md`
   - Activation: automatic, based on `description` field matching user intent
   - Required frontmatter: `name`, `description`
   - Writing an effective `description` (the description IS the activation trigger)
   - Progressive disclosure pattern: description → summary → steps → examples
   - Example (draw from `plugins/dev-tools/skills/code-review/SKILL.md`)

   ### 6. Agents
   - File location: `agents/<name>.md`
   - Frontmatter: `name`, `description`, `tools`
   - When to use agents vs commands vs skills
   - Minimal example structure (no existing example — write a template)

   ### 7. Hooks
   - File location: `hooks/<event>.md`
   - Available events: `PreToolUse`, `PostToolUse`, `Stop`, `SessionStart`, `SessionEnd`, `UserPromptSubmit`
   - Frontmatter: `event`
   - Minimal example structure (no existing example — write a template)

   ### 8. Testing a Plugin Locally
   - Direct load: `claude --plugin-dir ./plugins/my-plugin`
   - Load multiple: `--plugin-dir` repeated
   - Verify with `/help` inside session

   ### 9. Registering with a Marketplace
   - Marketplace manifest location: `.claude-plugin/marketplace.json` at the **registered directory root**
   - Valid fields for plugin entries: `name`, `version`, `description`, `source`, `category`, `tags`
   - **Explicitly forbidden**: `components` (schema rejects it)
   - Source paths resolve relative to `marketplace.json` — use `./plugins/my-plugin`
   - Registration command: `/plugin marketplace add <path>`
   - Install command: `/plugin install my-plugin@marketplace-name`

   ### 10. Schema Field Quick Reference
   Table (expand on the one already in `CHANGELOG.md`):

   | Field        | `plugin.json` | `marketplace.json` entry |
   |--------------|:---:|:---:|
   | `name`       | required | required |
   | `version`    | required | required |
   | `description`| required | required |
   | `source`     | — | required |
   | `author`     | allowed | — |
   | `license`    | allowed | — |
   | `category`   | **forbidden** | allowed |
   | `tags`       | **forbidden** | allowed |
   | `components` | **forbidden** | **forbidden** |

   ### 11. Common Pitfalls
   - `"category"` in plugin.json → use it only in marketplace.json
   - `"components"` in marketplace.json → not in the schema; CLI auto-discovers
   - `.claude-plugin/` must be at the root of the registered marketplace directory
   - Relative source paths resolve from marketplace.json location — use `./` not `../`
   - Version in plugin.json must match version in marketplace.json entry

---

## Files to Create

| File | Action |
|------|--------|
| `docs/creating-plugins.md` | Create new (~250 lines) |

---

## Verification

- Read the file after writing and confirm all sections are present
- Confirm schema table matches `CHANGELOG.md`
- Confirm code examples are accurate against actual repo files
