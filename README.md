# agentics

A marketplace system for Claude Code plugins, enabling discovery, distribution, and installation of plugins that extend Claude's capabilities.

## Overview

The agentics project provides:

- **Plugin Marketplace API** - REST API for discovering and serving Claude Code plugins
- **Example Plugins** - Reference implementations demonstrating plugin structure
- **Test Marketplace** - Local marketplace for testing and development
- **CLI Tools** - Command-line utilities for plugin management (planned)

## Prerequisites

### Required

- **Claude Code CLI** (version 1.0.0 or later)
  ```bash
  # Verify installation
  claude --version
  ```

### Optional (For API Development)

- **Node.js** (version 18.0.0 or later)
  ```bash
  # Verify installation
  node --version
  ```
- **npm** or **yarn** package manager

### Platform Support

- **macOS** 12.0 or later
- **Linux** (Ubuntu 20.04+ or equivalent)
- **Windows** (WSL2 recommended for best compatibility)

### Optional Tools

- **Git** - For cloning the repository
- **curl** - For API testing
- **jq** - For JSON parsing and formatting in examples

## Project Structure

```
agentics/
├── plugins/                      # Example plugins for testing
│   ├── hello-world/              # Minimal example plugin
│   └── dev-tools/                # Multi-component plugin
├── marketplace-data/             # Test marketplace configuration
│   └── .claude-plugin/
│       └── marketplace.json      # Marketplace manifest
├── tests/
│   └── fixtures/                 # Test plugin fixtures
└── README.md                     # This file
```

## Installation

### For Plugin Users (Testing Example Plugins)

If you want to test the example plugins locally, no dependencies are required beyond Claude Code CLI.

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/agentics.git
   cd agentics
   ```

2. **Load a plugin directly:**
   ```bash
   # Test with hello-world plugin
   claude --plugin-dir ./plugins/hello-world
   ```

3. **Verify the plugin loaded:**
   ```bash
   # In Claude, list available commands:
   # /help
   # You should see /hello-world:greet in the list
   ```

**Note:** You can test plugins immediately without installing any dependencies. The `--plugin-dir` flag loads plugins directly from your local filesystem.

### For Marketplace API Developers

If you want to develop or test the marketplace API (currently in progress):

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/agentics.git
   cd agentics
   ```

2. **Install dependencies (when API is implemented):**
   ```bash
   npm install
   # or
   yarn install
   ```

3. **Start the development server:**
   ```bash
   npm run dev
   # API will be available at http://localhost:3000
   ```

**Note:** The marketplace API is currently in development. Plugins work independently and can be tested without the API using the `--plugin-dir` method above.

### Troubleshooting

#### "claude: command not found"

The Claude Code CLI is not installed or not in your PATH.

**Solution:**
- Install Claude Code from the official source
- Verify installation: `claude --version`
- On macOS/Linux: Ensure `~/.local/bin` or the installation directory is in your PATH
- On Windows: Use WSL2 and follow Linux installation steps

#### Plugin not loading

The plugin directory may not exist or the path is incorrect.

**Solution:**
- Verify the path exists: `ls -la ./plugins/hello-world`
- Use absolute paths if relative paths aren't working:
  ```bash
  claude --plugin-dir /full/path/to/agentics/plugins/hello-world
  ```
- Check that `.claude-plugin/plugin.json` exists in the plugin directory

#### Permission errors

The plugin directory or files may not be readable.

**Solution:**
- Check file permissions: `ls -la ./plugins/hello-world`
- Make directory readable: `chmod -R +r ./plugins/hello-world`
- Ensure you own the files: `chown -R $USER:$USER ./plugins/`

## Usage Guide

### For Plugin Users

#### Single Plugin Testing

Test individual plugins by loading them directly:

```bash
# Test hello-world plugin
claude --plugin-dir ./plugins/hello-world

# In Claude, run:
# /hello-world:greet
# /hello-world:greet Alice
```

#### Multiple Plugin Testing

Load multiple plugins simultaneously by specifying multiple `--plugin-dir` flags:

```bash
# Load both plugins at once
claude --plugin-dir ./plugins/hello-world --plugin-dir ./plugins/dev-tools

# In Claude, you can now use commands from both plugins:
# /hello-world:greet
# /dev-tools:format src/index.ts
```

#### Commands vs Skills

