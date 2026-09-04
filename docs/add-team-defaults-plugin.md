# Add team-defaults plugin

> A new marketplace plugin that bundles the team's shared Claude Code agents and global rules, distributable via `/plugin install team-defaults@agentics-kit`.

<!-- generated:start -->

**Status:** Shipped 2026-08-03 **Plan:** [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
**Type:** feature

## What shipped

- Created `kit/plugins/team-defaults/` carrying two shared agents (`ts-commenter`, `css-generator`) and four global rules (`plan-mode.md`, `component-driven-ui.md`, `typescript-jsdoc.md`, `review-bot-loops.md`) plus `reference/SKELETON.md` — project-specific content (`ticket-creator.md`) excluded.
- Rewrote the `plan-mode.md` hook reference so the bundled copy no longer points at a machine-local `~/.claude/hooks/validate-plan-filename.py` path; instead it notes that the hook ships with `plan-agent`.
- Authored a `sync-rules` skill that diffs each source file against the destination, reports a sync plan, asks per-file confirmation on conflicts, copies approved files, and re-runs `diff -q` to verify each copy before reporting success.
- Registered `team-defaults` at v0.1.0 in `.claude-plugin/marketplace.json` (category `productivity`).
- Extended `tests/publish/smoke-clean-dist.sh` to assert that `dist/kit/plugins/team-defaults` is produced by the build, proving the plugin is registered and distributable.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/team-defaults/.claude-plugin/plugin.json` | Plugin manifest — name, description, keywords, homepage; no version key | Created |
| `kit/plugins/team-defaults/skills/sync-rules/SKILL.md` | Skill instructions — diff-first sync workflow with per-file confirmation and copy verification | Created |
| `kit/plugins/team-defaults/README.md` | Plugin documentation — overview, features, installation, usage | Created |
| `kit/plugins/team-defaults/CHANGELOG.md` | Release history — v0.1.0 initial entry | Created |
| `tests/publish/smoke-clean-dist.sh` | Publish smoke test — extended to include team-defaults in the plugin roster check | Modified |

## How it works

The `team-defaults` plugin bundles the shared Claude Code configuration that the whole team should use — agents and global rules that belong in every developer's `~/.claude/` folder. Distributing them as a marketplace plugin rather than hand-copying dotfiles means they are versioned in git, installable with a single command, and updatable via the standard plugin mechanism.

The plugin's `agents/` directory ships two agents: `ts-commenter` for annotating TypeScript code and `css-generator` for producing CSS from a description. The `rules/` directory ships four rule files — `plan-mode.md` (the plan-mode workflow with frontmatter and naming conventions), `component-driven-ui.md` (scoped to JS-framework files), `typescript-jsdoc.md` (scoped to TS/JS files), and `review-bot-loops.md` (a guard against automated review-bot iteration loops) — plus `reference/SKELETON.md`, the starter skeleton for new plan files. The project-specific `ticket-creator.md` agent was deliberately excluded because it references an Astro Basics project and has no meaning on other machines.

The `plan-mode.md` bundled here was rewritten before shipping: the original copy referenced `~/.claude/hooks/validate-plan-filename.py`, a path that only exists on the machine that authored it. The bundled copy instead notes that this hook ships with the `plan-agent` plugin. The `sync-rules` skill surfaces this to the user if `plan-agent` is not installed.

The `sync-rules` skill follows a diff-first workflow to protect the user's existing `~/.claude/rules/` content. For each file it first checks whether the destination is missing, identical, or in conflict with the source. Only after presenting a sync plan as a table does it proceed to copy — and conflicts require explicit per-file confirmation via `AskUserQuestion` before any overwrite. After copying, the skill re-runs `diff -q` source-vs-destination for every file it touched. Any mismatch or missing destination file halts with a named failure rather than a false success report. Files the plugin does not ship are never touched.

Registration in `.claude-plugin/marketplace.json` follows the repo convention: a `git-subdir` source pointing at `kit/plugins/team-defaults`, category `productivity`, and no `version` key in `plugin.json` (the version lives only in the marketplace manifest). The smoke test extension asserts that `node scripts/build-dist.mjs` produces `dist/kit/plugins/team-defaults`, which proves the plugin entry is valid and the path resolves.

## How to use it

**Install the plugin:**

```bash
/plugin marketplace add shawn-sandy/agentics
/plugin install team-defaults@agentics-kit
```

**Sync team rules to your machine:**

```
sync team rules
```

or:

```
/team-defaults:sync-rules
```

The skill reports a table of new / up-to-date / conflicted files and asks confirmation before overwriting any file that differs from your local copy.

**Load locally for development:**

```bash
claude --plugin-dir ./kit/plugins/team-defaults
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `a21acfb` | 2026-08-14 | Verify before asserting: merge guards, measured contrast ratios, review-finding reproduction (#552) |
| `4a01a79` | 2026-08-03 | fix: replace eight unrunnable ${CLAUDE_PLUGIN_ROOT} Bash commands with bin/ wrappers (#520) |

<!-- generated:end -->

## References

- Plan: [add-team-defaults-plugin.md](plans/add-team-defaults-plugin.md)
- Related docs: `kit/plugins/team-defaults/README.md`
