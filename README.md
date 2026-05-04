# agentics

A marketplace system for Claude Code plugins, enabling discovery, distribution, and installation of plugins that extend Claude's capabilities.

## Quick Start

**Install from GitHub (recommended):**

```bash
# Register the agentics-kit marketplace
/plugin marketplace add shawn-sandy/agentics

# Install any plugin by name
/plugin install code-review@agentics-kit
/plugin install git-agent@agentics-kit
```

**Or load a plugin directly for local testing:**

```bash
git clone https://github.com/shawn-sandy/agentics.git
cd agentics
claude --plugin-dir ./kit/plugins/code-review
# Then ask: "Review this code for issues"
```

## Overview

The agentics project provides:

- **Example Plugins** — 12 reference implementations demonstrating Claude Code plugin structure
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
├── .claude-plugin/
│   └── marketplace.json              # Marketplace manifest (agentics-kit)
├── .claude/
│   └── rules/                        # Scoped authoring rules (plugin patterns, marketplace, testing)
├── kit/
│   └── plugins/                      # Plugin source code (12 plugins)
│       ├── agent-creator/            # Agent-based plugin scaffolding
│       ├── agentic-plugin-dev/       # Plugin creation and management
│       ├── memory-tools/             # CLAUDE.md / project memory audit and optimization
│       ├── code-review/              # Code review skill
│       ├── code-simplifier/          # Code smell analysis and refactoring
│       ├── code-testing-agent/       # Test suggestion and review
│       ├── git-agent/                # Git workflow automation (commit, PR, ship)
│       ├── marketplace-builder/      # Marketplace scaffolding
│       ├── plan-interview/           # Plan stress-test (commands + skills)
│       ├── react-perf-analyzer/      # React performance analysis
│       ├── skill-reviewer/           # Skill authoring review and testing
│       └── wcag-compliance-reviewer/ # WCAG 2.2 accessibility compliance
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

### Component Types

Plugins can include four types of components:

| Type | Invocation | File Location | Use When |
|------|-----------|---------------|----------|
| **Commands** | Explicit: `/plugin:command` | `commands/name.md` | User should control when to run it |
| **Skills** | Automatic: matches user intent | `skills/name/SKILL.md` | Claude should detect the need from conversation |
| **Agents** | Delegated: spawned as subprocesses | `agents/name.md` | Work should run in the background without blocking |
| **Hooks** | Event-driven: triggered by lifecycle events | Configured in `settings.json` | Actions should happen automatically on specific events |

Most plugins use skills (automatic activation). Commands are for actions that need explicit user control. Agents and hooks are for advanced workflows like background git operations or pre-commit validation.

## Plugins

### code-review `v3.2.0`

Structured multi-dimensional code review across quality, bugs, security, best practices, complexity rating, breaking changes, and regressions.

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

### plan-interview `v1.14.5`

Stress-tests implementation plans with structured multi-round interviews before coding begins.

**Commands:**

| Command | Description |
|---------|-------------|
| `/plan-interview:plan-interview [plan-file-path]` | Run a structured interview against a plan file |
| `/plan-interview:deep-grill [plan-file-path]` | Walk through each decision branch and stress-test individual decisions |
| `/plan-interview:plan-status [plan-file-path]` | Check, update, or determine the implementation status of a plan |
| `/plan-interview:update-plan-status [plan-file-path]` | Update a plan's status metadata |
| `/plan-interview:plan-hygiene` | Pre-commit check for randomly-named plan files that need renaming |
| `/plan-interview:review-rename-plans` | Review and rename plan files with non-descriptive names |
| `/plan-interview:documenting-plans [plan-file-path]` | Generate prose docs from completed plan files |

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `plan-interview` | Stress-test, validate, interview, or find gaps in a plan |
| `deep-grill` | Deep grill a plan, examine design-tree branches, or stress-test individual decisions |
| `plan-status` | Check or determine the implementation status of a plan file |
| `documenting-plans` | Document a plan, turn a plan into docs, or create a reference doc from a plan |

