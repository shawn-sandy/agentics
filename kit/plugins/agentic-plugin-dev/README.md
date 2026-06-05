# agentic-plugin-dev

Create, manage, and validate Claude Code plugins — scaffold new plugins, manage marketplace entries, and audit plugin structure.

## Installation

### Via Marketplace (recommended)
```bash
/plugin install agentic-plugin-dev@agentics-kit
```

### Local Development
```bash
claude --plugin-dir ./kit/plugins/agentic-plugin-dev
```

## Usage

All three components are skills — they activate automatically when your request matches the trigger description. No explicit command invocation is required.

### Skills

| Skill | Activation | Description |
|-------|-----------|-------------|
| `plugin-creator` | Auto — "create a plugin", "scaffold a plugin" | Scaffolds a complete Claude Code plugin from scratch. Generates manifest, commands, skills, and agents for selected component types. |
| `plugin-manager` | Auto — "list marketplace plugins", "add a plugin", "bump version" | Manages plugin entries in `marketplace.json`. Adds, removes, bumps versions, and updates metadata for marketplace plugins. |
| `plugin-validator` | Auto — "validate a plugin", "check plugin structure", "audit a plugin" | Validates a plugin against the official Claude Code spec. Checks manifest fields, directory structure, and frontmatter for compliance. |

All skills declare `allowed-tools` explicitly in their frontmatter for consistent, session-independent tool access.

### Create a new plugin

> "Create a new plugin called my-awesome-tool with a skill and two commands"

The `plugin-creator` skill walks through requirements gathering, component details, manifest generation, and file creation.

### Manage marketplace entries

> "List all plugins in the marketplace"
> "Bump the hello-world plugin version to a minor release"

The `plugin-manager` skill handles marketplace entry CRUD and version management.

### Validate a plugin

> "Validate the hello-world plugin"

The `plugin-validator` skill checks manifest fields, directory structure, component frontmatter, and marketplace cross-references, then produces a PASS/FAIL report.

## Features

| Skill | Trigger | What It Does |
|-------|---------|--------------| 
| `plugin-creator` | "create a plugin", "scaffold a plugin" | Walks through a guided workflow to scaffold a complete plugin with manifest, components, and changelog |
| `plugin-manager` | "list marketplace plugins", "bump version" | Manages entries in `marketplace.json` — list, add, remove, update, bump versions |
| `plugin-validator` | "validate a plugin", "check plugin structure" | Runs structural validation against the official spec and produces a PASS/FAIL report |

## Plugin Structure

```
agentic-plugin-dev/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── plugin-creator/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── plugin-json-schema.md
│   │       └── component-templates.md
│   ├── plugin-manager/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── marketplace-schema.md
│   └── plugin-validator/
│       ├── SKILL.md
│       └── references/
│           └── validation-rules.md
├── CHANGELOG.md
└── README.md
```

## Related Plugins

- **skill-reviewer** — Review and audit individual SKILL.md files
- **agent-creator** — Scaffold agent-based plugins
- **marketplace-builder** — Set up marketplace infrastructure from scratch
