# Agentics Test Marketplace

This directory contains the test marketplace configuration for the agentics plugin development system. It serves as a reference implementation and testing environment for the marketplace API.

## Overview

The test marketplace (`agentics-test`) is a local marketplace that references example plugins in the `plugins/` directory. It demonstrates how marketplaces organize and distribute Claude Code plugins.

## Installation

### Prerequisites

Your setup requirements depend on what you want to do:

**For Testing Plugins (No API needed):**
- **Claude Code CLI** (version 1.0.0 or later)
  ```bash
  # Verify installation
  claude --version
  ```

**For API Development/Testing:**
- **Claude Code CLI** (version 1.0.0 or later)
- **Node.js** (version 18.0.0 or later)
  ```bash
  # Verify installation
  node --version
  ```
- **npm** or **yarn** package manager
- **Git** (for cloning the repository)
- **curl** and **jq** (optional, for API testing)

### Setup for Direct Plugin Testing

If you just want to test the example plugins without the marketplace API:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/agentics.git
   cd agentics
   ```

2. **Load a plugin directly:**
   ```bash
   # Test hello-world plugin
   claude --plugin-dir ./plugins/hello-world

   # In Claude, run:
   # /hello-world:greet
   ```

**Note:** You don't need the marketplace API to test plugins. The API is only needed for testing marketplace discovery and distribution workflows.

### Setup for Marketplace API Testing

If you want to test the marketplace API (currently in development):

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

3. **Start the API server:**
   ```bash
   npm run dev
   # API will be available at http://localhost:3000
   ```

4. **Verify API is running:**
   ```bash
   curl http://localhost:3000/api/v1/marketplaces
   # Should return marketplace list (may be empty initially)
   ```

**Note:** The marketplace API is currently in development. See the [Using the Test Marketplace](#using-the-test-marketplace) section for API workflow examples.

### Verify Marketplace Configuration

To verify the marketplace configuration is valid:

1. **Check marketplace.json exists:**
   ```bash
   ls -la marketplace-data/.claude-plugin/marketplace.json
   ```

2. **Validate JSON syntax:**
   ```bash
   cat marketplace-data/.claude-plugin/marketplace.json | jq .
   # Should output formatted JSON without errors
   ```

3. **Verify plugin source paths:**
   ```bash
   # From repository root, check that plugins exist
   ls -la plugins/hello-world/.claude-plugin/plugin.json
   ls -la plugins/dev-tools/.claude-plugin/plugin.json
   ```

4. **Test a plugin directly:**
   ```bash
   # Load and test to ensure plugins work
   claude --plugin-dir ./plugins/hello-world
   ```

## Marketplace Structure

```
marketplace-data/
├── .claude-plugin/
│   └── marketplace.json        # Marketplace manifest
└── README.md                   # This file
```

## Marketplace Manifest

The `marketplace.json` file defines the marketplace and lists available plugins:

```json
{
  "$schema": "https://anthropic.com/claude-code/marketplace.schema.json",
  "name": "agentics-test",
  "version": "1.0.0",
  "description": "Test marketplace for agentics plugin development",
  "owner": {
    "name": "Agentics Project"
  },
  "plugins": [...]
}
```

### Manifest Fields

**Required:**
- `name` - Unique marketplace identifier
- `version` - Semantic version
- `description` - Brief marketplace description
- `plugins` - Array of plugin entries

**Optional:**
- `owner` - Marketplace owner information
- `$schema` - JSON schema for validation

### Plugin Entries

Each plugin entry in the `plugins` array specifies:

```json
{
  "name": "plugin-name",
  "version": "1.0.0",
  "description": "Plugin description",
  "source": "../plugins/plugin-name",
  "category": "development",
  "tags": ["tag1", "tag2"],
  "components": {
    "commands": ["command1", "command2"],
    "skills": ["skill1"]
  }
}
```

**Required Fields:**
- `name` - Plugin identifier (must match plugin.json)
- `version` - Plugin version (must match plugin.json)
- `description` - Brief description
- `source` - Path to plugin directory (relative or absolute)

**Optional Fields:**
- `category` - Plugin category (development, productivity, etc.)
- `tags` - Array of searchable tags
- `components` - List of included components (commands, skills, agents, hooks)

## Registered Plugins

### hello-world
**Category:** learning
**Tags:** example, tutorial, minimal

A minimal example plugin demonstrating basic plugin structure.

**Components:**
- Command: `greet`

### dev-tools
**Category:** development
**Tags:** development, code-quality, formatting

Developer productivity tools for code formatting and review.

**Components:**
- Command: `format`
- Skill: `code-review`

## Using the Test Marketplace

### With Marketplace API

When the marketplace API server is running, you can interact with this marketplace:

#### 1. Register the marketplace

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

#### 2. Sync marketplace (discover plugins)

```bash
curl -X POST http://localhost:3000/api/v1/marketplaces/agentics-test/sync
```

This triggers the API to:
1. Read `marketplace.json`
2. Locate plugin directories via `source` paths
3. Parse plugin manifests and components
4. Index plugin metadata for search and retrieval

#### 3. List all plugins

```bash
curl http://localhost:3000/api/v1/plugins
```

#### 4. Get specific plugin

```bash
curl http://localhost:3000/api/v1/plugins/hello-world@agentics-test
```

#### 5. Search plugins

```bash
curl "http://localhost:3000/api/v1/plugins?category=development"
curl "http://localhost:3000/api/v1/plugins?q=code"
```

### With CLI (when available)

```bash
# List marketplace plugins
agentics list --marketplace agentics-test