```bash
claude --plugin-dir ./kit/plugins/plan-interview
# /plan-interview:plan-interview docs/plans/my-plan.md
# /plan-interview:deep-grill docs/plans/my-plan.md
# "Stress-test this plan"
# "What's the status of this plan?"
```

[View Plugin Documentation](./kit/plugins/plan-interview/README.md)

---

### memory-tools `v2.0.0`

Audits and optimizes CLAUDE.md project memory files against Claude Code best practices.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `memory-doctor` | Optimize, audit, clean up, or diagnose a CLAUDE.md / project memory file — also activates when Claude is ignoring instructions |
| `path-rules-advisor` | Create path-specific rules, organize rules by file type or directory, or check if the project needs scoped rules in `.claude/rules/` |

```bash
claude --plugin-dir ./kit/plugins/memory-tools
# "Audit my CLAUDE.md file"
# "My Claude is ignoring my instructions — what's wrong?"
# "Diagnose my project memory"
# "Create path-specific rules for my src/ directory"
```

[View Plugin Documentation](./kit/plugins/memory-tools/README.md)

---

### wcag-compliance-reviewer `v1.2.0`

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

### skill-reviewer `v1.6.0`

Reviews and plans Claude Code skills, runs tests for changed files, and audits skill permissions.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `reviewing-skills` | Audit or review a SKILL.md file for quality and best practices |
| `planning-skills` | Plan, design, or scaffold a new Claude Code skill |
| `auditing-allowed-tools` | Audit, recommend, or fix the `allowed-tools` frontmatter for a SKILL.md, or review which tools Claude used during a session |
| `running-tests` | Run tests for changed files, detect test framework, report results |

```bash
claude --plugin-dir ./kit/plugins/skill-reviewer
# "Review this SKILL.md file"
# "Help me plan a new skill"
# "What allowed-tools should this skill have?"
# "Run tests for the files I changed"
```

[View Plugin Documentation](./kit/plugins/skill-reviewer/README.md)

---

### code-testing-agent `v3.2.0`

Analyzes code and suggests specific, purpose-driven tests tied to actual behavior and intent — not arbitrary coverage.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `code-testing-agent` | Suggest tests for code based on behavior and intent |
| `reviewing-tests` | Review existing tests for quality, coverage gaps, and alignment |
| `tdd-fix` | Reproduce a bug with a failing test, then fix it in an autonomous red-green cycle |
| `running-tests` | Run tests, detect framework, and report results |

```bash
claude --plugin-dir ./kit/plugins/code-testing-agent
# "What tests should I write for this function?"
# "Review my test suite for gaps"
# "TDD fix this bug — write a failing test then make it green"
```

[View Plugin Documentation](./kit/plugins/code-testing-agent/README.md)

---

### git-agent `v3.6.0`

Automated git workflow — create branches, commit with conventional messages, and create PRs (with background subagents and slash commands for fire-and-forget commit, PR, and ship).

**Commands:**

| Command | Description |
|---------|-------------|
| `/git-agent:commit-bg` | Fire-and-forget background commit |
| `/git-agent:pr-bg` | Fire-and-forget background PR creation |
| `/git-agent:ship-bg` | Fire-and-forget background commit + push + PR |

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `branch-agent` | Create a new branch, start a branch, or branch off main |
| `commit-agent` | Stage changes and create a conventional commit |
| `pr-agent` | Create a PR, push and open a pull request, or submit a branch for review |
| `ship` | Commit, push, and open a pull request in one flow |

**Agents** (background subprocesses):

| Agent | Purpose |
|-------|---------|
| `agent-commit` | Background git commit without blocking the session |
| `agent-pr` | Background PR creation without blocking the session |
| `agent-ship` | Background end-to-end commit + push + PR flow |

