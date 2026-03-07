# Contributing to Agentics

Thank you for your interest in contributing! This guide covers how to report bugs, propose new plugins, and submit changes.

## Reporting Bugs

Open a [GitHub Issue](https://github.com/shawn-sandy/agentics/issues/new) with:

- Plugin name and version
- Claude Code CLI version (`claude --version`)
- Steps to reproduce
- Expected vs actual behavior
- Error messages or screenshots

## Proposing New Plugins

1. Open a GitHub Issue describing the plugin idea
2. Include: purpose, target audience, planned commands/skills
3. Wait for feedback before starting implementation

## Plugin Development Workflow

1. **Create your plugin** following the structure in [plugins/README.md](./plugins/README.md)
2. **Test locally** with `claude --plugin-dir ./plugins/your-plugin`
3. **Register** in `.claude-plugin/marketplace.json` (version must match `plugin.json`)
4. **Document** with a README.md in your plugin directory

### Plugin Structure

```
plugins/my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Required: name, version, description
├── commands/                 # Slash commands (optional)
│   └── my-command.md
├── skills/                   # Auto-activated skills (optional)
│   └── my-skill/
│       └── SKILL.md
└── README.md                 # Plugin documentation
```

## Pull Request Process

1. Create a feature branch from `main`
2. Make your changes
3. Ensure version sync between `plugin.json` and `marketplace.json`
4. Test your plugin locally with `--plugin-dir`
5. Include the plan file in commits for plugin changes
6. Submit a PR with a clear description

### PR Checklist

- [ ] Plugin manifest (`plugin.json`) has required fields: name, version, description
- [ ] Version in `marketplace.json` matches `plugin.json`
- [ ] Plugin tested locally with `claude --plugin-dir`
- [ ] README.md included in plugin directory
- [ ] Homepage URL points to plugin's directory (e.g., `https://github.com/shawn-sandy/agentics/tree/main/plugins/my-plugin`)
- [ ] CHANGELOG.md updated (for existing plugins)

## Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat(plugins/my-plugin): add new skill for X`
- `fix(plugins/my-plugin): correct version mismatch`
- `docs: update README with new plugin`

## Code of Conduct

This project follows the [Contributor Covenant](./CODE_OF_CONDUCT.md). Please read it before participating.

## Questions?

Open a [GitHub Issue](https://github.com/shawn-sandy/agentics/issues) or start a [Discussion](https://github.com/shawn-sandy/agentics/discussions).
