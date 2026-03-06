# Contributing to Agentics

Thank you for your interest in contributing to the agentics plugin marketplace!

## Reporting Bugs

1. Check [existing issues](https://github.com/shawn-sandy/agentics/issues) to avoid duplicates
2. Open a new issue using the **Bug Report** template
3. Include: steps to reproduce, expected behavior, actual behavior, Claude Code version

## Proposing New Plugins

1. Open an issue using the **New Plugin** template
2. Describe the plugin's purpose, commands/skills, and target audience
3. Discuss the proposal before starting development

## Plugin Development Workflow

### 1. Create Your Plugin

```bash
mkdir -p plugins/my-plugin/.claude-plugin
mkdir -p plugins/my-plugin/commands  # or skills/

# Create plugin manifest
cat > plugins/my-plugin/.claude-plugin/plugin.json <<EOF
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Brief description of what the plugin does"
}
EOF
```

### 2. Test Locally

```bash
claude --plugin-dir ./plugins/my-plugin
```

### 3. Register in Marketplace

Add your plugin entry to `.claude-plugin/marketplace.json`. The `version` must match your `plugin.json` exactly.

### 4. Submit a PR

See the PR process below.

## PR Process

1. Fork the repository and create a feature branch
2. Make your changes following the conventions below
3. Test your plugin locally with `--plugin-dir`
4. Ensure version sync between `plugin.json` and `marketplace.json`
5. Include a CHANGELOG.md entry for your plugin
6. Submit a PR with a clear description

### PR Checklist

- [ ] Plugin manifest (`plugin.json`) has required fields: `name`, `version`, `description`
- [ ] Version in `marketplace.json` matches `plugin.json`
- [ ] Plugin tested locally with `claude --plugin-dir`
- [ ] README.md included with usage examples
- [ ] Homepage URL points to plugin directory (e.g., `https://github.com/shawn-sandy/agentics/tree/main/plugins/my-plugin`)
- [ ] CHANGELOG.md updated

## Conventions

- **Commit messages:** Use [Conventional Commits](https://www.conventionalcommits.org/) — e.g., `feat(plugins/my-plugin): add format command`
- **Versioning:** Follow [Semantic Versioning](https://semver.org/)
- **Plugin names:** Lowercase, hyphen-separated (e.g., `my-plugin`)
- **Plugin structure:** Follow the [official Claude Code plugin structure](https://code.claude.com/docs/en/plugins)

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](./CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Questions?

Open a [discussion](https://github.com/shawn-sandy/agentics/discussions) or file an issue.
