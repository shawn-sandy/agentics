# agentics

A marketplace system for Claude Code plugins, enabling discovery, distribution, and installation of plugins that extend Claude's capabilities.

## Overview

The agentics project provides:

- **Plugin Marketplace API** - REST API for discovering and serving Claude Code plugins
- **Example Plugins** - Reference implementations demonstrating plugin structure
- **Test Marketplace** - Local marketplace for testing and development
- **CLI Tools** - Command-line utilities for plugin management (planned)

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

## Quick Start

### Using Example Plugins

Test the example plugins directly with Claude Code:

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
# /dev-tools:format src/index.ts
# Or ask: "Can you review this code for issues?"
```

### Using the Marketplace API

(API implementation in progress)

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