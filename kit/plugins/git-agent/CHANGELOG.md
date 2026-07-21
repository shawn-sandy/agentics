# Changelog — git-agent

## v4.4.0 — 2026-07-20 — background CI watcher

### Added

- **`agents/agent-ship-ci.md`** — a background subagent that watches an already-open PR's checks, applies at most one deterministic autofix per failing check, and reports. It is the unattended, truncated half of the `ship-autonomous` skill, not a background wrapper around it.
- **`commands/ship-ci-bg.md`** — `/git-agent:ship-ci-bg [pr]` dispatches it and returns control immediately.
- `tests/plugins/test-ship-ci-agent.sh` — 16 checks covering the deny-list invariant, the never-merge / never-review / never-ready guarantees, the existing-PR precondition, the one-attempt autofix cap, the lockfile-only revert, and the bounded `--watch`.

### Why it is not `ship-autonomous` in a subagent

`ship-autonomous` is built around `mcp__github__subscribe_pr_activity`: Step 5 ends the turn and the session is woken by PR webhooks. A subagent runs once to completion and can never be re-woken, so wrapping the skill would silently downgrade it to the polling fallback. Its escalation points — unrecognized CI failure, ambiguous review comment, `CHANGES_REQUESTED`, and the merge gate — are all `AskUserQuestion`, and a subagent has no user to ask. `agent-ship-ci` therefore drops every step that needs a human instead of guessing at it: it never merges, never marks a draft ready, never deletes a branch, and never replies to, resolves, or dismisses a review. It reports and stops; the merge decision stays with the parent session.

### Autofix scope and the deny-list invariant

Background git agents have denied `Write`/`Edit`/`NotebookEdit` since v3.5.0, and `tests/plugins/test-ship-self-review.sh` asserts that across every `agents/agent-*.md`. `agent-ship-ci` upholds it. That splits the `ship-autonomous` autofix allowlist in two:

- **Applied** — `lint` (only via a `--fix` script the project already defines) and `peer-deps` (lockfile reinstall, with the diff verified lockfile-only and reverted if it is not). These are the project's own tooling rewriting its own output via `Bash`, not model-authored edits.
- **Reported only** — `typecheck`, test failures, and everything unrecognized. Their fixes are source edits, which an unattended agent must not author.

One attempt per check, not three: these fixers are deterministic, so a second identical run cannot succeed where the first failed. `gh pr checks --watch` is bounded by the **Bash tool's own `timeout` parameter** (540s) and looped at most 5 times (~45 min) so a long CI run cannot exceed a single command timeout. It deliberately does not shell out to `timeout` — that is GNU coreutils and absent on stock macOS, where `timeout 540 gh ...` fails with `command not found` and the watch never runs. This was caught live on macOS while shipping the agent's own PR.

Throttled external review bots (CodeRabbit and similar report a red check when merely rate-limited, with an empty `workflow` and `link`) are classified `bot-infra` and are report-only. There is no defect to fix, and pushing a commit to clear one just burns another CI round. Also caught live on the agent's own PR.

---

## v4.3.0 — 2026-07-20 — ship self-reviews the diff before pushing

### Added

- **Step 4.5 (Self-Review Before Push)** in `skills/ship/SKILL.md` and `agents/agent-ship.md` — diffs the whole branch against its base and critiques it as a hostile reviewer before Step 5 pushes. Checks four regression classes that CI review bots repeatedly caught after the fact: dropped accessibility attributes, double-escaping in generated output, string parsing/truncation edge cases, and responsive/desktop layout regressions. Findings are fixed and folded into the Step 4 commit via `git commit --amend --no-edit`; the check re-runs once, never loops, and never blocks the ship.
  - `ship` (foreground): on by default — pass `--no-review` to skip.
  - `agent-ship` (background): always runs, and is **report-only** — it never edits files. Background git agents have denied `Write`/`Edit`/`NotebookEdit` since v3.5.0 so an unattended agent cannot rewrite source, and Step 4.5 upholds that rather than weakening it. Every finding is surfaced in the report returned to the parent session, so nothing ships silently; acting on a finding is the parent session's call. The step also explicitly forbids routing around the deny list via `Bash` (`sed -i`, heredoc rewrites, `git apply`).
- `tests/plugins/test-ship-self-review.sh` — 22 checks covering step ordering, the four regression classes, the non-blocking guarantee, the fix-vs-report asymmetry between skill and agent, and the deny-list invariant across all three `git-agent` background agents.

### Changed

- `skills/ship/SKILL.md`: `allowed-tools` gains `Edit` so self-review findings can be fixed in place. This is safe in the foreground, where the user sees the edits before the push.
- `agents/agent-ship.md`: the Step 8 close-out now reports self-review findings alongside the PR/MR URL. `tools` is deliberately unchanged — adding `Edit` there would have been inert (`disallowedTools` overrides it) and misleading.

---

## v4.2.0 — 2026-07-20 — Test Plan in PR bodies, lint gate, refuted-finding replies

### Added

