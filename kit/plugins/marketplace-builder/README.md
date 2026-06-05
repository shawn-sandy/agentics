# marketplace-builder

Evaluate a repository and scaffold Claude Code skill marketplace infrastructure.

## Overview

The marketplace-builder plugin helps developers turn any repository into a functioning Claude Code skill marketplace. It evaluates the current state of a repository across 5 dimensions, scores marketplace readiness, and offers to generate the missing infrastructure files.

**Who it's for:** Developers who want to create and distribute their own Claude Code plugins through a marketplace, either from scratch or by adding marketplace support to an existing project.

## Features

- **5-dimension audit** scoring repository foundation, documentation, code organization, developer experience, and marketplace readiness (max 10 points)
- **Marketplace scaffolding** generates `.claude-plugin/marketplace.json`, plugin directories, SKILL.md stubs, CLAUDE.md, and starter rules
- **Official schema compliance** follows the marketplace spec from https://code.claude.com/docs/en/plugin-marketplaces
- **Scan-data-driven templates** derives marketplace metadata from git config, package manifests, and README content
- **Per-file confirmation** before writing any generated file to disk

## Installation

### Via Marketplace (recommended)

```bash
/plugin install marketplace-builder@agentics-kit
```

### Local Development

```bash
claude --plugin-dir ./kit/plugins/marketplace-builder
```

## Usage

This plugin contains one skill — there are no commands. The skill auto-activates when your intent matches its description.

### Skills

#### building-marketplaces

Auto-activated — triggers when you ask to build, scaffold, or evaluate a marketplace.

Trigger phrases:

- "Build a marketplace"
- "Set up a skill marketplace"
- "Create a plugin marketplace"
- "Scaffold marketplace files"
- "Make this repo a marketplace"
- "Evaluate marketplace readiness"

### Example Workflow

1. Navigate to a repository you want to turn into a marketplace
2. Ask: "Help me set up a skill marketplace for this repo"
3. The skill scans the repository and presents a scored readiness report
4. Review the scores and recommendations
5. Choose which files to scaffold (marketplace.json, plugin directories, CLAUDE.md, etc.)
6. Confirm each file before it's written to disk
7. Run `claude plugin validate .` to verify the result

## Plugin Structure

```
marketplace-builder/
  .claude-plugin/
    plugin.json
  skills/
    building-marketplaces/
      SKILL.md
      references/
        audit-dimensions.md
        marketplace-templates.md
        checklist.md
  README.md
  CHANGELOG.md
```

All skills declare `allowed-tools` explicitly in their frontmatter for consistent, session-independent tool access.

## Components

### Skill: building-marketplaces

A 6-step sequential workflow:

1. **Resolve target repository** -- confirm which repo to evaluate
2. **Scan and inventory** -- collect metrics on files, structure, and marketplace infrastructure
3. **Run 5-dimension audit** -- score repository foundation, documentation, code organization, developer experience, and marketplace readiness
4. **Present scored report** -- table with grades, critical gaps, and top 3 actions
5. **Offer marketplace scaffolding** -- generate missing files based on scan results
6. **Write confirmation** -- per-file confirmation before writing

## What Gets Scaffolded

Based on what the repository is missing, the skill can generate:

| File | When offered |
|------|-------------|
| `.claude-plugin/marketplace.json` | No marketplace config exists, or existing one is broken |
| `CLAUDE.md` | No CLAUDE.md at root (minimal stub with TODOs) |
| `.claude/rules/*.md` | No rules directory (generic plugin and marketplace rules) |
| `.gitignore` additions | Missing `.claude/worktrees/` and `CLAUDE.local.md` entries |
| Plugin directory scaffold | User wants to add a new plugin to the marketplace |
| `CLAUDE.local.md` | No local override template exists |
| `.claude/settings.json` | Optional: team distribution via `extraKnownMarketplaces` |

## Scope

This plugin evaluates **repository-level marketplace readiness**. For deeper analysis of specific files, use:

- **memory-tools** -- audit and optimize CLAUDE.md content quality
- **skill-reviewer** -- audit SKILL.md files against best practices
