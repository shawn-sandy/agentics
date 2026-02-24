# Test Fixtures

This directory contains minimal plugin fixtures for automated testing of the marketplace API and CLI.

## Available Fixtures

### valid-plugin

A minimal valid plugin that passes all validation checks.

**Purpose:** Test successful plugin loading, parsing, and indexing.

**Structure:**
```
valid-plugin/
└── .claude-plugin/
    └── plugin.json
```

**plugin.json:**
- ✅ All required fields present (name, version, description)
- ✅ Valid JSON syntax
- ✅ Proper semantic versioning
- ✅ Optional fields included (author, license, category)

**Use in tests:**
```typescript
// Load valid plugin
const validPlugin = loadPluginFromPath('./tests/fixtures/valid-plugin');
expect(validPlugin).toBeDefined();
expect(validPlugin.name).toBe('test-valid-plugin');
expect(validPlugin.version).toBe('1.0.0');
```

### invalid-plugin

A plugin with missing required fields to test error handling.

**Purpose:** Test validation and error handling for malformed plugins.

**Structure:**
```
invalid-plugin/
└── .claude-plugin/
    └── plugin.json
```

**plugin.json:**
- ❌ Missing `version` field (required)
- ✅ Has name and description

**Use in tests:**
```typescript
// Attempt to load invalid plugin
expect(() => {
  loadPluginFromPath('./tests/fixtures/invalid-plugin');
}).toThrow('Missing required field: version');
```

## Test Scenarios

### Valid Plugin Tests

Test that the valid plugin fixture:
- [ ] Loads without errors
- [ ] Contains all expected metadata
- [ ] Passes validation checks
- [ ] Can be indexed by marketplace API
- [ ] Can be serialized/deserialized correctly

### Invalid Plugin Tests

Test that the invalid plugin fixture:
- [ ] Throws appropriate error when loaded
- [ ] Error message clearly identifies missing field
- [ ] Does not crash the system
- [ ] Logs error appropriately
- [ ] Returns structured error response (not generic failure)

## Creating Additional Fixtures

When adding new test fixtures, follow these guidelines:

### Naming Convention
- Use descriptive names that indicate the test purpose
- Prefix with `valid-` or `invalid-` to indicate expected outcome
- Examples: `valid-with-commands`, `invalid-bad-version`, `valid-complex`

### Directory Structure
- Mirror actual plugin structure
- Include only what's needed for the specific test
- Add README if fixture behavior is non-obvious

### Documentation
- Explain what the fixture tests
- Document any special characteristics
- Provide example test code

## Example Fixtures to Add

### valid-with-commands
Plugin with command files to test component discovery:
```
valid-with-commands/
├── .claude-plugin/
│   └── plugin.json
└── commands/
    ├── hello.md
    └── goodbye.md
```

### valid-with-skill
Plugin with a skill to test skill parsing:
```
valid-with-skill/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    └── my-skill/
        └── SKILL.md
```

### invalid-bad-json
Plugin with syntax errors in JSON:
```json
{
  "name": "test-bad-json",
  "version": "1.0.0",
  "description": "Missing closing quote
}
```

### invalid-bad-version
Plugin with invalid semantic version:
```json
{
  "name": "test-bad-version",
  "version": "1.0",  // Not semantic version
  "description": "Invalid version format"
}
```

## Usage in Tests

### Unit Tests

```typescript
import { describe, it, expect } from 'vitest';
import { loadPlugin, validatePlugin } from '../src/plugin-loader';

describe('Plugin Validation', () => {
  it('should load valid plugin', () => {
    const plugin = loadPlugin('./tests/fixtures/valid-plugin');
    expect(plugin.name).toBe('test-valid-plugin');
  });

  it('should reject invalid plugin', () => {
    expect(() => {
      loadPlugin('./tests/fixtures/invalid-plugin');
    }).toThrow('Missing required field: version');
  });
});
```

### Integration Tests

```typescript
describe('Marketplace API', () => {
  it('should index valid plugins', async () => {
    const response = await fetch('http://localhost:3000/api/v1/plugins');
    const plugins = await response.json();

    const testPlugin = plugins.find(p => p.name === 'test-valid-plugin');
    expect(testPlugin).toBeDefined();
  });

  it('should skip invalid plugins', async () => {
    // Invalid plugin should not appear in results
    const response = await fetch('http://localhost:3000/api/v1/plugins');
    const plugins = await response.json();

    const invalidPlugin = plugins.find(p => p.name === 'test-invalid-plugin');
    expect(invalidPlugin).toBeUndefined();
  });
});
```

## Best Practices

### Keep Fixtures Minimal
- Include only what's necessary for the test
- Avoid duplicating production plugin complexity
- Focus on specific scenarios

### Make Intent Clear
- Name fixtures descriptively
- Document what they test
- Explain any non-obvious behavior

### Maintain Fixtures
- Update when plugin schema changes
- Add new fixtures for new features
- Remove obsolete fixtures

### Organize by Purpose
- Group related fixtures in subdirectories if needed
- Use consistent naming conventions
- Document fixture organization in this README

## Resources

- [Plugin Structure Reference](../../plugins/hello-world/README.md)
- [Marketplace Configuration](../../.claude-plugin/marketplace.json)
- [Claude Code Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
