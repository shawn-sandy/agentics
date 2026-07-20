# Example Plugins

This directory contains example plugins for testing the agentics marketplace API. These plugins demonstrate the official Claude Code plugin structure and serve as reference implementations for plugin developers.

## Available Plugins

### code-review
A skill-only plugin that activates automatically when the user asks to review code.

**Components:**
- Skill: `code-review` - Review code across quality, bugs, security, and best practices

**Use case:** Understanding skill-only plugins, automatic activation patterns

### plan-agent
A plugin combining commands and skills for the same underlying capabilities (plan creation, review, documentation, and maintenance). Absorbed the former `plan-interview` plugin in v4.0.0.

**Components:**
- Command: `/plan-agent:deep-grill [plan-file-path]` - Walk each plan decision branch node-by-node
- Skill: `plan-status` - Auto-activates on check/update plan-status requests (single file or `--all` bulk)

**Use case:** Understanding command + skill co-location for the same feature

### memory-tools
A skill-only plugin that audits and optimizes CLAUDE.md project memory files.

**Components:**
- Skill: `agentic-memory-management` - Audit CLAUDE.md / project memory files against best practices
- Skill: `path-rules-advisor` - Create path-specific rule files in `.claude/rules/`

**Use case:** Understanding skills with broad activation criteria and multi-step output

### wcag-compliance-reviewer
A skill-only plugin that reviews code for WCAG 2.2 Level AA accessibility compliance.

**Components:**
- Skill: `wcag-compliance-reviewer` - Review HTML/CSS and React/TypeScript code for WCAG 2.2 compliance

**Use case:** Accessibility auditing, compliance checking

### skill-reviewer
A multi-skill plugin for reviewing, planning, and testing Claude Code skills.

**Components:**
- Skill: `reviewing-skills` - Audit SKILL.md files across 5 dimensions with scoring
- Skill: `planning-skills` - Guide workflow for designing and scaffolding new skills
- Skill: `running-tests` - Detect changed files, find related tests, run them, report results

**Use case:** Plugin authoring quality assurance, skill development workflow

### code-testing-agent
A multi-skill plugin that analyzes code and suggests targeted tests, reviews existing tests, and runs changed test files.

**Components:**
- Skill: `code-testing-agent` - Suggest specific, purpose-driven tests tied to actual code behavior
- Skill: `reviewing-tests` - Review existing tests for quality and coverage gaps
- Skill: `running-tests` - Detect changed files, find related tests, run them, report results

**Use case:** Test-driven development, test quality improvement

### git-agent
A skill-only plugin for automated git commit and PR creation.

**Components:**
- Skill: `commit-agent` - Stage changes and create conventional commits
- Skill: `pr-agent` - Push branch and create pull requests via `gh`

**Use case:** Streamlined git workflows, automated PR creation

## Testing Plugins Locally

### Prerequisites Check

Before testing plugins, verify your setup:

1. **Verify Claude Code CLI is installed:**
   ```bash
   claude --version
   # Should output version 1.0.0 or later
   ```

2. **Verify working directory:**
   ```bash
   pwd
   # Should show the agentics repository root
   # Expected: /path/to/agentics
   ```

3. **List available plugins:**
   ```bash
   ls -la kit/plugins/
   # Should show code-review/, plan-agent/, git-agent/, etc.
   ```

### Using --plugin-dir

Test individual plugins directly with Claude Code:

```bash
# Option 1: From repository root (relative path)
claude --plugin-dir ./kit/plugins/code-review

# Option 2: From anywhere (absolute path)
claude --plugin-dir /full/path/to/agentics/kit/plugins/code-review

# In Claude, ask naturally (skill activates automatically):
# "Review this code for issues"
```

```bash
# Test plan-agent plugin (has both commands and skills)
claude --plugin-dir ./kit/plugins/plan-agent

# Invoke the command explicitly:
# /plan-agent:deep-grill docs/plans/my-plan.md
# Or ask: "Stress-test this plan before I start coding" (skill activates)
```

### Loading Multiple Plugins

Load multiple plugins simultaneously:

```bash
claude --plugin-dir ./kit/plugins/code-review --plugin-dir ./kit/plugins/plan-agent
```

### Troubleshooting

#### Plugin not found

**Error:** "Plugin directory does not exist" or similar

