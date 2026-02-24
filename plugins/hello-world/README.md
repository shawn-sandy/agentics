# hello-world Plugin

A minimal reference plugin demonstrating the basic structure of Claude Code plugins. This is the canonical starting point for understanding how plugins work in the agentics marketplace.

## Purpose

The `hello-world` plugin is intentionally minimal. It contains exactly what a Claude Code plugin needs — a manifest, a single command, and this README — and nothing else. Use it as a template when creating your own plugin or as a sanity check when testing marketplace integration.

## Commands

| Command | Description |
|---------|-------------|
| `/hello-world:greet [name]` | Greets the user, optionally by name |

## Usage

### Basic greeting

```
/hello-world:greet
```

### Personalized greeting

```
/hello-world:greet Alice
```

## Plugin Structure

```
hello-world/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/
│   └── greet.md             # Greeting command
└── README.md                # This file
```

## Installation

```
/plugin install hello-world@agentics-kit
```

Or load directly for local testing:

```bash
claude --plugin-dir ./plugins/hello-world
```

## What this plugin demonstrates

1. **Minimal plugin.json** — required fields only (`name`, `version`, `description`)
2. **Command structure** — YAML frontmatter + markdown instructions
3. **Argument handling** — accessing user input via `$ARGUMENTS`
4. **Plugin discoverability** — `keywords` field for marketplace search
