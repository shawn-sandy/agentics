# Changelog — git-agent

## v3.11.1 — 2026-07-11 — More descriptive, human-readable generated branch names

### Changed

- `branch-agent` skill: auto-generated branch descriptions are now verb-led
  phrases that read like commit subjects (e.g.
  `feat/add-login-form-validation`) instead of extracted keyword fragments.
  Whole words only — abbreviations to save space are prohibited; long names
  drop trailing words instead of chopping mid-word.
- Length budgets raised to make room for readable names: pre-suffix name
  ≤ 60 chars (was 49), final date-suffixed name ≤ 72 chars (was 60), and
  descriptive-phrase slugs (Case B) ≤ 60 chars (was 30).

## v3.11.0 — 2026-06-16 — Absorb create-issue skill from issue-agent plugin

### Added

- `create-issue` skill: drafts and creates GitHub/GitLab issues from four context sources (`bug`, `feature`, `selection`, `session`) with host auto-detection, a confirmation gate, and automatic browser open (`--no-open` to suppress). Moved from the now-retired `issue-agent` plugin.

### Changed

- **Breaking:** invocation namespace changed from `/issue-agent:create-issue …` to `/git-agent:create-issue …`. Update any scripts, docs, or muscle memory accordingly.

## v3.10.5 — 2026-06-05 — Use portable plugin-dir path in README

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/git-agent` path instead of an author-specific home directory.

---

## v3.10.2 — 2026-06-01 — Add ExitPlanMode error handling

### Fixed

- fix: add ExitPlanMode error handling — treat 'not in plan mode' error as success

## v3.10.1 — 2026-06-01 — Minor wording corrections

### Fixed

- `ship-autonomous` skill: minor description wording corrections.

---

## v3.10.0 — Auto-link plan issue references in PR descriptions

- PR creation now scans plan files changed on the branch for
  `<meta name="plan-issue">` tags and appends a `## Linked Issues` section
  with `Closes <url>` lines to the PR body, enabling GitHub/GitLab to
  auto-close referenced issues on merge.
- Added shared `scripts/extract-plan-issues.sh` for background agents;
  foreground skills use inline `git diff` + `Grep`.
- Applies to all PR creation paths: `pr-agent`, `agent-pr`, `ship`,
  `agent-ship`, and `ship-autonomous` (via delegation to `pr-agent`).

## v3.9.3 — Fix subagent_type namespace qualification in background commands

- `commit-bg`, `pr-bg`, and `ship-bg` now dispatch with fully-qualified
  `subagent_type` values so agents resolve correctly when the plugin is
  installed from the marketplace:
  - `commit-bg`: `agent-commit` → `git-agent:agent-commit`
  - `pr-bg`: `agent-pr` → `git-agent:agent-pr`
  - `ship-bg`: `agent-ship` → `git-agent:agent-ship`

## v3.9.2 — README: sync usage documentation; split provider-specific CLI requirements

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## v3.9.1 — branch-agent: auto-stash on checkout conflict

- `branch-agent` now detects tracked files that would conflict with
  `git checkout -b` before attempting the checkout (new Step 4.5). The
  conflict set is computed as the intersection of locally-modified tracked
  files and files that differ between `HEAD` and `origin/<default>`.
- When conflicts are detected, the skill automatically stashes, creates the
  branch, and pops the stash — recovering your uncommitted changes on the new
  branch. Untracked files are never stashed.
- On `git stash pop` failure (rare merge conflict), the skill stops with a
  clear recovery guide (`git stash list` / resolve / `git stash drop`); the
  stash is never auto-dropped.
- No behaviour change for clean or untracked-only working trees.

## v3.9.0 — ship-autonomous watches PRs via event subscription

- `ship-autonomous` now subscribes to the PR's activity events
  (`mcp__github__subscribe_pr_activity`) after opening the PR, replacing the
  synchronous `gh pr checks --watch` polling loop as the primary path. After
  subscribing it posts an initial status update and ends the turn; CI failures
  and review comments arrive as `<github-webhook-activity>` events that wake the
  session.
- Event handling (Step 6) now covers **review comments** in addition to CI
  failures: clear, in-scope review changes are applied, committed, pushed, and
  replied to; ambiguous or architecturally significant comments are escalated.
- Failures outside the safe allowlist (`lint`/`typecheck`/`peer-deps`) and
  ambiguous review comments now **ask the user via `AskUserQuestion`** rather
  than printing an escalation block and stopping. Autofix is capped at 3
  attempts **per check**.
- Posts **regular status updates** and refreshes a live TodoWrite checklist on
  every event so the thread reflects current state.
- Keeps the subscription active after CI goes green to handle later review
  comments; unsubscribes (`mcp__github__unsubscribe_pr_activity`) only when the
  PR merges/closes or the user asks to stop.
- **Fallback:** in environments without the GitHub MCP server (e.g. local
  Claude Code), the skill detects that `subscribe_pr_activity` is unavailable
  and falls back to the previous synchronous `gh pr checks --watch` polling
  with the same ≤3-attempt autofix, stopping once CI is green.
