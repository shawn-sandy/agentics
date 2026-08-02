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
- **`docs/plans/archive/` is off-limits.** Never glob, grep, or read it unless
  the user names the path.
- **Two merge drivers auto-resolve conflicts** — `marketplace.json` keeps the
  higher semver, gallery `index.html` files union their cards. Run
  `scripts/setup-merge-driver.sh` once per clone. Never hand-edit conflict
  markers in a generated `index.html`.
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

- `.claude/rules/` — scoped authoring rules, auto-loaded by path:
  `plugin-patterns` (`kit/plugins/**`), `skill-authoring`
  (`**/skills/**`), `marketplace`, `testing` (`tests/**`), `plan-hygiene`
  (`**/plans/**`), `removed-plugins` (always).
- Per-plugin detail: README.md's generated Plugin Reference Table, then
  `kit/plugins/<name>/README.md`.
- `tests/fixtures/valid-plugin/` — the validation reference.
- Docs: <https://code.claude.com/docs/en/plugins-reference>
