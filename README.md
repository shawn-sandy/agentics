# agentics

A marketplace system for Claude Code plugins, enabling discovery, distribution, and installation of plugins that extend Claude's capabilities.

## Quick Start

```bash
git clone https://github.com/shawn-sandy/agentics.git
cd agentics
claude --plugin-dir ./plugins/code-review
# Then ask: "Review this code for issues"
```

## Overview

The agentics project provides:

- **Example Plugins** — 7 reference implementations demonstrating Claude Code plugin structure
- **Test Marketplace** — Local marketplace (`agentics-kit`) for testing plugin discovery and installation
- **Plugin Development Guide** — Documentation and patterns for creating your own plugins

## Prerequisites

### Required

- **Claude Code CLI** (version 1.0.33 or later — required for plugin support)
  ```bash
  # Verify installation
  claude --version
  ```

### Optional Tools

- **Git** — For cloning the repository
- **GitHub CLI (`gh`)** — For the git-agent plugin's PR creation

### Platform Support

- **macOS** 12.0 or later
- **Linux** (Ubuntu 20.04+ or equivalent)
- **Windows** (WSL2 recommended for best compatibility)

## Project Structure

```
agentics/
├── .claude-plugin/
│   └── marketplace.json          # Marketplace manifest (agentics-kit)
├── plugins/                      # Example plugins
│   ├── code-review/              # Code review skill
│   ├── plan-interview/           # Plan stress-test (command + skill)
│   ├── claude-md-optimizer/      # CLAUDE.md audit and optimization
│   ├── wcag-compliance-reviewer/ # WCAG 2.2 accessibility compliance
│   ├── skill-reviewer/           # Skill authoring review and testing
│   ├── code-test-suggestion/     # Test suggestion and review
│   └── git-agent/                # Automated git commit and PR creation
├── tests/
│   └── fixtures/                 # Test plugin fixtures
└── README.md                     # This file
```

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/shawn-sandy/agentics.git
   cd agentics
   ```

2. **Load a plugin directly:**
   ```bash
   # Test with code-review plugin
   claude --plugin-dir ./plugins/code-review

   # This starts an interactive Claude Code session.
   # Once Claude responds, ask naturally:
   # "Review this code for issues"
   ```

3. **Verify the plugin loaded:**
   ```bash
   # In the Claude interactive session, list available commands:
   /help
   ```

**Note:** You can test plugins immediately without installing any dependencies. The `--plugin-dir` flag loads plugins directly from your local filesystem and starts an interactive session.

### Troubleshooting

#### "claude: command not found"

The Claude Code CLI is not installed or not in your PATH.

**Solution:**
- Install Claude Code from the official source: https://code.claude.com/docs/en/installation
- Verify installation: `claude --version`
- Ensure you have version 1.0.33 or later (required for plugin support)
- On macOS/Linux: Ensure `~/.local/bin` or the installation directory is in your PATH
- On Windows: Use WSL2 and follow Linux installation steps

#### Plugin not loading

The plugin directory may not exist or the path is incorrect.

**Solution:**
- Verify the path exists: `ls -la ./plugins/code-review`
- Use absolute paths if relative paths aren't working:
  ```bash
  claude --plugin-dir /full/path/to/agentics/plugins/code-review
  ```
- Check that `.claude-plugin/plugin.json` exists in the plugin directory

#### Permission errors

The plugin directory or files may not be readable.

**Solution:**
- Check file permissions: `ls -la ./plugins/code-review`
- Make directory readable: `chmod -R +r ./plugins/code-review`
- Ensure you own the files: `chown -R $USER:$USER ./plugins/`

#### "Input must be provided" error with --plugin-dir

You see an error like: `Error: Input must be provided either through stdin or as a prompt argument when using --print`

**Solution:**
- This error can occur if Claude Code can't start the interactive session properly
- Try providing a prompt directly:
  ```bash
  claude --plugin-dir ./plugins/code-review "List available commands"
  ```
- Or pipe a command:
  ```bash
  echo "Review this code for issues" | claude --plugin-dir ./plugins/code-review
  ```
- Verify your Claude Code version supports plugins: `claude --version` (need 1.0.33+)
- Check plugin.json is valid JSON: `cat plugins/code-review/.claude-plugin/plugin.json | jq`

## Usage Guide

### Single Plugin Testing

Test individual plugins by loading them directly:

```bash
# Test code-review plugin (starts interactive session)
claude --plugin-dir ./plugins/code-review

