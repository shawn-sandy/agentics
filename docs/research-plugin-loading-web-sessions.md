# Research: Making Marketplace Plugins Available in Remote/Web Sessions

**Date:** 2026-06-06
**Session:** https://claude.ai/code/session_01QY4UTSwVSvZ878JkF6cK1k

## Problem

The 12 agentics-kit plugins are registered in `marketplace.json` and enabled via `enabledPlugins` in `.claude/settings.json`, but they don't load in Claude Code on the web (remote sessions). Commands like `/plan-agent:implementation-plan` show "Unknown command."

## Root Cause

Remote/web sessions are ephemeral containers. The `enabledPlugins` + `extraKnownMarketplaces` config requires a **one-time interactive trust prompt** the first time a marketplace is used. In a non-interactive remote session, this prompt is never accepted, so marketplace plugins never load.

From `docs/plugin-auto-load-setup.md`:
> A non-interactive context (e.g. a fresh Claude Code on the web session that can't answer prompts) may not load the kit until that prompt is accepted

## What Currently Works

- **Built-in skills** (e.g., `code-review`, `verify`, `init`) load fine
- **Local skills** in `.claude/skills/` load fine (e.g., `validate-plugin` is in `.claude/skills/validate-plugin/SKILL.md` and works)
- The `SessionStart` hook for the merge driver runs successfully
- Claude Code version in remote env: `2.1.167`

## Current Config (`.claude/settings.json`)

```json
{
  "extraKnownMarketplaces": {
    "agentics-kit": {
      "source": { "source": "github", "repo": "shawn-sandy/agentics" }
    }
  },
  "enabledPlugins": {
    "memory-tools@agentics-kit": true,
    "code-review@agentics-kit": true,
    "plan-interview@agentics-kit": true,
    // ... all 12 plugins
  }
}
```

## Potential Solution: Skills-Directory Plugins

### How it works

From the [official docs](https://code.claude.com/docs/en/plugins-reference#skills-directory-plugins):

> Any folder under a skills directory that contains a `.claude-plugin/plugin.json` manifest is loaded as a plugin named `<name>@skills-dir` on the next session, with no marketplace and no install step.

The plugins already have the right structure — each has `.claude-plugin/plugin.json`. Placing them (or symlinks to them) in `.claude/skills/` would make them auto-discoverable without marketplace trust.

### Implementation approach

Create a `scripts/link-plugins.sh` script that:
1. Reads active plugin names from `marketplace.json`
2. Creates symlinks: `.claude/skills/<name>` → `../../kit/plugins/<name>`
3. Is idempotent (safe to re-run)

Add it as a `SessionStart` hook in `.claude/settings.json`:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$TOPLEVEL/scripts/link-plugins.sh\""
          }
        ]
      }
    ]
  }
}
```

### Important caveat: project-scope restrictions

From the docs:
> **Project-scope `@skills-dir` plugins** have these restrictions:
> - Hooks and MCP servers do NOT load
> - Background monitors do not load
> - Personal-scope plugins have none of these restrictions

This means:
- **Skills, commands, agents** — WILL work (covers `/plan-agent:implementation-plan`, `/git-agent:commit`, etc.)
- **Plugin hooks** (e.g., `plan-agent/hooks.json` for filename validation) — will NOT load
- **Plugin MCP servers** — will NOT load

Affected plugins with hooks:
| Plugin | Hook | Impact |
|--------|------|--------|
| `plan-agent` | `validate-plan-filename.py`, `rebuild-plans-index.py` | Plan filename validation and gallery rebuild won't auto-fire |
| `plan-interview` | PostToolUse on ExitPlanMode | Auto-activation after Plan Mode won't trigger |
| `skill-reviewer` | Hook config for skill auditing | Skill audit hooks won't fire |

### Alternative: commit symlinks directly

Instead of a SessionStart hook, commit the symlinks directly to git:
```bash
cd .claude/skills
ln -s ../../kit/plugins/plan-agent plan-agent
ln -s ../../kit/plugins/code-review code-review
# ... etc
```

**Pro:** No hook needed, works immediately on clone.
**Con:** Must maintain symlinks when plugins are added/removed. Git handles symlinks but Windows users may have issues.

### Alternative: `--plugin-dir` (not viable for web)

`claude --plugin-dir ./kit/plugins/plan-agent` works locally but can't be used in remote sessions since you don't control the CLI invocation.

## Plugin Component Map (all 12 active plugins)

| Plugin | Skills | Commands | Agents | Hooks | Would hooks load via skills-dir? |
|--------|--------|----------|--------|-------|----------------------------------|
| memory-tools | 2 | — | — | — | N/A |
| code-review | 1 | 1 | 1 | — | N/A |
| plan-interview | 6 | 10 | 1 | Yes | No |
| wcag-compliance-reviewer | 1 | — | — | — | N/A |
| skill-reviewer | 4 | 1 | — | Yes | No |
| code-testing-agent | 5 | — | — | — | N/A |
| git-agent | 5 | 3 | 3 | — | N/A |
| product-plans | 1 | 1 | 7 | — | N/A |
| settings-sync | 2 | — | — | — | N/A |
| social-media-tools | 13 | 1 | — | — | N/A |
| plan-agent | 5 | — | — | Yes | No |
| issue-agent | 1 | — | — | — | N/A |

## Key Files

- `.claude/settings.json` — current plugin config
- `.claude-plugin/marketplace.json` — marketplace registry
- `.claude/skills/validate-plugin/SKILL.md` — working example of a local skills-dir skill
- `docs/plugin-auto-load-setup.md` — existing setup documentation
- `kit/plugins/*/` — all plugin source directories

## Official Documentation

- [Plugins](https://code.claude.com/docs/en/plugins) — creating plugins
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference) — skills-directory plugins section
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces) — marketplace distribution
- [Discover Plugins](https://code.claude.com/docs/en/discover-plugins) — installation
- [Claude Code on the Web](https://code.claude.com/docs/en/claude-code-on-the-web) — remote environment docs

## Open Questions

1. **Would symlinks work cross-platform?** Git stores symlinks, but Windows without developer mode may not resolve them. If contributors use Windows, a SessionStart hook that copies (not symlinks) may be safer.
2. **Plugin hooks gap:** 3 plugins have hooks that won't load from project-scope skills-dir. Should those hooks be migrated to `.claude/settings.json` as project-level hooks instead?
3. **Naming collision:** If the marketplace trust IS eventually accepted in a session, would `plan-agent@agentics-kit` and `plan-agent@skills-dir` conflict? The docs say `--plugin-dir` takes precedence over marketplace — need to verify skills-dir behavior.
4. **`/reload-plugins` in remote sessions:** Could this be called manually to force marketplace plugin loading after the session starts?

## Recommendation

Implement the **SessionStart hook + symlink script** approach. It:
- Works automatically in every session (local and remote)
- Doesn't require committing 12 symlinks to git
- Is idempotent and low-risk
- Solves the immediate problem (skills/commands/agents load)

For the hooks gap, migrate the 3 affected plugins' hooks into `.claude/settings.json` as project-level hooks (they already use `${CLAUDE_PLUGIN_ROOT}` which would need adjustment).
