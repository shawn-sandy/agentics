---
name: plugin-validator
description: "Validates a plugin against the official Claude Code spec. Checks manifest fields, directory structure, and frontmatter for compliance. Use when the user asks to validate or audit a plugin."
allowed-tools: AskUserQuestion, Glob, Read
---

## Overview

Runs a comprehensive structural validation against a Claude Code plugin, checking manifest fields, directory layout, component frontmatter, and marketplace cross-references. Produces a scored report with PASS/FAIL results.

Follow these steps exactly.

## When not to use

Does not review skill quality — use skill-reviewer. Does not review agent quality — use agent-reviewer.

## Table of Contents

- [Step 1: Resolve Target Plugin](#step-1-resolve-target-plugin)
- [Step 2: Structural Scan](#step-2-structural-scan)
- [Step 3: Manifest Validation](#step-3-manifest-validation)
- [Step 4: Component Validation](#step-4-component-validation)
- [Step 5: Present Report](#step-5-present-report)

---

## Step 1: Resolve Target Plugin

Determine which plugin to validate:

1. If the user provided an explicit path, use it
2. If the user named a plugin, search for `plugins/[name]/.claude-plugin/plugin.json` using `Glob`
3. If neither, ask: "Which plugin should I validate? Provide a name or path."

Verify the target directory exists and contains `.claude-plugin/plugin.json`. If not, report: "No plugin found at `[path]` — missing `.claude-plugin/plugin.json`."

---

## Step 2: Structural Scan

Inventory the plugin directory using `Glob` and `Read`:

### Directory Check

Scan for these directories and files:

| Path | Expected | Check |
|------|----------|-------|
| `.claude-plugin/plugin.json` | Required | Must exist |
| `commands/*.md` | Optional | If present, validate each |
| `skills/*/SKILL.md` | Optional | If present, validate each |
| `agents/*.md` | Optional | If present, validate each |
| `hooks.json` | Optional | If present, validate JSON |
| `.mcp.json` | Optional | If present, validate JSON |
| `CHANGELOG.md` | Recommended | Warn if missing |

### Misplacement Check

Flag components found in wrong locations:

- Commands, skills, or agents inside `.claude-plugin/` — **ERROR**: "Components should not be inside `.claude-plugin/`. Move `[file]` to the appropriate directory."
- SKILL.md files not inside a named subdirectory of `skills/` — **WARNING**: "Skill files should be at `skills/[name]/SKILL.md`, not directly in `skills/`."

---

## Step 3: Manifest Validation

Read `.claude-plugin/plugin.json` and validate using rules from `references/validation-rules.md`:

### Required Field Checks

| Check | Rule | Severity |
|-------|------|----------|
| `name` exists | Must be present | ERROR |
| `name` format | Lowercase, hyphens, numbers only. ≤64 chars | ERROR |
| `name` restricted | Must not contain `anthropic` or `claude` | ERROR |
| `description` exists | Should be present | WARNING |

### Version Conflict Check

1. Check if `version` is set in `plugin.json`
2. Use `Glob` to find `.claude-plugin/marketplace.json` in the project root
3. If a marketplace entry exists for this plugin:
   - If `plugin.json` has `version` — **ERROR**: "For relative-path plugins, `version` should only be in `marketplace.json`. Remove `version` from `plugin.json`."
   - Cross-check that the marketplace `source` path resolves to this plugin directory

### Marketplace Cross-Reference

When a `marketplace.json` exists:

1. Find the entry matching this plugin's name
2. Verify `source` path resolves to the validated directory
3. If no entry found — **INFO**: "Plugin is not registered in the marketplace."
4. If `source` path doesn't match — **WARNING**: "Marketplace source path `[path]` does not resolve to the validated plugin directory."

---

## Step 4: Component Validation

Validate each component found in Step 2:

### Commands (`commands/*.md`)

| Check | Rule | Severity |
|-------|------|----------|
| YAML frontmatter | Must have `---` delimiters | ERROR |
| `description` field | Must be present in frontmatter | ERROR |
| File naming | Kebab-case `.md` files | WARNING |

### Skills (`skills/*/SKILL.md`)

| Check | Rule | Severity |
|-------|------|----------|
| YAML frontmatter | Must have `---` delimiters | ERROR |
| `name` field | Must be present, kebab-case, ≤64 chars | ERROR |
| `description` field | Must be present, ≤1,024 chars | ERROR |
| Trigger phrases | Description should contain "Use when..." | WARNING |
| Scope exclusion | Description or body should contain "Does NOT..." or a `## When not to use` section | WARNING |
| Directory naming | Directory name should match `name` field | WARNING |

### Agents (`agents/*.md`)

| Check | Rule | Severity |
|-------|------|----------|
| YAML frontmatter | Must have `---` delimiters | ERROR |
| `name` field | Must be present, kebab-case, ≤64 chars | ERROR |
| `description` field | Must be present, ≤1,024 chars | ERROR |
| `tools`/`disallowedTools` | Must not both be set | ERROR |
| File naming | Filename should match `name` field | WARNING |

### Hooks (`hooks.json`)

| Check | Rule | Severity |
|-------|------|----------|
| Valid JSON | Must parse without errors | ERROR |
| Event names | Must be valid hook events | ERROR |
| `matcher` field | Must be present per hook entry | WARNING |

### MCP Servers (`.mcp.json`)

| Check | Rule | Severity |
|-------|------|----------|
| Valid JSON | Must parse without errors | ERROR |
| `command` field | Must be present per server | ERROR |

---

## Step 5: Present Report

Present results as a validation report:

```
## Plugin Validation Report: [plugin-name]

**Location:** [path]
**Result:** [PASS/FAIL] ([error count] errors, [warning count] warnings, [info count] info)

### Manifest
- [PASS/FAIL] Name: [name] ([validation detail])
- [PASS/FAIL] Description: [present/missing]
- [PASS/FAIL] Version conflict: [none/conflict detail]
- [PASS/INFO] Marketplace: [registered/not registered]

### Structure
- [PASS/FAIL] Plugin directory: [valid/issues]
- [PASS/WARNING] Misplaced files: [none/list]
- [PASS/WARNING] CHANGELOG.md: [present/missing]

### Components
- [PASS/FAIL] Commands ([count]): [details]
- [PASS/FAIL] Skills ([count]): [details]
- [PASS/FAIL] Agents ([count]): [details]
- [PASS/FAIL] Hooks: [valid/invalid/not present]
- [PASS/FAIL] MCP: [valid/invalid/not present]
```

**Overall result:**
- **PASS** — No errors found (warnings are acceptable)
- **FAIL** — One or more errors found

If errors exist, list each with a fix recommendation.
