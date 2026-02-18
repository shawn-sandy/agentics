# dev-tools Plugin

Developer productivity tools for code formatting and review. This multi-component plugin demonstrates how commands and skills work together in Claude Code plugins.

## Overview

The dev-tools plugin provides essential developer utilities for maintaining code quality. It showcases a plugin with both explicit commands (slash commands) and implicit skills (auto-activated based on context).

## Features

### Commands

- **`/dev-tools:format`** - Format code files or directories using language-appropriate tools (Prettier, Black, etc.)
- **`/dev-tools:plan-review`** - Review a plan and interview the user about technical implementation, trade-offs, UI/UX concerns, edge cases, and best practices

### Skills

- **`code-review`** - Automatically activated code review skill that analyzes code for bugs, security issues, and best practices

## Installation

### Prerequisites

**Required:**
- **Claude Code CLI** (version 1.0.33 or later - required for plugin support)
  ```bash
  # Verify installation
  claude --version
  ```
- **Git** (optional, for cloning the repository)

**Optional (for formatting functionality):**
- **Prettier** - For JavaScript/TypeScript/JSON/CSS/HTML formatting
  ```bash
  npm install -g prettier
  # Verify: prettier --version
  ```
- **Black** or **autopep8** - For Python formatting
  ```bash
  pip install black
  # Verify: black --version
  ```

**Note:** The plugin works without the formatters installed. The format command will detect available formatters and provide helpful messages if they're missing.

### Local Testing

Load the plugin directly from the file system using either method:

**Option 1: From any project folder (recommended)**
```bash
# Load the plugin using the absolute path from any directory
claude --plugin-dir ~/devbox/agentics/plugins/dev-tools

# Once Claude responds, you can type commands like:
# /dev-tools:format src/index.ts
# /dev-tools:plan-review path/to/plan.md
# Or ask: "Can you review this code for issues?"
```

**Option 2: From Repository Root**
```bash
# Navigate to the repository root
cd ~/devbox/agentics

# Load the plugin with relative path (starts interactive session)
claude --plugin-dir ./plugins/dev-tools
```

**Option 3: Register the marketplace (persistent)**
```bash
# Register once, then install — available everywhere
/plugin marketplace add ~/devbox/agentics/marketplace-data
/plugin install dev-tools@agentics-test
```

**Option 4: Direct Prompt Execution**
```bash
# Provide a prompt directly without entering interactive mode
claude --plugin-dir ~/devbox/agentics/plugins/dev-tools "Format the file src/index.ts"

# Or pipe commands
echo "Review the code in src/utils.js" | claude --plugin-dir ~/devbox/agentics/plugins/dev-tools
```

### Verify Installation

After loading the plugin, verify both commands and skills work:

**Verify Command:**
```bash
# Start the plugin in interactive mode:
claude --plugin-dir ./plugins/dev-tools

# Once in the Claude interactive session, run:
/dev-tools:format

# Expected behavior:
# - Lists available formatters if no file specified
# - Shows helpful message about formatter availability

# Or test with direct prompt:
claude --plugin-dir ./plugins/dev-tools "List available formatters"
```

**Verify Skill:**
```bash
# In the Claude interactive session, ask:
"Can you review this code for issues?"

# Expected behavior:
# - The code-review skill should activate automatically
# - Claude will provide structured code review feedback

# Or test with direct prompt:
claude --plugin-dir ./plugins/dev-tools "Review the code in src/index.js for issues"
```

You can also verify the command appears in the help:
```bash
# In the Claude interactive session, run:
/help

# You should see /dev-tools:format in the available commands list
```

### Via Marketplace (Planned)

When the marketplace API is complete, installation will be simplified:

```bash
agentics install dev-tools
```

## Usage

### Formatting Code

**Format current file:**
```
/dev-tools:format
```

**Format specific file:**
```
/dev-tools:format src/components/Button.tsx
```

**Format directory:**
```
/dev-tools:format src/
```

The format command automatically detects the file type and uses the appropriate formatter:
- JavaScript/TypeScript/JSON/CSS/HTML → Prettier
- Python → Black or autopep8

### Code Review

The code review skill activates automatically when you ask Claude to review code:

**Activate skill by asking:**
```
Can you review this code for issues?
Please check this function for bugs
Review the security of this API endpoint
```

The skill provides systematic feedback on:
- Code quality and maintainability
- Potential bugs and edge cases
- Security vulnerabilities
- Best practices and error handling

## Plugin Structure

```
dev-tools/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── commands/
│   ├── format.md                # Format command
│   └── plan-review.md           # Plan review command
├── skills/
│   └── code-review/
│       └── SKILL.md             # Code review skill
└── README.md                    # This file
```

## Components

### Command: format

**File:** `commands/format.md`
**Invocation:** `/dev-tools:format [path]`

Formats code files or directories using language-specific formatters.

**Supported Languages:**
- JavaScript, TypeScript, JSX, TSX
- Python
- JSON
- CSS, SCSS
- HTML
- Markdown

**Examples:**
```
/dev-tools:format src/index.ts
/dev-tools:format src/components/
/dev-tools:format .
```

**Requirements:**
- Prettier (for JS/TS/JSON/CSS/HTML)
- Black or autopep8 (for Python)

### Command: plan-review

**File:** `commands/plan-review.md`
**Invocation:** `/dev-tools:plan-review [path-to-plan]`

