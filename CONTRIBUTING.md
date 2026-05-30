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

## First-time Setup

Run this once after cloning to register the `marketplace.json` merge driver:

```bash
bash scripts/setup-merge-driver.sh
```

This lets git automatically resolve version conflicts in `.claude-plugin/marketplace.json` by keeping the higher semver per plugin during merges and rebases. Claude Code sessions self-register the driver automatically via a `SessionStart` hook — manual setup is only needed for non-Claude contributors.

## Plugin Development Workflow

1. **Create your plugin** following the structure in [plugins/README.md](./plugins/README.md)
2. **Test locally** with `claude --plugin-dir ./kit/plugins/your-plugin`
3. **Register** in `.claude-plugin/marketplace.json` with a bumped version — do **not** add `version` to `plugin.json`
4. **Document** with a README.md in your plugin directory

### Plugin Structure

```
kit/plugins/my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Required: name, description (no version field)
├── commands/                 # Slash commands (optional)
│   └── my-command.md
├── skills/                   # Auto-activated skills (optional)
│   └── my-skill/
│       └── SKILL.md
└── README.md                 # Plugin documentation
```

> **Version rule:** `version` lives **only** in `.claude-plugin/marketplace.json`. Adding it to `plugin.json` silently overrides the marketplace version and causes conflicts.

## Pull Request Process

1. Create a feature branch from `main`
2. Make your changes
3. Bump the plugin's `version` in `.claude-plugin/marketplace.json` (must be higher than `main`)
4. Test your plugin locally with `--plugin-dir`
5. Include the plan file in commits for plugin changes
6. Submit a PR with a clear description

### PR Checklist

- [ ] Plugin manifest (`plugin.json`) has required fields: `name`, `description` — **no `version` field**
- [ ] Plugin version bumped in `marketplace.json` and is higher than the version on `main`
- [ ] Plugin tested locally with `claude --plugin-dir`
- [ ] README.md included in plugin directory
- [ ] Homepage URL points to plugin's directory (e.g., `https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/my-plugin`)
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
