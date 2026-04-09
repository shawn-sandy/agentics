# Changelog — git-agent

## v3.2.0 — Grant read permissions to pr-agent and ship

- `pr-agent`: add `Read, Grep, Glob` to `allowed-tools` (forward-looking
  permission grant — no current behavior change; enables future edits to
  read PR templates, changelogs, and release notes without a permission update)
- `ship`: same as above

## v3.1.0 — Add branch-agent skill

- New skill: `branch-agent` — creates a branch from `origin/<default>` with no upstream tracking ref and switches to it
- Accepts the branch name verbatim from `$ARGUMENTS`; stops cleanly if none provided
- Guards against detached HEAD, missing `origin` remote, and fetch failures
- Default branch detection follows the `pr-agent` pattern (`git symbolic-ref` → `git remote show` → `main`/`master` fallback)
- Uses `--no-track` on `git checkout -b` to prevent automatic upstream tracking

## v3.0.0 — Remove branching-agent skill

- **BREAKING CHANGE:** Removed the `branching-agent` skill. Users who relied
  on automated branch creation should fall back to `git checkout -b` or
  another plugin.
- The remaining skills (`commit-agent`, `pr-agent`, `ship`) are unchanged.

## v2.0.0 — Rename new-branch skill to branching-agent

- Skill renamed: `new-branch` → `branching-agent`
- Directory renamed: `skills/new-branch/` → `skills/branching-agent/`
- No behavior changes — activation, flow, and slug logic are unchanged

## v1.2.1 — Smarter branch slugs in new-branch

- `new-branch` now extracts the core subject from the user's argument and
  produces short, readable slugs (≤20 chars when possible) instead of
  mechanically slugifying the whole sentence
- Example: "start a feature for dark mode" → `dark-mode`
  (was `start-a-feature-for-dark-mode`)

## v1.2.0 — Add new-branch skill

- New skill: `new-branch` — fetches latest from `origin` and creates a branch from `origin/<default>` without switching to the default branch first
- Prompts for name (or extracts from user message) and type prefix, with a recommendation based on observed branch naming patterns in the repo
- Interactive confirmation when working tree is dirty; carries uncommitted changes forward when git allows it

## v1.1.0 — Add ship skill

- New skill: `ship` — chains commit + push + PR into a single flow
- Unified pre-flight checks before any mutations
- Pushes to existing PR if one already exists on the branch

## v1.0.0 — Initial release with commit-agent and pr-agent skills