- Added `mcp__github__subscribe_pr_activity` and
  `mcp__github__unsubscribe_pr_activity` to `allowed-tools`; updated the skill
  description and README to describe the watch/autofix lifecycle.

## v3.8.0 — ship-autonomous moved into plugin

- New skill: `ship-autonomous` — supervised full pipeline (branch if on
  default, commit, open PR, poll CI, autofix lint/typecheck/peer-deps ≤3
  iterations, request review when green)
- Moved from project-level `.claude/skills/ship-autonomous/` into
  `kit/plugins/git-agent/skills/ship-autonomous/` so it ships with the plugin
  and is installable by marketplace users
- No behavior changes — content is identical to the project-level version
  (already had Step 0 `ExitPlanMode` and `ToolSearch`/`ExitPlanMode` in
  `allowed-tools` from the prior fix)
- Updated README with `ship-autonomous` in the Skills list, usage section, and
  Plugin Structure tree

## v3.7.1 — ExitPlanMode in agent-ship

- Added `ToolSearch` and `ExitPlanMode` to `agent-ship` tools list
- Added Step 0 to `agent-ship` workflow: calls `ExitPlanMode` unconditionally
  before any mutation, mirroring the pattern already in all four git-agent
  skills

## v3.7.0 — Disable model invocation on workflow skills

- `disable-model-invocation: true` on `commit-agent` — manual invocation only via `/git-agent:commit-agent`; no longer auto-triggers on intent match.
- `disable-model-invocation: true` on `pr-agent` — manual invocation only via `/git-agent:pr-agent`; no longer auto-triggers on intent match.
- `disable-model-invocation: true` on `ship` — manual invocation only via `/git-agent:ship`; no longer auto-triggers on intent match.

## v3.6.2 — Description cleanup and scope boundaries

- Collapsed `branch-agent` and `ship` skill descriptions from multi-line YAML blocks to single-line inline strings starting with "Use when..." for reliable auto-activation
- Added explicit "Does NOT..." scope clauses to `branch-agent` and `ship` descriptions
- Dropped implementation-detail tags (`subagents`, `background`, `slash-commands`) from marketplace entry; these describe internals rather than user search intent

## v3.6.1 — Conditional ExitPlanMode detection

- All four git-mutating skills (`branch-agent`, `commit-agent`, `pr-agent`,
  `ship`) now detect whether plan mode is active before calling
  `ExitPlanMode`, skipping the call when not in plan mode
- No behavioral change (ExitPlanMode was already a no-op outside plan mode)
  but instructions now explicitly model conditional detection and silent exit

## v3.6.0 — Slash commands for explicit background dispatch

- New `commands/` directory with three thin-wrapper slash commands that
  dispatch the v3.5.0 background agents with `run_in_background: true`:
  - `/git-agent:commit-bg [hint]` → dispatches `agent-commit`
  - `/git-agent:pr-bg [hint]` → dispatches `agent-pr`
  - `/git-agent:ship-bg [hint]` → dispatches `agent-ship`
- Each command accepts an optional hint argument that is passed to the agent
  as additional context for the commit message or PR summary
- Commands return control to the user immediately after dispatch — no
  waiting, no polling; the user is notified automatically on completion
- Updated `README.md` with a "Slash commands" section documenting invocation
  syntax and the example `/git-agent:ship-bg fix off-by-one in pagination`

## v3.5.0 — Background subagents for commit, pr, and ship

- New `agents/` directory with three background subagents that mirror the
  existing skills:
  - `agent-commit` — background version of `commit-agent`
  - `agent-pr` — background version of `pr-agent`
  - `agent-ship` — background version of `ship`
- Each agent uses `background: true` so the parent session can dispatch the
  work and keep going while the subagent runs to completion
- Existing skills (`branch-agent`, `commit-agent`, `pr-agent`, `ship`) are
  unchanged and remain the synchronous path
- `branch-agent` is intentionally **not** mirrored as an agent — branch
  creation is a synchronous setup step (you need to be on the new branch
  before continuing) and backgrounding it has no benefit
- Updated `README.md` with a "Background subagents" section, a skill-vs-agent
  decision table, trigger phrases for each agent, and a caveat about the
  working-tree snapshot timing tradeoff

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

## v3.3.3 — commit-agent, pr-agent, and ship now exit plan mode on entry

- Extends the v3.3.1 `branch-agent` pattern to the remaining three git-mutating
  skills: `commit-agent`, `pr-agent`, and `ship`
- Each skill now calls `ExitPlanMode` as its first step (Step 0) so it
  self-bootstraps out of plan mode before running any git mutations
- Added `ExitPlanMode` to each skill's `allowed-tools` to prevent mid-run
  permission prompts
- Updated `~/.claude/CLAUDE.md` global rule: callers no longer need to
  pre-check plan-mode state before invoking git-agent skills

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