**Commands** require explicit invocation using the `/plugin:command` syntax:
```bash
# Explicit command invocation
/dev-tools:format src/index.ts
```

**Skills** activate automatically based on your request:
```bash
# Just ask naturally - the code-review skill will activate automatically
"Can you review this code for issues?"
"Check this file for bugs"
```

**Tip:** Use `/help` in Claude to see all available commands from loaded plugins.

### For API Developers

**Prerequisites:** Ensure you've completed the [installation steps for API developers](#for-marketplace-api-developers) before proceeding.

**Note:** The marketplace API is currently in progress. The examples below represent the planned functionality.

#### Using the Marketplace API (In Progress)

1. **Start the API server:**
   ```bash
   npm run dev
   ```

2. **Register the test marketplace:**
   ```bash
   curl -X POST http://localhost:3000/api/v1/marketplaces \
     -H "Content-Type: application/json" \
     -d '{
       "name": "agentics-test",
       "source": {
         "type": "local",
         "path": "./marketplace-data"
       }
     }'
   ```

3. **Sync and discover plugins:**
   ```bash
   curl -X POST http://localhost:3000/api/v1/marketplaces/agentics-test/sync
   ```

4. **List available plugins:**
   ```bash
   curl http://localhost:3000/api/v1/plugins
   ```

## Example Plugins

### hello-world

A minimal viable plugin demonstrating basic plugin structure.

**Features:**
- Single slash command: `/hello-world:greet`
- Demonstrates argument handling
- Clean, well-documented code

[View Plugin Documentation](./plugins/hello-world/README.md)

### dev-tools

A multi-component plugin showcasing commands and skills working together.

**Features:**
- Command: `/dev-tools:format` - Format code files
- Skill: `code-review` - Automatically review code for issues

[View Plugin Documentation](./plugins/dev-tools/README.md)

## Test Marketplace

The `marketplace-data/` directory contains a test marketplace configuration that references the example plugins. This marketplace is used for:

- Testing marketplace API functionality
- Demonstrating marketplace structure
- Providing reference implementation
- End-to-end integration testing

[View Marketplace Documentation](./marketplace-data/README.md)

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
# Test plugin directly
claude --plugin-dir ./plugins/my-plugin

# In Claude, invoke your command
# /my-plugin:my-command
```

### Registering Plugins in Marketplace

Add your plugin to `marketplace-data/.claude-plugin/marketplace.json`:

```json
{
  "plugins": [
    ...existing plugins,
    {
      "name": "my-plugin",
      "version": "1.0.0",
      "description": "My test plugin",
      "source": "../plugins/my-plugin",
      "category": "development",
      "tags": ["testing"]
    }
  ]
}
```

Then resync the marketplace:

```bash
curl -X POST http://localhost:3000/api/v1/marketplaces/agentics-test/sync
```

## Documentation

- [Plugin Directory](./plugins/README.md) - Plugin development guide and examples
- [Marketplace Documentation](./marketplace-data/README.md) - Marketplace setup and API usage
- [Test Fixtures](./tests/fixtures/README.md) - Testing utilities and fixtures

## Roadmap

### Current Features
- ✅ Example plugin implementations (hello-world, dev-tools)
- ✅ Test marketplace configuration
- ✅ Plugin structure documentation

### In Progress
- 🚧 Marketplace API implementation
- 🚧 Plugin discovery and indexing
- 🚧 RESTful API endpoints

### Planned Features
- ⏱️ CLI for plugin installation (`agentics install`)
- ⏱️ Plugin search and filtering
- ⏱️ Remote marketplace support
- ⏱️ Plugin versioning and updates
- ⏱️ Dependency management
- ⏱️ Plugin scaffolding tools
- ⏱️ Publishing workflow

## Contributing

### Creating Example Plugins

1. Follow the plugin structure in `plugins/README.md`
2. Keep examples simple and focused
3. Document all components clearly
4. Test thoroughly before committing

### Plugin Guidelines

- Use official Claude Code plugin structure
- Include comprehensive README
- Follow semantic versioning
- Provide clear component descriptions
- Test with Claude Code before publishing

## Resources

- [Claude Code Documentation](https://github.com/anthropics/claude-code)
- [Claude Code Plugin Guide](https://docs.anthropic.com/claude-code/plugins)
- [Plugin Development Best Practices](./plugins/README.md)

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