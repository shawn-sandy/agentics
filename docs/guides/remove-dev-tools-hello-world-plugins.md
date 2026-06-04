# Remove dev-tools and hello-world Plugins

> Deletes the `hello-world` and `dev-tools` example plugins from the marketplace and removes all documentation references; marketplace version bumped 2.2.0 → 2.3.0.

<!-- generated:start -->

**Status:** Shipped   **Plan:** [remove-dev-tools-hello-world-plugins.md](plans/remove-dev-tools-hello-world-plugins.md)   **Type:** standard

## What shipped

- `plugins/hello-world/` directory deleted (6 files).
- `plugins/dev-tools/` directory deleted (5 files).
- `.claude-plugin/marketplace.json` — both plugin entries removed; marketplace version bumped from `2.2.0` to `2.3.0` (MINOR: removal is internal-only, no external consumers).
- `CLAUDE.md` — both plugins removed from the Reference Implementations table.
- Root `README.md` — hello-world and dev-tools removed from plugin listings and `--plugin-dir` examples.
- `plugins/README.md` — both plugin entries removed.
- `.claude/rules/plugin-patterns.md` — dead pointer to `plugins/dev-tools/skills/code-review/SKILL.md` (line 56) removed or redirected.
- `CLAUDE.local.md` — `--plugin-dir` commands for both plugins removed.
- Root `CHANGELOG.md` — removal entry added.
- `~/.claude/projects/.../memory/MEMORY.md` — stale plugin references removed from Active Plugins, Key Commands, and Detailed Notes sections.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `plugins/hello-world/` | Example plugin — 6 files | Deleted |
| `plugins/dev-tools/` | Example plugin — 5 files | Deleted |
| `.claude-plugin/marketplace.json` | Marketplace registry | Modified (entries removed, version 2.3.0) |
| `CLAUDE.md` | Project instructions | Modified |
| `README.md` | Root documentation | Modified |
| `plugins/README.md` | Plugin directory guide | Modified |
| `.claude/rules/plugin-patterns.md` | Authoring rules | Modified (dead pointer removed) |
| `CLAUDE.local.md` | Local machine config | Modified |
| `CHANGELOG.md` | Root version history | Modified |

## How it works

Both `hello-world` and `dev-tools` were demonstration plugins: `hello-world` showed the basic plugin structure and the command vs. skill distinction; `dev-tools` demonstrated multi-skill plugins with optional external dependencies (Prettier, Black). With the other reference implementations in the marketplace providing richer and more realistic examples, these two were redundant and were removing clutter from the marketplace listing.

The marketplace version bump follows MINOR semantics (2.3.0) rather than MAJOR: the plugins were internal-only reference implementations with no external consumers, so no downstream users were broken by the removal.

The dead pointer in `.claude/rules/plugin-patterns.md` — a reference to `plugins/dev-tools/skills/code-review/SKILL.md` as a progressive disclosure example — was the primary operational risk: leaving it would have created a misleading broken link in the authoring rules. It was removed as part of this plan.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |

<!-- generated:end -->

## References

- Plan: [remove-dev-tools-hello-world-plugins.md](plans/remove-dev-tools-hello-world-plugins.md)
- Related: [create-hello-world-testing-docs.md](create-hello-world-testing-docs.md)
