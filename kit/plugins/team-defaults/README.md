# team-defaults

Shared team defaults for Claude Code: the agents and global rules the team uses across every project, installable as one versioned plugin instead of hand-copied dotfiles.

## Features

- **Agents** (auto-discovered on install)
  - `ts-commenter` — TypeScript/JSDoc documentation specialist optimized for AI-assistant comprehension
  - `css-generator` — extracts design tokens from images into CSS custom properties and utility classes
- **Skills**
  - `sync-rules` — installs the bundled rule files into `~/.claude/rules/` with per-file diff and confirmation

## Bundled rules

| Rule | Scope |
|------|-------|
| `plan-mode.md` | Plan-mode workflow: frontmatter, naming, required structure |
| `reference/SKELETON.md` | Starter skeleton for new plans |
| `component-driven-ui.md` | Bottom-up component composition (`*.tsx`, `*.astro`, `*.vue`, `*.svelte`) |
| `typescript-jsdoc.md` | JSDoc documentation for TS/JS files |
| `review-bot-loops.md` | Guard against automated review-bot iteration loops |

Rules are not auto-installed — run the `sync-rules` skill ("sync team rules") after installing so nothing in your `~/.claude/rules/` is overwritten without confirmation.

## Installation

```bash
/plugin marketplace add shawn-sandy/agentics
/plugin install team-defaults@agentics-kit
```

Or load locally for testing:

```bash
claude --plugin-dir ./kit/plugins/team-defaults
```

## Usage

- "sync team rules" → runs `sync-rules`, reports new/changed/up-to-date files, asks before overwriting
- Agents activate automatically (e.g. asking for JSDoc comments on TypeScript triggers `ts-commenter`)

## Plugin Structure

```
team-defaults/
├── .claude-plugin/plugin.json
├── agents/
│   ├── code-comments.md     (ts-commenter)
│   └── css-generator.md
└── skills/
    └── sync-rules/
        ├── SKILL.md
        └── rules/
            ├── plan-mode.md
            ├── component-driven-ui.md
            ├── typescript-jsdoc.md
            ├── review-bot-loops.md
            └── reference/SKELETON.md
```

## Notes

- `plan-mode.md` references the `validate-plan-filename` hook, which ships with the `plan-agent` plugin — install both for the full planning workflow.
- Project-specific agents (e.g. per-repo ticket creators) intentionally stay out of this plugin; it carries only defaults that apply everywhere.
