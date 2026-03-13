# Validation Rules Reference

Official docs: <https://code.claude.com/docs/en/plugins-reference>

Use `WebFetch` on the URL above for the latest spec if the user requests "use latest docs".

## Manifest Rules

| ID | Check | Severity | Fix |
|----|-------|----------|-----|
| M01 | `name` field exists | ERROR | Add `"name": "plugin-name"` to plugin.json |
| M02 | `name` is lowercase + hyphens + numbers only | ERROR | Rename to kebab-case |
| M03 | `name` ≤64 characters | ERROR | Shorten the name |
| M04 | `name` does not contain `anthropic` or `claude` | ERROR | Choose a different name |
| M05 | `description` field exists | WARNING | Add a brief description |
| M06 | No `version` field in plugin.json (relative-path) | ERROR | Remove `version` from plugin.json; set it in marketplace.json only |
| M07 | `homepage` points to plugin directory, not repo root | WARNING | Update to include `/tree/main/plugins/[name]` |

## Structure Rules

| ID | Check | Severity | Fix |
|----|-------|----------|-----|
| S01 | `.claude-plugin/plugin.json` exists | ERROR | Create the manifest file |
| S02 | No components inside `.claude-plugin/` | ERROR | Move commands/skills/agents to plugin root directories |
| S03 | Skill SKILL.md is inside named subdirectory | WARNING | Move to `skills/[name]/SKILL.md` |
| S04 | CHANGELOG.md exists | WARNING | Create a changelog |
| S05 | No unexpected files in `.claude-plugin/` | INFO | Only `plugin.json` should be here |

## Command Rules

| ID | Check | Severity | Fix |
|----|-------|----------|-----|
| C01 | Has YAML frontmatter (`---` delimiters) | ERROR | Add frontmatter block |
| C02 | `description` in frontmatter | ERROR | Add `description:` field |
| C03 | File is kebab-case `.md` | WARNING | Rename file |

## Skill Rules

| ID | Check | Severity | Fix |
|----|-------|----------|-----|
| K01 | Has YAML frontmatter | ERROR | Add frontmatter block |
| K02 | `name` field present | ERROR | Add `name:` field |
| K03 | `name` is kebab-case, ≤64 chars | ERROR | Fix name format |
| K04 | `description` field present | ERROR | Add `description:` field |
| K05 | `description` ≤1,024 chars | ERROR | Shorten description |
| K06 | Description contains "Use when..." | WARNING | Add trigger phrases |
| K07 | Description contains "Does NOT..." | WARNING | Add scope exclusion |
| K08 | Directory name matches `name` field | WARNING | Rename directory or field |

## Agent Rules

| ID | Check | Severity | Fix |
|----|-------|----------|-----|
| A01 | Has YAML frontmatter | ERROR | Add frontmatter block |
| A02 | `name` field present, kebab-case, ≤64 chars | ERROR | Fix name |
| A03 | `description` field present, ≤1,024 chars | ERROR | Fix description |
| A04 | `tools` and `disallowedTools` not both set | ERROR | Remove one; they are mutually exclusive |
| A05 | `model` is valid (sonnet/opus/haiku/inherit) | ERROR | Fix model value |
| A06 | Filename matches `name` field | WARNING | Rename file or field |

## Hook Rules

| ID | Check | Severity | Fix |
|----|-------|----------|-----|
| H01 | Valid JSON | ERROR | Fix JSON syntax |
| H02 | Event names are valid | ERROR | Use: PreToolUse, PostToolUse, Notification, Stop, SubAgentStop |
| H03 | Each hook has `matcher` | WARNING | Add matcher pattern |

## MCP Rules

| ID | Check | Severity | Fix |
|----|-------|----------|-----|
| P01 | Valid JSON | ERROR | Fix JSON syntax |
| P02 | Each server has `command` | ERROR | Add command field |
