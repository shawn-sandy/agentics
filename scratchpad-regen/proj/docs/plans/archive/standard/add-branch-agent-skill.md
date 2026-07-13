# Plan: Add simple `branch-agent` skill to git-agent

## Context

The `git-agent` plugin previously shipped a `branching-agent` skill that was removed in v3.0.0 (breaking change). That skill was complex — it did slug generation, abbreviation mapping, branch-naming-pattern scanning, interactive type-prefix selection, and dirty-tree handling. The user wants a **simpler** replacement that just does the essential thing: create a branch from the default branch, switch to it, and ensure there is no upstream tracking ref to the parent branch (so `git push` won't accidentally target the default branch).

The load-bearing mechanism is a single git flag: `git checkout -b <name> --no-track origin/<default>`. The `--no-track` flag is exactly what prevents the upstream connection from being set. No separate "remove upstream" step is needed.

This is a **new non-breaking skill addition** to git-agent → minor version bump (3.0.0 → 3.1.0).

## Objective

Add a simple `branch-agent` skill to the `git-agent` plugin that creates a branch from the default branch, switches to it, and leaves it with no upstream tracking ref. Naming follows the existing sibling-skill convention (`commit-agent`, `pr-agent`).

## Steps

1. **Create the skill file** at [kit/plugins/git-agent/skills/branch-agent/SKILL.md](kit/plugins/git-agent/skills/branch-agent/SKILL.md).
   - *Why:* Skills live under `skills/<name>/SKILL.md` per the plugin structure convention.
   - Frontmatter: `name: branch-agent`, `allowed-tools: Bash(git *)` (mirroring `commit-agent`).
   - Drafted `description` for activation matching:

     ```
     description: Use when the user asks to create a new branch, start a branch, branch off main, make a fresh branch, or branch from the default. Creates the branch from origin/<default> with no upstream tracking. Does not commit, push, or create PRs — use commit-agent or pr-agent for that.
     ```

   - The "Does not X — use Y for that" disambiguation mirrors `commit-agent` and `pr-agent`, preventing activation overlap with sibling skills.
   - Body follows the existing strict-order / hard-STOP pattern seen in `commit-agent`, `pr-agent`, and `ship`.

2. **Skill body — Step 1: Guards.**
   - Run `git rev-parse --is-inside-work-tree` — if not a repo, STOP.
   - Run `git branch --show-current` — if empty, STOP with detached-HEAD error.
   - Run `git remote get-url origin` — if it fails, STOP with `branch-agent requires a remote named 'origin'.` (Avoids confusing failures later in default-branch detection or fetch.)
   - *Why:* Matches the guard style used in `commit-agent` Step 1 and `pr-agent` Step 1, and adds an explicit no-`origin` guard surfaced during plan interview.

3. **Skill body — Step 2: Resolve branch name from `$ARGUMENTS`.**
   - If `$ARGUMENTS` provides a usable branch name, use it verbatim (no slug transformation — keeping it simple).
   - If `$ARGUMENTS` is empty or ambiguous, STOP with a message asking the user to supply a branch name.
   - *Why:* The old `branching-agent` did heavy slug generation and interactive prompting. The user explicitly asked for something simpler — pass through what the user typed.

4. **Skill body — Step 3: Detect default branch.**
   - Run `git symbolic-ref refs/remotes/origin/HEAD --short 2>/dev/null` and strip `origin/` prefix.
   - Fallback: `git remote show origin | grep 'HEAD branch'`.
   - Final fallback: try `main`, then `master`, via `git rev-parse --verify --quiet`.
   - If none resolve, STOP and report the git error verbatim.
   - *Why:* This mirrors the detection logic in `pr-agent` Step 2, which is the canonical pattern in this plugin.

5. **Skill body — Step 4: Fetch latest from origin.**
   - Run `git fetch origin <default>`.
   - **On failure** (offline, network error, auth required for private remote): report the git error verbatim and STOP. Do not proceed with a stale ref.
   - *Why:* Creating from `origin/<default>` without fetching first would use a stale remote ref. Fetching only the default branch (not `--all`) keeps the operation fast and scoped. Failing loud rather than silent prevents the user from accidentally branching from yesterday's `main`.

6. **Skill body — Step 5: Create branch with no upstream tracking.**
   - Run: `git checkout -b <branch> --no-track origin/<default>`
   - *Why:* This is the single critical command. `--no-track` is what removes any connection to the parent branch — without it, the new branch would silently get `origin/<default>` as its upstream.
   - On failure (e.g. branch already exists, dirty-tree conflict), report the git error verbatim and STOP. Do not retry, do not force.

7. **Skill body — Step 6: Confirm and STOP.**
   - Run `git rev-parse --short HEAD` to get the short SHA.
   - Output one line: `Created and checked out <branch> from origin/<default> @ <sha> (no upstream tracking)`.
   - Terminal horizontal rule + `**STOP here. Do not stage, commit, push, or take any further action.**`
   - *Why:* Matches the terminal-STOP convention used by all three existing skills, preventing scope creep.

8. **Update [kit/plugins/git-agent/README.md](kit/plugins/git-agent/README.md).**
   - Add `branch-agent` to the Features list.
   - Add a Usage section with sample activation phrases and the step summary.
   - Add `skills/branch-agent/SKILL.md` to the Plugin Structure tree.
   - *Why:* The plugin-patterns rules require README to document each component with activation syntax.

9. **Update [kit/plugins/git-agent/CHANGELOG.md](kit/plugins/git-agent/CHANGELOG.md).**
   - Prepend entry: `## v3.1.0 — Add branch-agent skill` with a short bullet list.
   - *Why:* Project convention — every version bump requires a changelog entry, newest-first.

10. **Bump version and refresh metadata in [.claude-plugin/marketplace.json](.claude-plugin/marketplace.json).**
    - Change the `git-agent` entry `version` from `3.0.0` → `3.1.0`.
    - Update the `git-agent` entry `description` to reflect the new skill, e.g. `Automated git workflow — create branches, commit with conventional messages, and create PRs`.
    - Add `"branch"` and `"checkout"` to the `git-agent` entry `tags` array.
    - Do NOT bump the marketplace top-level `version` field — git history confirms the convention is to bump only the per-plugin entry version on plugin changes.
    - *Why:* Per project rules, version for relative-path plugins lives only in `marketplace.json`, not `plugin.json`. New non-breaking skill = MINOR bump. Description and tags drift will cause the plugin to be undiscoverable for branch-related searches.

11. **Update [kit/plugins/git-agent/.claude-plugin/plugin.json](kit/plugins/git-agent/.claude-plugin/plugin.json).**
    - Update the `description` field to mirror the new marketplace description.
    - Add `"branch"` and `"checkout"` to the `keywords` array.
    - Do NOT add a `version` field to `plugin.json` — for relative-path plugins, version lives only in `marketplace.json`.
    - *Why:* `plugin.json` is the canonical manifest read when the plugin is loaded directly via `--plugin-dir`. Keeping its description and keywords aligned with `marketplace.json` prevents drift between the two installation paths.

12. **Rename the plan file** from `docs/plans/dazzling-zooming-pizza.md` → `docs/plans/add-branch-agent-skill.md` using `git mv` (preserves history).
    - *Why:* Plan-hygiene rule (`.claude/rules/plan-hygiene.md`) requires descriptive filenames before commit. The current filename is the random auto-generated name from plan-mode initialization. This step must run before the implementation commit so the renamed file is what gets committed.

## Critical Files

| File | Action |
| --- | --- |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | **Create** |
| `kit/plugins/git-agent/README.md` | **Edit** — Features + Usage + Plugin Structure |
| `kit/plugins/git-agent/CHANGELOG.md` | **Edit** — prepend v3.1.0 entry |
| `.claude-plugin/marketplace.json` | **Edit** — bump git-agent version, refresh description, add `branch`/`checkout` tags |
| `kit/plugins/git-agent/.claude-plugin/plugin.json` | **Edit** — refresh description, add `branch`/`checkout` keywords |
| `docs/plans/dazzling-zooming-pizza.md` | **Rename** → `docs/plans/add-branch-agent-skill.md` |

## Existing Patterns Reused

- **Guard style** → [kit/plugins/git-agent/skills/commit-agent/SKILL.md:9-14](kit/plugins/git-agent/skills/commit-agent/SKILL.md#L9-L14)
- **Default branch detection** → [kit/plugins/git-agent/skills/pr-agent/SKILL.md](kit/plugins/git-agent/skills/pr-agent/SKILL.md) Step 2 pattern
- **Strict-order / STOP-after-step-N structure** → all three existing skills
- **`allowed-tools: Bash(git *)` scoping** → [kit/plugins/git-agent/skills/commit-agent/SKILL.md:4](kit/plugins/git-agent/skills/commit-agent/SKILL.md#L4)

## Verification

1. **Syntactic validation:** After editing `marketplace.json`, the project's auto-validator hook (configured in `.claude/settings.json`) will verify JSON syntax on save.

2. **Load the plugin locally:**

   ```bash
   claude --plugin-dir ~/devbox/agentics/kit/plugins/git-agent
   ```

3. **Trigger the skill** in a test repo by saying something like "create a new branch called test-feature" and confirm:
   - The skill activates on that phrasing.
   - A new branch is created from `origin/main`.
   - `git branch -vv` shows the new branch with **no** upstream tracking ref (no `[origin/main]` annotation).
   - `git rev-parse --abbrev-ref --symbolic-full-name @{u}` returns an error (no upstream), confirming the connection was never set.

4. **Install via marketplace** to confirm the version bump is picked up:

   ```bash
   /plugin marketplace add ~/devbox/agentics
   /plugin install git-agent@agentics-kit
   ```

5. **README rendering check:** Open the updated `README.md` and confirm the new skill section renders cleanly and the Plugin Structure tree still matches the actual directory layout.

## Next Steps (out of scope)

- Interactive branch-name suggestion based on repo naming conventions (was in the removed `branching-agent`).
- Automatic slug generation from free-text user input.
- Dirty-tree handling with stash/carry-forward prompts.
- Support for creating from branches other than the default.

## Resolved Decisions

- **Skill name:** `branch-agent` — matches the existing `commit-agent` / `pr-agent` naming convention in the same plugin.
- **Branch name source:** `$ARGUMENTS` only. If empty or missing, the skill STOPs with a clear instruction asking the user to re-invoke with a name. No `AskUserQuestion` interaction → keeps `allowed-tools` scoped to `Bash(git *)` only.
- **Fetch behavior:** Scoped fetch — `git fetch origin <default>` — to refresh only the default branch ref, not all remotes.
- **Default-branch guard:** No guard. Being on the default branch when invoking the skill is fine; `git checkout -b ... --no-track origin/<default>` works regardless of the current branch.
- **Default-branch detection:** Use the `pr-agent` pattern (`git symbolic-ref` → `git remote show origin` → `main`/`master` fallback). Confirmed during interview — user wants the skill to detect the default branch, not be strict about failing on unusual configurations.
- **Dirty working tree:** Let `git checkout -b` fail naturally and report verbatim. No pre-flight `git status` check, no auto-stash.
- **Branch name collision:** Let `git checkout -b` fail naturally and report verbatim. No pre-flight `git rev-parse --verify` check, no auto-suffixing.
- **Branch name validation:** None. Trust the user; let git enforce its own naming rules.
- **`git fetch` failure:** STOP and report verbatim. Do not branch from a stale ref.
- **No `origin` remote:** STOP in Step 1 guards with a clear error message.
- **Marketplace top-level version:** NOT bumped. Per git history, top-level marketplace version is independent of per-plugin bumps.

## Interview Summary

Stress-tested via `/plan-interview:plan-interview` before implementation.

### Confirmed during interview

| Question | Decision |
| --- | --- |
| Default branch detection strictness | Use `pr-agent` pattern with `main`/`master` fallback |
| Dirty working tree handling | Let git fail naturally — no pre-flight check, no stash |
| Name collision handling | Let git fail naturally — no pre-flight check, no auto-suffix |
| Branch name validation | None — trust user, let git enforce its rules |

### Out-of-scope concerns surfaced and incorporated into plan

1. **`git fetch` failure path** — added explicit STOP-on-failure in Step 4.
2. **No-`origin` remote case** — added Step 1 guard via `git remote get-url origin`.
3. **`marketplace.json` description/tags drift** — Step 10 expanded to refresh description and add `branch`/`checkout` tags.
4. **`plugin.json` description/keywords drift** — added new Step 11 to mirror marketplace metadata.
5. **Activation `description` wording undrafted** — concrete draft added inline to Step 1, with sibling-disambiguation pattern.
6. **Plan filename rename informal** — added new Step 12 to rename via `git mv` before commit.

### Complexity check

No complexity concerns. The plan is intentionally simple, the user confirmed maximum simplicity in all four interview answers, and the load-bearing mechanism is a single git flag (`--no-track`). Six skill steps is consistent with existing sibling skills (`commit-agent` 4, `pr-agent` 5, `ship` 8).

### Plan name validation

| Element | Current | Issue | Resolution |
| --- | --- | --- | --- |
| Filename | `dazzling-zooming-pizza.md` | Random adjective-verb-noun pattern unrelated to content | Renamed to `add-branch-agent-skill.md` as Step 12 (deferred from plan-mode due to write restriction) |
| H1 Heading | `# Plan: Add simple branch-agent skill to git-agent` | None — descriptive and aligned | No change |
