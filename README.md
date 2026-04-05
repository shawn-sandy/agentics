# agentics

A marketplace system for Claude Code plugins, enabling discovery, distribution, and installation of plugins that extend Claude's capabilities.

## Quick Start

```bash
git clone https://github.com/shawn-sandy/agentics.git
cd agentics
claude --plugin-dir ./kit/plugins/code-review
# Then ask: "Review this code for issues"
```

## Overview

The agentics project provides:

- **Example Plugins** — 11 reference implementations demonstrating Claude Code plugin structure
- **Test Marketplace** — `agentics-kit` marketplace for testing plugin discovery and installation
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
├── kit/
│   ├── .claude-plugin/
│   │   └── marketplace.json          # Marketplace manifest (agentics-kit)
│   └── plugins/                      # Example plugins
│       ├── code-review/              # Code review skill
│       ├── plan-interview/           # Plan stress-test (command + skill)
│       ├── claude-md-optimizer/      # CLAUDE.md audit and optimization
│       ├── wcag-compliance-reviewer/ # WCAG 2.2 accessibility compliance
│       ├── skill-reviewer/           # Skill authoring review and testing
│       ├── code-testing-agent/       # Test suggestion and review
│       ├── git-agent/                # Automated git commit and PR creation
│       ├── agent-creator/            # Agent-based plugin scaffolding
│       ├── react-perf-analyzer/      # React performance analysis
│       ├── marketplace-builder/      # Marketplace scaffolding
│       └── agentic-plugin-dev/       # Plugin creation and management
├── tests/
│   └── fixtures/                     # Test plugin fixtures
└── README.md                         # This file
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
   claude --plugin-dir ./kit/plugins/code-review

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
- Verify the path exists: `ls -la ./kit/plugins/code-review`
- Use absolute paths if relative paths aren't working:
  ```bash
  claude --plugin-dir /full/path/to/agentics/kit/plugins/code-review
  ```
- Check that `.claude-plugin/plugin.json` exists in the plugin directory

#### Permission errors

The plugin directory or files may not be readable.

**Solution:**
- Check file permissions: `ls -la ./kit/plugins/code-review`
- Make directory readable: `chmod -R +r ./kit/plugins/code-review`
- Ensure you own the files: `chown -R $USER:$USER ./kit/plugins/`

#### "Input must be provided" error with --plugin-dir

You see an error like: `Error: Input must be provided either through stdin or as a prompt argument when using --print`

**Solution:**
- This error can occur if Claude Code can't start the interactive session properly
- Try providing a prompt directly:
  ```bash
  claude --plugin-dir ./kit/plugins/code-review "List available commands"
  ```
- Or pipe a command:
  ```bash
  echo "Review this code for issues" | claude --plugin-dir ./kit/plugins/code-review
  ```
- Verify your Claude Code version supports plugins: `claude --version` (need 1.0.33+)
- Check plugin.json is valid JSON: `cat kit/plugins/code-review/.claude-plugin/plugin.json | jq`

## Usage Guide

### Single Plugin Testing

Test individual plugins by loading them directly:

```bash
# Test code-review plugin (starts interactive session)
claude --plugin-dir ./kit/plugins/code-review

# Once in the Claude session, ask naturally:
# "Review this code for issues"

# Or provide a prompt directly:
claude --plugin-dir ./kit/plugins/code-review "Review this file for bugs"
```

### Multiple Plugin Testing

Load multiple plugins simultaneously by specifying multiple `--plugin-dir` flags:

```bash
# Load multiple plugins at once (starts interactive session)
claude --plugin-dir ./kit/plugins/code-review --plugin-dir ./kit/plugins/plan-interview

# Once in the Claude session, you can use commands from both plugins:
# "Review this code for issues"
# /plan-interview:plan-interview docs/plans/my-plan.md

# Or provide a prompt directly:
claude --plugin-dir ./kit/plugins/code-review --plugin-dir ./kit/plugins/plan-interview "Review my code"
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

### code-review `v3.1.0`

Systematic code review across quality, bugs, security vulnerabilities, breaking changes, and regressions with complexity rating.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `code-review-agent` | Review code, check for bugs, analyze code quality, look for security issues, or detect breaking changes |

```bash
claude --plugin-dir ./kit/plugins/code-review
# "Review this function for bugs"
# "Check this file for security issues"
```

[View Plugin Documentation](./kit/plugins/code-review/README.md)

---

### plan-interview `v1.12.0`

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
claude --plugin-dir ./kit/plugins/plan-interview
# /plan-interview:plan-interview
# "Stress-test this plan"
```