# Once in the Claude session, ask naturally:
# "Review this code for issues"

# Or provide a prompt directly:
claude --plugin-dir ./plugins/code-review "Review this file for bugs"
```

### Multiple Plugin Testing

Load multiple plugins simultaneously by specifying multiple `--plugin-dir` flags:

```bash
# Load multiple plugins at once (starts interactive session)
claude --plugin-dir ./plugins/code-review --plugin-dir ./plugins/plan-interview

# Once in the Claude session, you can use commands from both plugins:
# "Review this code for issues"
# /plan-interview:plan-interview docs/plans/my-plan.md

# Or provide a prompt directly:
claude --plugin-dir ./plugins/code-review --plugin-dir ./plugins/plan-interview "Review my code"
```

### Commands vs Skills

**Commands** require explicit invocation using the `/plugin:command` syntax:
```bash
# Explicit command invocation
/plan-interview:plan-interview docs/plans/my-plan.md
```

**Skills** activate automatically based on your request:
```bash
# Load the code-review plugin, then just ask naturally
"Can you review this code for issues?"
"Check this file for bugs"

# Load the plan-interview plugin, then describe your intent
"Stress-test this plan before I start coding"
```

**Tip:** Use `/help` in Claude to see all available commands from loaded plugins.

## Plugins

### code-review `v2.1.1`

Systematic code review across quality, bugs, security vulnerabilities, breaking changes, and regressions with complexity rating.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `code-review-agent` | Review code, check for bugs, analyze code quality, look for security issues, or detect breaking changes |

```bash
claude --plugin-dir ./plugins/code-review
# "Review this function for bugs"
# "Check this file for security issues"
```

[View Plugin Documentation](./plugins/code-review/README.md)

---

### plan-interview `v1.3.0`

Stress-tests implementation plans with structured multi-round interviews before coding begins.

**Commands:**

| Command | Description |
|---------|-------------|
| `/plan-interview:plan-interview [plan-file-path]` | Run a structured interview against a plan file |

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `plan-interview` | Stress-test, validate, interview, or find gaps in a plan |

```bash
claude --plugin-dir ./plugins/plan-interview
# /plan-interview:plan-interview
# "Stress-test this plan"
```

[View Plugin Documentation](./plugins/plan-interview/README.md)

---

### claude-md-optimizer `v1.5.0`

Audits and optimizes CLAUDE.md files against Claude Code best practices.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `claude-md-optimizer` | Optimize, audit, or clean up a CLAUDE.md file — also activates when Claude is ignoring instructions |

```bash
claude --plugin-dir ./plugins/claude-md-optimizer
# "Audit my CLAUDE.md file"
# "My Claude is ignoring my instructions — what's wrong?"
```

[View Plugin Documentation](./plugins/claude-md-optimizer/README.md)

---

### wcag-compliance-reviewer `v1.1.0`

Reviews HTML/CSS and React/TypeScript code for WCAG 2.2 Level AA accessibility compliance.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `wcag-compliance-reviewer` | Review code for accessibility, WCAG compliance, or a11y issues |

```bash
claude --plugin-dir ./plugins/wcag-compliance-reviewer
# "Check this component for accessibility issues"
# "Is this page WCAG 2.2 compliant?"
```

[View Plugin Documentation](./plugins/wcag-compliance-reviewer/README.md)

---

### skill-reviewer `v1.4.0`

Reviews and plans Claude Code skills, and runs tests for changed files.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `reviewing-skills` | Audit or review a SKILL.md file for quality and best practices |
| `planning-skills` | Plan, design, or scaffold a new Claude Code skill |
| `running-tests` | Run tests for changed files, detect test framework, report results |

```bash
claude --plugin-dir ./plugins/skill-reviewer
# "Review this SKILL.md file"
# "Help me plan a new skill"
# "Run tests for the files I changed"
```

[View Plugin Documentation](./plugins/skill-reviewer/README.md)

---

### code-test-suggestion `v2.2.1`

Analyzes code and suggests specific, purpose-driven tests tied to actual behavior and intent.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `code-test-suggestion` | Suggest tests for code based on behavior and intent |
| `reviewing-tests` | Review existing tests for quality, coverage gaps, and alignment |

```bash
claude --plugin-dir ./plugins/code-test-suggestion
# "What tests should I write for this function?"
# "Review my test suite for gaps"
```

[View Plugin Documentation](./plugins/code-test-suggestion/README.md)

---

### git-agent `v1.0.0`

Automated git commit and PR creation — stage, commit with conventional messages, and create PRs in one shot.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `commit-agent` | Stage changes and create a conventional commit |
| `pr-agent` | Push branch and create a pull request |

```bash
claude --plugin-dir ./plugins/git-agent
# "Commit my changes"
# "Create a PR for this branch"
```

[View Plugin Documentation](./plugins/git-agent/README.md)

## Test Marketplace

The `.claude-plugin/marketplace.json` at the project root defines the `agentics-kit` marketplace, which references all example plugins. Register it once to make all plugins installable by name:

```bash
/plugin marketplace add /path/to/agentics
/plugin install code-review@agentics-kit
/plugin install plan-interview@agentics-kit
/plugin install claude-md-optimizer@agentics-kit
/plugin install wcag-compliance-reviewer@agentics-kit
/plugin install skill-reviewer@agentics-kit
/plugin install code-test-suggestion@agentics-kit
/plugin install git-agent@agentics-kit
```

## Development

### Plugin Development

Create new plugins in the `plugins/` directory:

```bash
# Create plugin structure
mkdir -p plugins/my-plugin/.claude-plugin
mkdir -p plugins/my-plugin/commands

