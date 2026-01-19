# hello-world Plugin

A minimal example plugin demonstrating the basic structure of Claude Code plugins. This plugin serves as a reference implementation for the agentics marketplace testing suite.

## Overview

The hello-world plugin is intentionally simple, containing only the essential components needed for a functioning Claude Code plugin. It's designed to help developers understand plugin structure and test marketplace functionality.

## Features

- **Single Command**: `/hello-world:greet` - A simple greeting command
- **Argument Handling**: Demonstrates how to use `$ARGUMENTS` in commands
- **Clear Structure**: Shows minimal viable plugin organization

## Installation

### Local Testing

Load the plugin directly from the file system:

```bash
claude --plugin-dir ./plugins/hello-world
```

### Via Marketplace (when available)

```bash
agentics install hello-world
```

## Usage

### Basic Greeting

```
/hello-world:greet
```

Outputs a friendly greeting and introduction.

### Personalized Greeting

```
/hello-world:greet Alice
```

Greets the user by name.

## Plugin Structure

```
hello-world/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/
│   └── greet.md             # Greeting command
└── README.md                # This file
```

## Components

### Command: greet

**File:** `commands/greet.md`
**Invocation:** `/hello-world:greet [name]`

Greets the user and introduces the plugin. Accepts an optional name argument for personalization.

**Examples:**
- `/hello-world:greet` - General greeting
- `/hello-world:greet Bob` - Personalized greeting for Bob

## Development

This plugin demonstrates:

1. **Plugin Manifest** - Minimal required fields in `plugin.json`
2. **Command Structure** - YAML frontmatter + markdown instructions
3. **Argument Usage** - Accessing user input via `$ARGUMENTS`
4. **Documentation** - Clear README and command descriptions

## Testing

### Manual Testing

1. Load the plugin:
   ```bash
   claude --plugin-dir ./plugins/hello-world
   ```

2. Test the command:
   ```
   /hello-world:greet
   /hello-world:greet TestUser
   ```

3. Verify:
   - Command appears in available commands list
   - Greeting is friendly and informative
   - Arguments are handled correctly

### Expected Behavior

- Command should execute without errors
- Output should mention the plugin's role as a test example
- Name argument (if provided) should be incorporated naturally

## Troubleshooting

### "Unknown skill: hello-world:greet" Error

**Cause:** This misleading error occurs when the plugin isn't loaded or the command syntax is incorrect.

**Note:** The `greet` component is a **command**, not a skill. Commands require explicit invocation.

**Solutions:**
1. Ensure the plugin is loaded first:
   ```bash
   claude --plugin-dir ./plugins/hello-world
   ```

2. Verify correct syntax with colon:
   ```
   /hello-world:greet
   ```
   (NOT `/hello world greet` or `hello-world:greet` without the slash)

3. Check if the plugin is listed in available commands (use `/help`)

### Plugin Not Loading

**Symptom:** Error messages when trying to load the plugin

**Common Causes:**
- Incorrect working directory (must be project root)
- Invalid file paths
- Missing or corrupted `plugin.json`

**Solutions:**
1. Verify you're in the correct directory:
   ```bash
   pwd  # Should show project root
   ls plugins/hello-world  # Should list plugin files
   ```

2. Check plugin manifest exists and is valid:
   ```bash
   cat plugins/hello-world/.claude-plugin/plugin.json
   ```

3. Verify file permissions:
   ```bash
   ls -la plugins/hello-world/.claude-plugin/
   ```

### Command Not Found

**Symptom:** "Command not found" when invoking `/hello-world:greet`

**Solutions:**
1. Verify the plugin loaded successfully (no errors during load)
2. Check the command file exists: `plugins/hello-world/commands/greet.md`
3. Restart Claude Code session to reload the plugin
4. Check for typos in command name (case-sensitive)

### No Response or Generic Response

**Symptom:** Command executes but doesn't produce the expected greeting

**Solutions:**
1. Verify the command file has proper YAML frontmatter
2. Check that `$ARGUMENTS` is referenced in the command instructions
3. Review `commands/greet.md` for syntax errors
4. Exit and reload the plugin (changes require session restart)

### Claude Code Version Issues

**Symptom:** Plugin works in one environment but not another

**Solutions:**
1. Check Claude Code CLI version: `claude --version`
2. Ensure you're using a recent version that supports plugins
3. Verify the plugin manifest uses compatible features
4. Check Claude Code documentation for version-specific plugin requirements

### Quick Test Script Not Working

**Symptom:** `./plugins/hello-world/test.sh` fails or shows errors

**Solutions:**
1. Ensure script is executable:
   ```bash
   chmod +x plugins/hello-world/test.sh
   ```

2. Run from project root:
   ```bash
   cd /Users/shawnsandy/devbox/agentics
   ./plugins/hello-world/test.sh
   ```

3. Check bash is available: `which bash`

### For More Help

- **Detailed Testing Guide:** See `TESTING.md` in this directory
- **Quick Test Script:** Run `./test.sh` for testing instructions
- **Verify Plugin Structure:** Compare with `tests/fixtures/valid-plugin/`
- **Check Logs:** Look for error messages in Claude Code console output

## Marketplace Integration

This plugin is registered in the agentics-test marketplace at `marketplace-data/.claude-plugin/marketplace.json`:

```json
{
  "name": "hello-world",
  "version": "1.0.0",
  "description": "A minimal example plugin for testing the marketplace",
  "source": "../plugins/hello-world",
  "category": "learning",
  "tags": ["example", "tutorial", "minimal"]
}
```

## Contributing

This is an example plugin for testing purposes. For improvements:

1. Keep changes minimal and focused
2. Maintain clarity over complexity
3. Update documentation to match changes
4. Ensure compatibility with marketplace API

## License

MIT License

Copyright (c) 2024 Agentics Project

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

## Resources

- [Claude Code Plugin Documentation](https://github.com/anthropics/claude-code)
- [Agentics Marketplace API](../../docs/api.md)
- [Plugin Development Guide](../README.md)