[View Plugin Documentation](./kit/plugins/plan-interview/README.md)

---

### claude-md-optimizer `v1.5.0`

Audits and optimizes CLAUDE.md files against Claude Code best practices.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `claude-md-optimizer` | Optimize, audit, or clean up a CLAUDE.md file — also activates when Claude is ignoring instructions |

```bash
claude --plugin-dir ./kit/plugins/claude-md-optimizer
# "Audit my CLAUDE.md file"
# "My Claude is ignoring my instructions — what's wrong?"
```

[View Plugin Documentation](./kit/plugins/claude-md-optimizer/README.md)

---

### wcag-compliance-reviewer `v1.1.0`

Reviews HTML/CSS and React/TypeScript code for WCAG 2.2 Level AA accessibility compliance.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `wcag-compliance-reviewer` | Review code for accessibility, WCAG compliance, or a11y issues |

```bash
claude --plugin-dir ./kit/plugins/wcag-compliance-reviewer
# "Check this component for accessibility issues"
# "Is this page WCAG 2.2 compliant?"
```

[View Plugin Documentation](./kit/plugins/wcag-compliance-reviewer/README.md)

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
claude --plugin-dir ./kit/plugins/skill-reviewer
# "Review this SKILL.md file"
# "Help me plan a new skill"
# "Run tests for the files I changed"
```

[View Plugin Documentation](./kit/plugins/skill-reviewer/README.md)

---

### code-testing-agent `v3.0.0`

Analyzes code and suggests specific, purpose-driven tests tied to actual behavior and intent.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `code-testing-agent` | Suggest tests for code based on behavior and intent |
| `reviewing-tests` | Review existing tests for quality, coverage gaps, and alignment |
| `running-tests` | Run tests, detect framework, and report results |

```bash
claude --plugin-dir ./kit/plugins/code-testing-agent
# "What tests should I write for this function?"
# "Review my test suite for gaps"
```

[View Plugin Documentation](./kit/plugins/code-testing-agent/README.md)

---

### git-agent `v1.1.0`

Automated git commit and PR creation — stage, commit with conventional messages, and create PRs in one shot.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `commit-agent` | Stage changes and create a conventional commit |
| `ship` | Commit, push, and open a pull request in one flow |

```bash
claude --plugin-dir ./kit/plugins/git-agent
# "Commit my changes"
# "Ship it"
```

[View Plugin Documentation](./kit/plugins/git-agent/README.md)

---

### agent-creator `v1.0.0`

Scaffolds Claude Code agent-based plugins with guided workflows.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `generating-agents` | Create, scaffold, or generate a new agent-based plugin |

```bash
claude --plugin-dir ./kit/plugins/agent-creator
# "Create a new agent plugin called my-agent"
```

[View Plugin Documentation](./kit/plugins/agent-creator/README.md)

---

### react-perf-analyzer `v1.1.0`

Identifies React component source patterns that commonly correlate with poor INP, CLS, Long Animation Frames, and Long Tasks scores.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `react-perf-analyzer` | Analyze React components for performance issues or web vitals problems |

```bash
claude --plugin-dir ./kit/plugins/react-perf-analyzer
# "Analyze this component for performance issues"
```

[View Plugin Documentation](./kit/plugins/react-perf-analyzer/README.md)

---

### marketplace-builder `v1.0.0`

Evaluates a repository and scaffolds Claude Code marketplace infrastructure.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `building-marketplaces` | Scaffold, audit, or set up a Claude Code plugin marketplace |

```bash
claude --plugin-dir ./kit/plugins/marketplace-builder
# "Help me set up a plugin marketplace for this repo"
```

[View Plugin Documentation](./kit/plugins/marketplace-builder/README.md)

---

### agentic-plugin-dev `v1.0.0`

Create, manage, and validate Claude Code plugins — scaffold new plugins, manage marketplace entries, and audit plugin structure.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `plugin-creator` | Create or scaffold a new Claude Code plugin |
| `plugin-manager` | Add, update, or remove a plugin from marketplace.json |
| `plugin-validator` | Validate a plugin's structure and manifest |

```bash
claude --plugin-dir ./kit/plugins/agentic-plugin-dev
# "Create a new plugin called my-plugin"
# "Validate the structure of this plugin"
```

[View Plugin Documentation](./kit/plugins/agentic-plugin-dev/README.md)

## Marketplace

The `agentics-kit` marketplace is defined in `kit/.claude-plugin/marketplace.json`. Each plugin is sourced via `git-subdir`, enabling sparse cloning of individual plugins without fetching the full repository.

Register the marketplace and install plugins by name:

```bash
/plugin marketplace add shawn-sandy/agentics --sparse kit
/plugin install code-review@agentics-kit
/plugin install plan-interview@agentics-kit
/plugin install claude-md-optimizer@agentics-kit
/plugin install wcag-compliance-reviewer@agentics-kit
/plugin install skill-reviewer@agentics-kit
/plugin install code-testing-agent@agentics-kit
/plugin install git-agent@agentics-kit
/plugin install agent-creator@agentics-kit
/plugin install react-perf-analyzer@agentics-kit
/plugin install marketplace-builder@agentics-kit
/plugin install agentic-plugin-dev@agentics-kit
```

## Development

### Plugin Development

Create new plugins in the `kit/plugins/` directory:

```bash
# Create plugin structure
mkdir -p kit/plugins/my-plugin/.claude-plugin
mkdir -p kit/plugins/my-plugin/skills/my-skill

