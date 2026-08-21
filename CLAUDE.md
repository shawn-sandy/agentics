# CLAUDE.md

Marketplace of Claude Code plugins. Sources live in `kit/plugins/<name>/`; the
marketplace **references** them by relative path — it does not embed them.

## Gotchas

- **`version` lives only in `.claude-plugin/marketplace.json`.** Adding a
  `version` to a relative-path `plugin.json` silently overrides the marketplace
  value. Bump it manually in the same PR that touches a plugin — a CI guard
  fails the PR if it does not exceed the base branch. Check locally:
  `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs`
  (the script reads `origin/${BASE_REF}` directly, so a stale remote-tracking
  ref compares against the wrong base)
- **Claude Desktop runs frozen claude.ai copies, not `~/.claude/plugins/cache/`.**
  It loads snapshots from `~/Library/Application Support/Claude/local-agent-mode-sessions/<a>/<b>/rpm/`,
  each stamped with the date claude.ai last pulled — so a newly shipped skill is
  invisible there while working fine in the terminal CLI, and
  `installed_plugins.json` (the CLI's view) agrees with the repo the whole time.
  A SessionStart hook warns when they drift; check by hand with
  `node scripts/check-claude-ai-sync.mjs`. The fix is on claude.ai, never here.
- **`docs/plans/archive/` is off-limits.** Never glob, grep, or read it unless
  the user names the path.
- **Two merge drivers auto-resolve conflicts** — `marketplace.json` keeps the
  higher semver, gallery `index.html` files union their cards. A SessionStart
  hook registers them automatically; run `scripts/setup-merge-driver.sh` by hand
  only outside Claude Code or with hooks off. Never hand-edit conflict markers
  in a generated `index.html` — an unresolved conflict there means the driver
  never registered.
- **Plugin homepage URLs point at the plugin directory,** not the repo root:
  `https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/<name>`
- `.claude/settings.json` validates `marketplace.json` after every Write/Edit.
- Requires Claude Code 1.0.33+.

## Commands

```bash
claude --plugin-dir ./kit/plugins/<name>   # load one plugin locally
node scripts/build-dist.mjs                # build dist/ (gitignored)
gh workflow run publish-dist.yml --repo shawn-sandy/agentics
```

```text
/plugin marketplace add shawn-sandy/agentics
/plugin install <name>@agentics-kit
```

## Git

Branch off `main` for every task — never extend a branch from a previous
session:

```bash
git fetch origin && git checkout -b <verb-target-YYYY-MM-DD> origin/main
```

Commit the plan file alongside plugin changes, however minor.

## Where things are

- `.claude/rules/` — authoring rules, auto-loaded when a read matches their scope:

  | Rule | Loads on |
  |------|----------|
  | `plugin-patterns` | `kit/plugins/**` |
  | `skill-authoring` | `kit/plugins/**/skills/**` |
  | `marketplace` | `kit/plugins/**`, `.claude-plugin/**` |
  | `testing` | `tests/**` |
  | `plan-hygiene` | `**/plans/**` |
  | `removed-plugins` | always (unscoped) |
- Per-plugin detail: README.md's generated Plugin Reference Table, then
  `kit/plugins/<name>/README.md`.
- `tests/fixtures/valid-plugin/` — the validation reference.
- Docs: <https://code.claude.com/docs/en/plugins-reference>
