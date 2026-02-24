# dev-tools Plugin

Code formatting for JavaScript, TypeScript, Python, CSS, HTML, and Markdown. Applies the right formatter for each file type automatically.

## Purpose

This plugin provides a single `/dev-tools:format` command that detects the language of the target file or directory and applies the appropriate formatting tool (Prettier, Black, or autopep8). It handles the formatter selection so you don't have to remember which tool to use.

**Note:** As of v2.0.0, this plugin contains only the `format` command. The `code-review`, `claude-md-optimizer`, and `plan-interview` skills have been extracted to their own standalone plugins for better discoverability and independent versioning. See [CHANGELOG.md](CHANGELOG.md) for migration details.

## Commands

| Command | Description |
|---------|-------------|
| `/dev-tools:format [path]` | Format a file or directory using the appropriate formatter |

## Usage

### Format the current file

```
/dev-tools:format
```

### Format a specific file

```
/dev-tools:format src/index.ts
/dev-tools:format components/Button.tsx
```

### Format a directory

```
/dev-tools:format src/
/dev-tools:format .
```

## Supported Languages

| Language | Formatter |
|----------|-----------|
| JavaScript / TypeScript | Prettier |
| Python | Black (preferred) or autopep8 |
| JSON | Prettier |
| Markdown | Prettier |
| CSS / SCSS | Prettier |
| HTML | Prettier |

## Plugin Structure

```
dev-tools/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest (v2.0.0)
├── commands/
│   └── format.md            # Format command
├── CHANGELOG.md             # Version history
└── README.md                # This file
```

## Installation

```
/plugin install dev-tools@agentics-kit
```

Or load directly for local testing:

```bash
claude --plugin-dir ./plugins/dev-tools
```
