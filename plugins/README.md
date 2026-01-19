# Example Plugins

This directory contains example plugins for testing the agentics marketplace API. These plugins demonstrate the official Claude Code plugin structure and serve as reference implementations for plugin developers.

## Available Plugins

### hello-world
A minimal viable plugin demonstrating basic plugin structure. Perfect for understanding the fundamentals of Claude Code plugin development.

**Components:**
- Command: `/hello-world:greet` - Simple greeting command

**Use case:** Learning plugin basics, testing plugin loading

### dev-tools
A multi-component plugin showcasing commands and skills working together.

**Components:**
- Command: `/dev-tools:format` - Format code files
- Skill: `code-review` - Review code for issues

**Use case:** Understanding multi-component plugins, testing skills integration

## Testing Plugins Locally

### Using --plugin-dir

Test individual plugins directly with Claude Code:

```bash
# Test hello-world plugin
claude --plugin-dir ./plugins/hello-world

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

These plugins are referenced in `marketplace-data/.claude-plugin/marketplace.json` for marketplace API testing. The marketplace system:

1. **Discovers** plugins from marketplace.json
2. **Indexes** plugin metadata and components
3. **Serves** plugin information via API
4. **Enables** installation via CLI

See `marketplace-data/README.md` for marketplace setup instructions.

## Resources

- [Claude Code Plugin Documentation](https://github.com/anthropics/claude-code)
- [Plugin Development Guide](https://docs.anthropic.com/claude-code/plugins)
- [Marketplace API Documentation](../docs/api.md)

## Contributing

These are example plugins for testing. For production plugins:
- Use the plugin scaffolding tools (when available)
- Follow semantic versioning
- Include comprehensive tests
- Provide detailed documentation
- Consider security implications

## License

MIT License - See individual plugin directories for specific licenses.