# Create plugin manifest (no version — version goes in marketplace.json only)
cat > kit/plugins/my-plugin/.claude-plugin/plugin.json <<EOF
{
  "name": "my-plugin",
  "description": "My test plugin"
}
EOF
```

### Testing Plugins

Test plugins locally before adding to the marketplace:

```bash
# Test plugin directly (starts interactive session)
claude --plugin-dir ./kit/plugins/my-plugin

# Once in the Claude session, invoke your command:
# /my-plugin:my-command

# Or provide a prompt directly:
claude --plugin-dir ./kit/plugins/my-plugin "Run /my-plugin:my-command"
```

### Registering Plugins in Marketplace

Add your plugin to `kit/.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    {
      "name": "my-plugin",
      "source": {
        "source": "git-subdir",
        "url": "shawn-sandy/agentics",
        "path": "kit/plugins/my-plugin"
      },
      "version": "1.0.0",
      "description": "My test plugin",
      "category": "development",
      "tags": ["testing"]
    }
  ]
}
```

## Documentation

- [Plugin Directory](./kit/plugins/README.md) — Plugin development guide and examples
- [Test Fixtures](./tests/fixtures/README.md) — Testing utilities and fixtures
- [Roadmap](./ROADMAP.md) — Planned features and API development
- [Changelog](./CHANGELOG.md) — Project-level change history
- [Security Policy](./SECURITY.md) — Vulnerability reporting
- [Contributing](./CONTRIBUTING.md) — How to contribute
- [Code of Conduct](./CODE_OF_CONDUCT.md) — Community standards

## Roadmap

### Current Features

- 11 example plugin implementations covering commands, skills, and agents
- `agentics-kit` marketplace v3.0.0 with `git-subdir` sources for sparse cloning
- Plugin structure documentation and patterns
- Community infrastructure: contributing guide, code of conduct, security policy, issue templates

| Plugin | Version | Type |
|--------|---------|------|
| code-review | v3.1.0 | Skill |
| plan-interview | v1.12.0 | Command + Skill |
| claude-md-optimizer | v1.5.0 | Skill |
| wcag-compliance-reviewer | v1.1.0 | Skill |
| skill-reviewer | v1.4.0 | Skill (x3) |
| code-testing-agent | v3.0.0 | Skill (x3) |
| git-agent | v1.1.0 | Skill (x2) |
| agent-creator | v1.0.0 | Skill |
| react-perf-analyzer | v1.1.0 | Skill |
| marketplace-builder | v1.0.0 | Skill |
| agentic-plugin-dev | v1.0.0 | Skill (x3) |

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
- [Plugin Development Best Practices](./kit/plugins/README.md)

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
