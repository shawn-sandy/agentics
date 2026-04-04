# agentic-plugin-dev

Create, manage, and validate Claude Code plugins — scaffold new plugins, manage marketplace entries, and audit plugin structure.

## Features

| Skill | Trigger | What It Does |
|-------|---------|--------------|
| `plugin-creator` | "create a plugin", "scaffold a plugin" | Walks through a guided workflow to scaffold a complete plugin with manifest, components, and changelog |
| `plugin-manager` | "list marketplace plugins", "bump version" | Manages entries in `marketplace.json` — list, add, remove, update, bump versions |
| `plugin-validator` | "validate a plugin", "check plugin structure" | Runs structural validation against the official spec and produces a PASS/FAIL report |

## Installation

### From marketplace

```bash
/plugin marketplace add /path/to/agentics
/plugin install agentic-plugin-dev@agentics-kit
```

### Local testing

```bash
claude --plugin-dir ./plugins/agentic-plugin-dev
```

## Usage

### Create a new plugin

> "Create a new plugin called my-awesome-tool with a skill and two commands"

The `plugin-creator` skill will walk you through requirements gathering, component details, manifest generation, and file creation.

### Manage marketplace entries

> "List all plugins in the marketplace"
> "Bump the hello-world plugin version to a minor release"

The `plugin-manager` skill handles marketplace entry CRUD and version management.

### Validate a plugin

> "Validate the hello-world plugin"

The `plugin-validator` skill checks manifest fields, directory structure, component frontmatter, and marketplace cross-references.

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
