# Changelog — git-agent

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