# Install a plugin
agentics install hello-world --marketplace agentics-test

# Search plugins
agentics search "code review"
```

## API Integration

The marketplace API performs these operations on the test marketplace:

### Discovery
Reads `marketplace.json` to get the list of plugins and their source locations.

### Indexing
For each plugin:
1. Reads `plugin.json` manifest
2. Scans `commands/`, `skills/`, `agents/`, `hooks/` directories
3. Extracts component metadata (descriptions, parameters, etc.)
4. Builds searchable index with categories and tags

### Serving
Provides REST API endpoints:
- `GET /api/v1/marketplaces` - List all marketplaces
- `GET /api/v1/marketplaces/:id` - Get marketplace details
- `POST /api/v1/marketplaces/:id/sync` - Resync marketplace
- `GET /api/v1/plugins` - List/search plugins
- `GET /api/v1/plugins/:id` - Get specific plugin details

## Development Workflow

### Adding a New Plugin

1. **Create plugin directory:**
   ```bash
   mkdir -p plugins/my-plugin/.claude-plugin
   ```

2. **Create plugin.json:**
   ```json
   {
     "name": "my-plugin",
     "version": "1.0.0",
     "description": "My test plugin"
   }
   ```

3. **Add components** (commands, skills, etc.)

4. **Register in marketplace.json:**
   ```json
   {
     "plugins": [
       ...existing plugins,
       {
         "name": "my-plugin",
         "version": "1.0.0",
         "description": "My test plugin",
         "source": "../plugins/my-plugin"
       }
     ]
   }
   ```

5. **Resync marketplace:**
   ```bash
   curl -X POST http://localhost:3000/api/v1/marketplaces/agentics-test/sync
   ```

### Testing Changes

After modifying plugins or marketplace.json:

1. **Resync the marketplace** to update the API index
2. **Query the API** to verify changes are reflected
3. **Test plugin installation** via CLI

## Marketplace Categories

Standard categories for organizing plugins:

- `development` - Developer tools and utilities
- `productivity` - Workflow and efficiency tools
- `learning` - Educational and tutorial plugins
- `testing` - Testing and QA tools
- `documentation` - Documentation generators and tools
- `security` - Security analysis and auditing
- `data` - Data processing and analysis

## Best Practices

### Versioning
- Use semantic versioning (MAJOR.MINOR.PATCH)
- Increment version in both `plugin.json` and `marketplace.json`
- Document breaking changes

### Source Paths
- Use relative paths for local development (`../plugins/...`)
- Use URLs for remote plugins (when supported)
- Ensure paths are accessible from marketplace API server

### Metadata
- Provide clear, concise descriptions
- Use relevant tags for discoverability
- Specify correct categories
- List all components explicitly

### Documentation
- Keep plugin READMEs up to date
- Document installation requirements
- Provide usage examples
- Explain component behavior

## Troubleshooting

### Plugins Not Discovered

**Check:**
1. Source path is correct in `marketplace.json`
2. Plugin has valid `plugin.json` manifest
3. Marketplace sync was run after changes
4. API server has read permissions on plugin directories

**Debug:**
```bash
# Check marketplace sync logs
curl http://localhost:3000/api/v1/marketplaces/agentics-test

# Verify plugin structure
ls -la plugins/hello-world/.claude-plugin/plugin.json
```

### Invalid Plugin Metadata

**Validate plugin.json:**
```bash
# Check JSON syntax
cat plugins/my-plugin/.claude-plugin/plugin.json | jq .

# Verify required fields
jq '.name, .version, .description' plugins/my-plugin/.claude-plugin/plugin.json
```

### Source Path Errors

**Ensure paths are correct:**
```bash
# From marketplace-data directory
ls ../plugins/hello-world/.claude-plugin/plugin.json

# Verify relative path works
cd marketplace-data
cat $(jq -r '.plugins[0].source' .claude-plugin/marketplace.json)/.claude-plugin/plugin.json
```

## Testing Scenarios

### Valid Marketplace Operations

✅ Register marketplace
✅ Sync marketplace
✅ List plugins
✅ Get plugin by ID
✅ Search plugins by category
✅ Search plugins by tags
✅ Filter plugins by component type

### Error Handling

Test how the API handles:
- ❌ Invalid marketplace.json syntax
- ❌ Missing plugin.json files
- ❌ Invalid source paths
- ❌ Version mismatches
- ❌ Duplicate plugin names
- ❌ Malformed component definitions

## Future Enhancements

Potential improvements to the marketplace system:

1. **Remote Sources** - Support Git URLs and HTTP sources
2. **Dependency Management** - Handle plugin dependencies
3. **Version Constraints** - Specify compatible version ranges
4. **Auto-Update** - Automatic plugin updates from marketplace
5. **Publishing** - Tools for publishing plugins to marketplaces
6. **Verification** - Digital signatures and verified publishers
7. **Analytics** - Download and usage statistics

## Resources

- [Plugin Directory](../plugins/README.md) - Example plugin implementations
- [Marketplace API Documentation](../docs/api.md) - API reference
- [Claude Code Plugin Docs](https://github.com/anthropics/claude-code) - Official plugin documentation

## License

MIT License - See individual plugin directories for specific licenses.
