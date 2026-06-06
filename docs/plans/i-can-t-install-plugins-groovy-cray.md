# Plan: Auto-load agentics-kit plugins in web sessions

## Context

In Claude Code on the web, `/plugin install` is a client-side, interactive
command that cannot be run from inside an agent session — so plugins from this
repo's own marketplace never load automatically in a fresh web-session clone.
The original idea was a **SessionStart hook** to load them, but research against
the official docs confirms a shell hook **cannot** install or enable plugins:
there is no `claude plugin install` CLI subcommand, and plugin state is purely a
settings/client concern.

The supported, declarative mechanism is two keys in the committed
`.claude/settings.json`:

- `extraKnownMarketplaces` — registers this repo's marketplace without the
  interactive `/plugin marketplace add` step.
- `enabledPlugins` — auto-enables named plugins (object form,
  `"name@marketplace": true`).

Because web sessions are fresh clones that read the repo's `.claude/settings.json`
on startup, committing these keys to the branch makes the full kit auto-load in
all future sessions. The user chose to enable **all 12** marketplace plugins,
and to apply the config at **both** scopes (this repo + global user settings).

Note: settings config (`enabledPlugins` / `extraKnownMarketplaces`) is **not**
read from `CLAUDE.md` — that file is natural-language memory only. Plugin
enablement must live in a `settings.json` file.

## Outcome

After this change, future Claude Code web sessions on `shawn-sandy/agentics`
will start with all 12 `agentics-kit` plugins enabled — no manual install. The
user will also receive a snippet to enable the same kit globally across all
their repos via user-scope settings.

## Scope: both project and user settings

The user chose **Both** — commit the config to this repo's project settings now,
and provide a copy-paste snippet for global user settings.

- **Project (this repo)** — edit and commit `.claude/settings.json` on the
  branch. This is the only file changed in the repo. Works for fresh clones /
  web sessions of `agentics`.
- **User (all repos)** — `~/.claude/settings.json`. This cannot be reliably
  edited from this ephemeral web container (its home dir is wiped at session
  end), so it will be delivered to the user as a snippet to paste into their
  local/global user settings on their own machine. Same two keys
  (`extraKnownMarketplaces` + `enabledPlugins`) as below.

## Files to modify

### `.claude/settings.json` (only file changed in the repo)

Merge two new top-level keys alongside the existing `permissions`,
`plansDirectory`, and `hooks` blocks. **Do not touch the existing SessionStart
merge-driver hook or the PostToolUse hooks** — they stay exactly as-is.

Add:

```json
"extraKnownMarketplaces": {
    "agentics-kit": {
        "source": {
            "source": "github",
            "repo": "shawn-sandy/agentics"
        }
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
```

Notes:
- Marketplace name `agentics-kit` matches `.claude-plugin/marketplace.json`'s
  `name` field and the install command documented in CLAUDE.md
  (`/plugin install <plugin>@agentics-kit`).
- `enabledPlugins` must be an **object** (`"name@mkt": true`), not an array.
- The 12 plugin names are taken verbatim from `.claude-plugin/marketplace.json`.

## Why settings (not a hook)

| Approach | Works? | Why |
|----------|--------|-----|
| SessionStart hook running an install command | ❌ | No non-interactive CLI to install/enable plugins |
| `extraKnownMarketplaces` + `enabledPlugins` in committed `.claude/settings.json` | ✅ | Read on session start from the repo clone; documented mechanism |

The existing SessionStart hook (merge-driver setup) is unrelated and is left
untouched.

## Verification

1. **JSON validity** — the repo's own PostToolUse hook validates
   `marketplace.json`; for `settings.json` run `jq empty .claude/settings.json`
   and confirm no error. Optionally validate against the settings schema.
2. **Field correctness** — confirm `enabledPlugins` is an object, all 12 keys
   carry the `@agentics-kit` suffix, and each name exists in
   `.claude-plugin/marketplace.json` (grep/compare).
3. **End-to-end** — the authoritative check is starting a **new** web session on
   this branch (or after merge to `main`) and confirming the 12 plugins'
   commands/skills are available (e.g. `/git-agent:*`, `/plan-agent:*` appear,
   memory-tools/code-review skills activate). This can only be fully observed in
   a fresh session, not the current one.

## Commit & push

- Branch: `claude/plugin-auto-load-hook-QZHpQ` (already checked out).
- Commit message (single settings file, no plugin/marketplace version bump
  needed since no plugin source changed):
  `chore: auto-enable agentics-kit plugins via settings for web sessions`
- Push with `git push -u origin claude/plugin-auto-load-hook-QZHpQ`.
- No PR unless the user asks.

## Caveat to surface to the user

`extraKnownMarketplaces` is documented primarily for managed/team settings and
may prompt for marketplace trust on first use in some clients. If a future
session does not auto-enable, the fallback remains the one-time
`/plugin marketplace add shawn-sandy/agentics`. This will be confirmable only by
starting a fresh session after merge.
