# Changelog — git-agent

## v3.4.0 — branch-agent always appends date suffix

- `branch-agent` now appends a `-YYYY-MM-DD` suffix (today's date) to every
  branch it creates, regardless of whether the name came from `$ARGUMENTS`,
  was slugified from a phrase, or was auto-generated from working-tree changes
- Added `Bash(date *)` to the skill's `allowed-tools` so the `date +%Y-%m-%d`
  call does not trigger a mid-run permission prompt
- Auto-generated branch names now cap at 49 characters (down from 60) to
  reserve room for the 11-character date suffix; the final branch name still
  stays under 60 chars
- Example: `feat/login-fix` → `feat/login-fix-2026-04-17`

## v3.3.2 — pr-agent no longer stops on merged PRs

- `pr-agent` Step 3 now checks `state` when inspecting an existing PR;
  only stops for `state: OPEN` — merged and closed PRs no longer block
  new PR creation

## v3.3.1 — branch-agent always exits plan mode on entry

- `branch-agent` now calls `ExitPlanMode` as its first step (Step 0) so it
  can self-bootstrap out of plan mode before running any git mutations
- Added `ExitPlanMode` to the skill's `allowed-tools` list to prevent
  mid-run permission prompts

## v3.3.0 — Auto-detect branch names from working tree changes

- `branch-agent` now auto-generates a branch name when invoked with no
  argument **and** the working tree has uncommitted changes
- Generated names follow the conventional `<type>/<scope>-<description>`
  format, mirroring the type vocabulary used by `commit-agent`
  (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `style`,
  `ci`, `build`)
- Type is inferred from the changed file paths and diff (markdown-only →
  `docs`, tests-only → `test`, CI-only → `ci`, build manifests → `build`,
  pure renames → `refactor`, etc.); scope is the most-changed top-level
  directory and is omitted when changes span more than two top-level dirs
- Total branch name length capped at 60 characters with word-boundary
  truncation; falls back to `chore/auto-branch` if validation fails
- Empty argument with a clean working tree still errors as before; explicit
  branch names are still used verbatim with no transformation; descriptive
  phrases continue to be auto-slugified per v3.2.0 behavior

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