Reads a plan and conducts a structured interview using the AskUserQuestion tool across five dimensions: technical implementation, trade-offs, UI/UX concerns, edge cases, and best practices. Asks 1–2 focused questions per dimension, then summarizes key decisions, open items, and recommended next steps.

**Examples:**
```
/dev-tools:plan-review docs/migration-plan.md
/dev-tools:plan-review architecture/api-redesign.md
```

### Skill: code-review

**File:** `skills/code-review/SKILL.md`
**Activation:** Automatic when user asks to review code

Provides comprehensive code review covering:

1. **Code Quality** - Readability, maintainability, naming conventions
2. **Potential Bugs** - Common errors, edge cases, async issues
3. **Security** - Input validation, authentication, data exposure
4. **Best Practices** - Error handling, type safety, performance

**Activation Examples:**
- "Review this code"
- "Check for bugs"
- "Is this secure?"
- "Any improvements you'd suggest?"

## Development

This plugin demonstrates:

1. **Multi-Component Structure** - Commands + skills working together
2. **Command Arguments** - Using `$ARGUMENTS` for flexible inputs
3. **Skill Activation** - Clear description triggers automatic invocation
4. **Progressive Disclosure** - Detailed instructions in skill files
5. **External Tool Integration** - Calling formatters like Prettier and Black

## Testing

### Manual Testing

1. **Load the plugin (starts interactive session):**
   ```bash
   claude --plugin-dir ./plugins/dev-tools
   ```

2. **Test format command in the Claude session:**
   ```
   # Create a test file first (in a separate terminal)
   echo "function test(){console.log('hello')}" > test.js

   # In Claude session, format it
   /dev-tools:format test.js

   # Check the result (in separate terminal)
   cat test.js
   ```

3. **Or test with direct prompt:**
   ```bash
   echo "function test(){console.log('hello')}" > test.js
   claude --plugin-dir ./plugins/dev-tools "Format the file test.js"
   cat test.js
   ```

4. **Test code-review skill:**
   ```
   # In Claude session, ask Claude to review some code
   "Can you review this function for issues?"
   [Paste some code]

   # Verify the skill activates and provides structured feedback
   ```

### Expected Behavior

**Format Command:**
- Detects file type correctly
- Applies appropriate formatter
- Shows clear success/error messages
- Handles missing formatters gracefully

**Code Review Skill:**
- Activates when user asks to review code
- Provides specific feedback with line numbers
- Categorizes issues (critical vs improvements)
- Suggests concrete fixes

## Marketplace Integration

This plugin is registered in the agentics-test marketplace at `marketplace-data/.claude-plugin/marketplace.json`:

```json
{
  "name": "dev-tools",
  "version": "1.0.0",
  "description": "Developer productivity tools for code formatting and review",
  "source": "../plugins/dev-tools",
  "category": "development",
  "tags": ["development", "code-quality", "formatting"],
  "components": {
    "commands": ["format", "plan-review"],
    "skills": ["code-review"]
  }
}
```

## Dependencies

### Required

- None (plugin structure works without external tools)

### Optional (for full functionality)

- **Prettier** - JavaScript/TypeScript formatting
  ```bash
  npm install -g prettier
  ```

- **Black** - Python formatting
  ```bash
  pip install black
  ```

- **autopep8** - Alternative Python formatter
  ```bash
  pip install autopep8
  ```

## Configuration

### Prettier

The format command respects Prettier configuration files:
- `.prettierrc`
- `.prettierrc.json`
- `prettier.config.js`

### Black

The format command respects Black configuration in:
- `pyproject.toml`

## Troubleshooting

### "prettier: command not found"

Install Prettier globally:
```bash
npm install -g prettier
```

Or use npx:
```bash
npx prettier --write <file>
```

### "black: command not found"

Install Black:
```bash
pip install black
```

### Skill doesn't activate

Make sure your request clearly indicates code review intent:
- ✅ "Review this code"
- ✅ "Check for bugs"
- ✅ "Is this secure?"
- ❌ "What does this do?" (analysis, not review)

### "Input must be provided" Error

**Symptom:** Error message: `Error: Input must be provided either through stdin or as a prompt argument when using --print`

**Solutions:**
1. Try providing a prompt directly:
   ```bash
   claude --plugin-dir ./plugins/dev-tools "List available commands"
   ```
2. Or pipe a command:
   ```bash
   echo "Format my code" | claude --plugin-dir ./plugins/dev-tools
   ```
3. Verify your Claude Code version: `claude --version` (need 1.0.33+)
4. Check plugin.json is valid JSON:
   ```bash
   cat .claude-plugin/plugin.json | jq
   ```

## Contributing

This is an example plugin for testing purposes. For improvements:

1. Maintain multi-component structure
2. Keep commands focused and single-purpose
3. Ensure skills have clear activation criteria
4. Update documentation to match changes
5. Test both commands and skills thoroughly

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

- [Claude Code Documentation](https://code.claude.com/docs/en)
- [Create Plugins Guide](https://code.claude.com/docs/en/plugins)
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Prettier Documentation](https://prettier.io/docs/en/index.html)
- [Black Documentation](https://black.readthedocs.io/)
- [Agentics Marketplace API](../../docs/api.md)
- [Plugin Development Guide](../README.md)