# Create plugin manifest
cat > plugins/my-plugin/.claude-plugin/plugin.json <<EOF
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "My test plugin"
}
EOF

# Create a command
cat > plugins/my-plugin/commands/my-command.md <<EOF
---
description: My command description
---

# My Command

Instructions for Claude on what this command should do.
EOF
```

### Testing Plugins

Test plugins locally before adding to the marketplace:

```bash
# Test plugin directly (starts interactive session)
claude --plugin-dir ./plugins/my-plugin

# Once in the Claude session, invoke your command:
# /my-plugin:my-command

# Or provide a prompt directly:
claude --plugin-dir ./plugins/my-plugin "Run /my-plugin:my-command"
```

### Registering Plugins in Marketplace

Add your plugin to `.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    ...existing plugins,
    {
      "name": "my-plugin",
      "version": "1.0.0",
      "description": "My test plugin",
      "source": "./plugins/my-plugin",
      "category": "development",
      "tags": ["testing"]
    }
  ]
}
```

## Documentation

- [Plugin Directory](./plugins/README.md) — Plugin development guide and examples
- [Test Fixtures](./tests/fixtures/README.md) — Testing utilities and fixtures
- [Roadmap](./ROADMAP.md) — Planned features and API development
- [Changelog](./CHANGELOG.md) — Project-level change history
- [Security Policy](./SECURITY.md) — Vulnerability reporting
- [Contributing](./CONTRIBUTING.md) — How to contribute
- [Code of Conduct](./CODE_OF_CONDUCT.md) — Community standards

## Roadmap

### Current Features
- 7 example plugin implementations covering commands, skills, and agents
- Test marketplace configuration (`agentics-kit` v2.3.0)
- Plugin structure documentation and patterns
- Community infrastructure: contributing guide, code of conduct, security policy, issue templates

| Plugin | Version | Type |
|--------|---------|------|
| code-review | v2.1.1 | Skill |
| plan-interview | v1.3.0 | Command + Skill |
| claude-md-optimizer | v1.5.0 | Skill |
| wcag-compliance-reviewer | v1.1.0 | Skill |
| skill-reviewer | v1.4.0 | Skill (x3) |
| code-test-suggestion | v2.2.1 | Skill (x2) |
| git-agent | v1.0.0 | Skill (x2) |

### Planned Features

See [ROADMAP.md](./ROADMAP.md) for details on upcoming features including:
- Marketplace API implementation
- CLI for plugin installation
- Remote marketplace support
- Plugin search and filtering

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines on:
- Reporting bugs
- Proposing new plugins
- Plugin development workflow
- PR process and conventions

## Resources

- [Claude Code Documentation](https://code.claude.com/docs/en)
- [Create Plugins Guide](https://code.claude.com/docs/en/plugins)
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Discover Plugins](https://code.claude.com/docs/en/discover-plugins)
- [Plugin Development Best Practices](./plugins/README.md)

## License

MIT License

Copyright (c) 2026 Shawn Sandy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