```bash
claude --plugin-dir ./kit/plugins/git-agent
# "Commit my changes"
# "Create a branch for this feature"
# "Open a PR for this branch"
# "Ship it"
# /git-agent:commit-bg
```

[View Plugin Documentation](./kit/plugins/git-agent/README.md)

---

### agent-creator `v1.1.0`

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

### react-perf-analyzer `v1.2.0`

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

### marketplace-builder `v1.1.0`

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

### agentic-plugin-dev `v1.1.0`

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

### code-simplifier `v1.0.0`

Analyze code for structural quality issues, code smells, and optimization opportunities — dead code, complexity, god classes, duplication, coupling, and performance anti-patterns.

**Skills** (activate automatically based on your request):

| Skill | Activates when you ask to... |
|-------|------------------------------|
| `code-simplifier` | Simplify code, find code smells, reduce complexity, identify refactoring opportunities, check for dead code, or optimize structure |

```bash
claude --plugin-dir ./kit/plugins/code-simplifier
# "Find code smells in this file"
# "Simplify this function"
# "Check for dead code"
```

[View Plugin Documentation](./kit/plugins/code-simplifier/README.md)

---

## Marketplace

The `agentics-kit` marketplace is defined in `kit/.claude-plugin/marketplace.json`. Each plugin is sourced via `git-subdir`, enabling sparse cloning of individual plugins without fetching the full repository.

Register the marketplace and install plugins by name:

```bash
/plugin marketplace add shawn-sandy/agentics
/plugin install code-review@agentics-kit
/plugin install plan-interview@agentics-kit
/plugin install memory-tools@agentics-kit
/plugin install wcag-compliance-reviewer@agentics-kit
/plugin install skill-reviewer@agentics-kit
/plugin install code-testing-agent@agentics-kit
/plugin install git-agent@agentics-kit
/plugin install agent-creator@agentics-kit
/plugin install react-perf-analyzer@agentics-kit
/plugin install marketplace-builder@agentics-kit
/plugin install agentic-plugin-dev@agentics-kit
/plugin install code-simplifier@agentics-kit
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

- 12 example plugin implementations covering commands, skills, and agents
- `agentics-kit` marketplace v3.0.0 with `git-subdir` sources for sparse cloning
- Plugin structure documentation and patterns
- Community infrastructure: contributing guide, code of conduct, security policy, issue templates

| Plugin | Version | Components |
|--------|---------|------------|
| code-review | v3.2.0 | 1 skill, 1 agent |
| plan-interview | v1.14.5 | 7 commands, 4 skills |
| memory-tools | v2.0.0 | 2 skills |
| wcag-compliance-reviewer | v1.2.0 | 1 skill |
| skill-reviewer | v1.6.0 | 4 skills |
| code-testing-agent | v3.2.0 | 4 skills |
| git-agent | v3.6.0 | 3 commands, 4 skills, 3 agents |
| agent-creator | v1.1.0 | 1 skill |
| react-perf-analyzer | v1.2.0 | 1 command, 1 skill |
| marketplace-builder | v1.1.0 | 1 skill |
| agentic-plugin-dev | v1.1.0 | 3 skills |
| code-simplifier | v1.0.0 | 1 skill |

### Planned Features

See [ROADMAP.md](./ROADMAP.md) for details on upcoming features including:
- Marketplace API implementation
- CLI for plugin installation
- Remote marketplace support
- Plugin search and filtering

## CI/CD Integration

This repository uses two GitHub Actions workflows powered by [Claude Code Action](https://github.com/anthropics/claude-code-action):

- **Claude Code** (`claude.yml`) — Responds to `@claude` mentions in issue comments, PR review comments, and issues. Use it to ask Claude for help directly in GitHub.
- **Claude Code Review** (`claude-code-review.yml`) — Automatically reviews all pull requests when opened, synchronized, or reopened. Provides code review feedback as PR comments.

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

