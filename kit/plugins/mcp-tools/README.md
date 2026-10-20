# mcp-tools

Diagnose and fix MCP server setup issues in Claude Code.

## Overview

MCP servers configured with a floating version (`npx <package>@latest`) drift: each new
release can demand dependencies the machine does not have. In Playwright's case every
release of `@playwright/mcp` is built on a different Playwright version, and each
Playwright version wants one specific Chromium build — so every release re-prompts for
a browser download and can fail to connect. The first skill in this plugin detects and
fixes that case.

## Features

| Skill | Invocation | What it does |
|-------|------------|--------------|
| `fix-playwright-mcp` | `/mcp-tools:fix-playwright-mcp` (command-only) | Diagnoses the Playwright MCP Chromium mismatch, then pins a user-scope server to one release driving the system Chrome |

## Installation

```text
/plugin marketplace add shawn-sandy/agentics
/plugin install mcp-tools@agentics-kit
```

## Usage

Run `/mcp-tools:fix-playwright-mcp` when:

- sessions keep prompting to download a Playwright browser,
- the Playwright plugin's MCP server fails to connect at session start,
- `~/.npm/_npx` keeps accumulating copies of `@playwright/mcp`.

The skill reports a five-signal diagnosis (plugin state, existing server, installed
Chromium builds, npx cache drift, system Chrome), asks which fix to apply, backs up
`~/.claude/settings.json`, applies the chosen fix, and verifies every change by
re-reading it. It never edits the plugin's cached `.mcp.json`, which plugin updates
overwrite.

## Structure

```text
mcp-tools/
├── .claude-plugin/
│   └── plugin.json
├── CHANGELOG.md
├── README.md
└── skills/
    └── fix-playwright-mcp/
        └── SKILL.md
```

## Components

- **Skills:** `fix-playwright-mcp` — command-only (`disable-model-invocation: true`),
  so it never triggers from natural language.
- No commands, agents, hooks, or scripts.
