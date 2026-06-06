# Auto-loading the agentics-kit plugins

This guide explains how the `agentics-kit` plugins are made to load
automatically — no manual `/plugin install` per machine or per session — and how
each team member can enable the same kit across **all** their own repos.

## TL;DR

- Plugin enablement is configured in **`settings.json`**, not `CLAUDE.md`.
  CLAUDE.md is natural-language memory and is never read for plugin config.
- Two keys do the work: `extraKnownMarketplaces` (registers the marketplace)
  and `enabledPlugins` (turns plugins on).
- This repo already ships them in **project scope** (`.claude/settings.json`),
  so fresh clones and Claude Code on the web sessions of `agentics` auto-load
  the kit.
- To get the kit in **all your other repos**, add the same two keys to your
  personal **user settings** (`~/.claude/settings.json`).

## Why not `/plugin install`?

`/plugin install` and `/plugin marketplace add` are interactive, client-side
commands. They can't run from inside an agent session (e.g. Claude Code on the
web), and there is no `claude plugin install` CLI subcommand a script or
SessionStart hook could call. Plugin state is a **settings-file** concern, so
the durable, automatable mechanism is declarative settings — not a hook.

## The two settings keys

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
    "wcag-compliance-reviewer@agentics-kit": true,
    "skill-reviewer@agentics-kit": true,
    "code-testing-agent@agentics-kit": true,
    "git-agent@agentics-kit": true,
    "product-plans@agentics-kit": true,
    "settings-sync@agentics-kit": true,
    "social-media-tools@agentics-kit": true,
    "plan-agent@agentics-kit": true,
    "issue-agent@agentics-kit": true
  }
}
```

Field rules (easy to get wrong):

- `enabledPlugins` is an **object** (`"name@marketplace": true`), not an array.
- Every plugin key needs the **`@agentics-kit`** suffix — that's the marketplace
  `name` from `.claude-plugin/marketplace.json`.
- `extraKnownMarketplaces` is **plural**, and its source is
  `{ "source": "github", "repo": "owner/repo" }`.

## Scope: which `settings.json`?

| Scope | File | Effect | Committed? |
|-------|------|--------|------------|
| Project | `.claude/settings.json` (in this repo) | Auto-loads for any clone / web session of **agentics** | Yes — in git |
| User | `~/.claude/settings.json` | Auto-loads in **every repo** on your machine | No — personal |
| Local | `.claude/settings.local.json` | Personal overrides for one repo only | No — gitignored |

This repo uses **project scope**, already committed. Each teammate adds **user
scope** themselves for their other repos.

## Setup for team members

### Already done for this repo

Nothing to do for `agentics` itself — pull `main` and start a fresh session.
The 12 plugins activate automatically.

### Enable in all your other repos (per person)

1. Open (or create) `~/.claude/settings.json`.
2. **Merge** the two keys above into the existing top-level JSON object — don't
   overwrite the file. If you already have `enabledPlugins`, add these entries
   to it rather than replacing it.
3. Save and start a new session.

> Note for Claude Code on the web: a remote container's `~/.claude/` is
> ephemeral (wiped when the session ends), so user-scope settings must be set
> where your settings actually persist — your local desktop/CLI install, or your
> web environment's configured settings. Per-repo **project** settings (committed
> to the repo) are the reliable choice for web sessions.

## The plugins (agentics-kit)

| Plugin | What it does |
|--------|--------------|
| `memory-tools` | CLAUDE.md / project-memory auditing |
| `code-review` | Auto code review; `/code-review:fix-branch` |
| `plan-interview` | Stress-test plans via deep-grill interview |
| `wcag-compliance-reviewer` | WCAG accessibility review |
| `skill-reviewer` | Audit & optimize skill files |
| `code-testing-agent` | Test suggestion, review, tdd-fix / tdd-loop |
| `git-agent` | Branch / commit / PR / ship workflows |
| `product-plans` | Cross-functional review panel |
| `settings-sync` | Back up & restore Claude Code settings |
| `social-media-tools` | Generate shareable social cards from code |
| `plan-agent` | `/plan-agent:implementation-plan` workflow |
| `issue-agent` | Create GitHub / GitLab issues from any context |

## Caveats

- **Trust prompt:** `extraKnownMarketplaces` may ask you to trust the
  marketplace on first use in some clients. If a session doesn't auto-enable,
  the one-time fallback is `/plugin marketplace add shawn-sandy/agentics`.
- **Verify in a new session:** plugin enablement is read at session start, so
  confirm it in a fresh session — check that commands like `/git-agent:*` and
  `/plan-agent:*` appear and skills (memory-tools, code-review) activate.

## References

- Settings: <https://code.claude.com/docs/en/settings>
- Plugin marketplaces: <https://code.claude.com/docs/en/plugin-marketplaces>
- Discover & install plugins: <https://code.claude.com/docs/en/discover-plugins>
- Claude Code on the web: <https://code.claude.com/docs/en/claude-code-on-the-web>