**Solutions:**
- Verify the path exists: `ls -la ./kit/plugins/code-review`
- Check you're in the repository root: `pwd`
- Use absolute path instead: `claude --plugin-dir /full/path/to/agentics/kit/plugins/code-review`
- Ensure `.claude-plugin/plugin.json` exists in the plugin directory

#### Command not recognized

**Error:** Command doesn't appear in `/help` or "Unknown command" message

**Solutions:**
- Verify the plugin loaded successfully (check Claude's startup output)
- Check command file exists: `ls -la kit/plugins/plan-agent/commands/`
- Ensure command file has `.md` extension
- Verify YAML frontmatter has `description` field
- Try restarting Claude with `--plugin-dir` flag

#### Skill not activating

**Error:** Natural language request doesn't trigger skill

**Solutions:**
- Check skill description matches your request intent
- Verify skill file location: `kit/plugins/plugin-name/skills/skill-name/SKILL.md`
- Ensure YAML frontmatter has both `name` and `description` fields
- Try being more explicit in your request
- Use the exact phrasing from skill description for testing

## Plugin Structure

Each plugin follows the official Claude Code plugin structure:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest (required)
├── commands/                # Slash commands (optional)
│   └── command-name.md
├── skills/                  # Auto-invoked skills (optional)
│   └── skill-name/
│       └── SKILL.md
├── agents/                  # Subagents (optional)
│   └── agent-name/
│       └── AGENT.md
└── README.md               # Plugin documentation
```

## Plugin Manifest (plugin.json)

Every plugin requires a `.claude-plugin/plugin.json` file:

```json
{
  "name": "plugin-name",
  "description": "Brief description of what the plugin does",
  "author": {
    "name": "Author Name"
  },
  "license": "MIT",
  "homepage": "https://github.com/owner/repo/tree/main/kit/plugins/plugin-name",
  "repository": "https://github.com/owner/repo"
}
```

**Required fields:**
- `name` - Plugin identifier (lowercase, hyphens only)
- `description` - Brief description of functionality

**Note:** Do not set `version` in `plugin.json` — version is managed exclusively in `marketplace.json`.

**Optional fields:**
- `author` - Author information (name, email, url)
- `license` - License identifier (MIT, Apache-2.0, etc.)
- `category` - Plugin category (development, productivity, learning, etc.)
- `repository` - Git repository URL
- `homepage` - Plugin homepage URL

## Creating Commands

Commands are markdown files in the `commands/` directory with YAML frontmatter:

```markdown
---
description: Brief description shown in command list
---

# Command Instructions

Write clear instructions for Claude on what this command should do.

Access user arguments with $ARGUMENTS.
Access the current directory with $PWD.
```

**Naming conventions:**
- Filename becomes command name: `greet.md` → `/plugin:greet`
- Use lowercase, hyphens for multi-word commands
- Keep names concise and descriptive

## Creating Skills

Skills are markdown files in `skills/skill-name/SKILL.md`:

```markdown
---
name: skill-name
description: When to invoke this skill. Use when the user asks...
---

# Skill Instructions

Provide detailed instructions on how to execute this skill.
Skills are invoked automatically when their description matches user intent.
```

**Best practices:**
- Clear activation criteria in description
- Progressive disclosure: start simple, add detail as needed
- Include examples and edge cases

## Plugin Development Guidelines

### Keep It Simple
- Start with one component (command or skill)
- Add complexity only when needed
- Prefer clarity over cleverness

### Follow Conventions
- Use official plugin structure
- Match existing naming patterns
- Include helpful error messages

### Document Well
- Clear README with usage examples
- Descriptive command/skill frontmatter
- Comment complex logic

### Test Thoroughly
- Test commands with various arguments
- Verify skills activate correctly
- Check error handling

## Integration with Marketplace

These plugins are referenced in `.claude-plugin/marketplace.json` for marketplace API testing. The marketplace system:

1. **Discovers** plugins from marketplace.json via `source` path references
2. **Indexes** plugin metadata and components
3. **Serves** plugin information via API
4. **Enables** installation via CLI

See the [root README](../README.md) for marketplace registration and usage.

## Resources

- [Claude Code Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)

## Contributing

These are example plugins for testing. For production plugins:
- Use the plugin scaffolding tools (when available)
- Follow semantic versioning
- Include comprehensive tests
- Provide detailed documentation
- Consider security implications

## License

MIT License - See individual plugin directories for specific licenses.
