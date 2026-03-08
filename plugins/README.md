# Example Plugins

This directory contains example plugins for testing the agentics marketplace API. These plugins demonstrate the official Claude Code plugin structure and serve as reference implementations for plugin developers.

## Available Plugins

### hello-world
A minimal viable plugin demonstrating basic plugin structure. Perfect for understanding the fundamentals of Claude Code plugin development.

**Components:**
- Command: `/hello-world:greet [name]` - Simple greeting command

**Use case:** Learning plugin basics, testing plugin loading

### dev-tools
A commands-focused plugin for code formatting.

**Components:**
- Command: `/dev-tools:format [path]` - Format code files using the appropriate formatter

**Use case:** Understanding command plugins, formatter delegation

### code-review
A skill-only plugin that activates automatically when the user asks to review code.

**Components:**
- Skill: `code-review` - Review code across quality, bugs, security, and best practices

**Use case:** Understanding skill-only plugins, automatic activation patterns

### plan-interview
A plugin combining a command and a skill for the same underlying capability.

**Components:**
- Command: `/plan-interview:plan-interview [plan-file-path]` - Explicit plan interview invocation
- Skill: `plan-interview` - Auto-activates on stress-test/validate/interview requests

**Use case:** Understanding command + skill co-location for the same feature

### claude-md-optimizer
A skill-only plugin that audits and optimizes CLAUDE.md files.

**Components:**
- Skill: `claude-md-optimizer` - Audit CLAUDE.md files against best practices

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

### code-test-suggestion
A skill-only plugin that suggests targeted tests based on actual code behavior and intent.

**Components:**
- Skill: `code-test-suggestion` - Suggest specific, purpose-driven tests for code
- Skill: `reviewing-tests` - Review existing tests for quality and coverage gaps

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
   ls -la plugins/
   # Should show hello-world/ and dev-tools/ directories
   ```

### Using --plugin-dir

Test individual plugins directly with Claude Code:

```bash
# Option 1: From repository root (relative path)
claude --plugin-dir ./plugins/hello-world

# Option 2: From anywhere (absolute path)
claude --plugin-dir /full/path/to/agentics/plugins/hello-world

# In Claude, run:
# /hello-world:greet
# /hello-world:greet Alice
```

```bash
# Test dev-tools plugin
claude --plugin-dir ./plugins/dev-tools

# In Claude, run:
# /dev-tools:format
# Or ask: "Can you review this code for issues?" (skill activates)
```

### Loading Multiple Plugins

Load both plugins simultaneously:

```bash
claude --plugin-dir ./plugins/hello-world --plugin-dir ./plugins/dev-tools
```

### Troubleshooting

#### Plugin not found

**Error:** "Plugin directory does not exist" or similar

**Solutions:**
- Verify the path exists: `ls -la ./plugins/hello-world`
- Check you're in the repository root: `pwd`
- Use absolute path instead: `claude --plugin-dir /full/path/to/plugins/hello-world`
- Ensure `.claude-plugin/plugin.json` exists in the plugin directory

#### Command not recognized

**Error:** Command doesn't appear in `/help` or "Unknown command" message

**Solutions:**
- Verify the plugin loaded successfully (check Claude's startup output)
- Check command file exists: `ls -la plugins/hello-world/commands/`
- Ensure command file has `.md` extension
- Verify YAML frontmatter has `description` field
- Try restarting Claude with `--plugin-dir` flag

#### Skill not activating

**Error:** Natural language request doesn't trigger skill

**Solutions:**
- Check skill description matches your request intent
- Verify skill file location: `plugins/plugin-name/skills/skill-name/SKILL.md`
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
  "version": "1.0.0",
  "description": "Brief description of what the plugin does",
  "author": {
    "name": "Author Name",
    "email": "author@example.com"
  },
  "license": "MIT",
  "category": "development"
}
```

**Required fields:**
- `name` - Plugin identifier (lowercase, hyphens only)
- `version` - Semantic version (e.g., "1.0.0")
- `description` - Brief description of functionality

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