- **`## Test Plan` section in PR bodies** (`pr-agent`, `ship`) — a checklist of the commands a reviewer runs to verify the change. Boxes may only be checked for work actually verified in-session; an unchecked box is honest, a false checkmark is not.
- **Lint gate in `ship-autonomous` Step 2.5** — runs the project's first non-`fix`, non-`watch` `lint*` script alongside the test suite and stops on failure, catching lint locally instead of a full CI round-trip later in Step 6b. No auto-`--fix` at this stage: the user has not seen the diff yet.
- **Refuted-finding path in `ship-autonomous` §6c** — a review comment that misreads the code, describes stale state, or repeats a declined finding is answered with one short reply on the thread and resolved, not silenced with a no-op commit. A repeat of the same refuted finding is skipped silently. When the finding arrived as a formal `CHANGES_REQUESTED` review, replying and resolving does **not** clear the review decision that Step 8 blocks on, so that case escalates via `AskUserQuestion` (dismiss the review, or request a re-review) instead of being marked handled — never merged around.

---

## v4.1.1 — 2026-07-16 — Trim ship-autonomous description to budget

### Fixed

- `skills/ship-autonomous/SKILL.md`: description reduced from 214 chars to within the 200-char budget, so it no longer trips `/skill-reviewer:check-description`.

---

## v4.1.0 — 2026-07-16 — ship-autonomous verifies before committing and gates the merge

### Added

- **Step 2.5 (Verify)** — runs the project's `test*` script before committing and stops on failure rather than shipping a red tree. When the change is observable in a browser, previews it via `.claude/launch.json`, checks console and server logs, and screenshots both light and dark themes.
- **Step 8 (Merge)** — re-confirms every check is green immediately before merging, re-fetches the live review decision and unresolved-thread count (an approval or change request may have landed since the last event), then gates the merge itself behind `AskUserQuestion`. The merge pins `--match-head-commit <headRefOid>` so commits arriving after verification cause the merge to fail rather than silently land unreviewed. Branch deletion requires a **separate** explicit approval: a merge approval never authorizes `--delete-branch`.
- Closing policy note: a re-fired bot review on an already-approved PR is not new information — after one substantive fix pass, only merge-blocking findings are actioned.

### Changed

- `allowed-tools` gained the `mcp__Claude_Browser__*` preview tools used by Step 2.5.

### Fixed

- **Step 5 fallback polling was broken (pre-existing, since v3.x).** `gh pr checks --json name,state,conclusion,workflowName` errors out with `Unknown JSON field` — `gh pr checks` exposes `state`/`workflow`, not `conclusion`/`workflowName` (those belong to `gh run list`). Local runs without the GitHub MCP server could never read CI status. Now queries `name,state,workflow,link` and reads `state`. Prose in Steps 5 and 7 updated from "conclusions" to "states".
- Step 8's green re-check used the same invalid `conclusion` field; corrected to `name,state,link`.
- Step 8 suggested `gh pr branch-delete`, which is not a `gh` subcommand — cleanup would have failed after an otherwise successful merge. Replaced with `git push origin --delete <branch>` and an optional local `git branch -d`.
- Step 2.5's test-script selector matched `^test`, so a `test:watch` or `test:dev` script could be selected and hang the pipeline forever. Now prefers the exact `test` script and excludes persistent variants (`watch`, `dev`, `ui`, `serve`) when falling back.
- Step 2.5's browser preview checked console and server logs but only treated theme breakage as blocking; console/server errors now block and must be fixed and re-checked before the pipeline continues.
- README described the local fallback as stopping once CI is green, contradicting Step 8, which routes fallback mode through merge approval. Corrected.

## v4.0.1 — 2026-07-13 — Per-skill model pinning

### Changed

- Model frontmatter tuned to match each component's job: `branch-agent` fixed from `Haiku` to the documented lowercase `haiku` alias; `commit-agent` and the `agent-commit` background agent pinned to `haiku` (rigid conventional-commit format, high frequency); `pr-agent` and `create-issue` pinned to `sonnet` (outward-facing prose, matching `agent-pr`). `ship` and `ship-autonomous` deliberately inherit the session model — ship-autonomous's CI autofix step applies real code edits and should never run on a downgraded model. Overrides are turn-scoped and fall back to the session model if excluded by an org `availableModels` allowlist.

## v4.0.0 — 2026-07-13 — create-issue auto-activates on intent match

### Changed

- **Breaking (activation behavior):** removed `disable-model-invocation: true` from the `create-issue` skill — it now auto-activates when user intent matches (e.g. "file a bug", "open an issue", "create a feature ticket") in addition to explicit `/git-agent:create-issue` invocation. The confirmation gate before issue creation is unchanged.
- `create-issue` Phase 3 documents both activation paths: on ambient model invocation `$ARGUMENTS` is empty, so the source keyword and title are derived from the triggering message and recent conversation before falling back to `AskUserQuestion`.

## v3.12.0 — 2026-07-13 — create-issue accepts plan files as a source

### Added

- `create-issue` skill: new `plan` source — pass a plan file path (`.md` spec or rendered `.html`; a bare `.md`/`.html` token implies the source without the keyword) and the skill maps the plan's title, Objective, Steps (as a `- [ ]` checklist), and Acceptance Criteria into a structured issue body via the new `references/plan-issue.md` template. Labels are suggested from the plan's `type:` frontmatter. The issue body cites the plan path so the ticket links back to its plan.

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
