# Fix lint-gate defects

> The lint-before-commit hook had four defects that caused it to never run for any installed user: missing `"hooks"` key registration, no baseline comparison, root-only package walk, and no non-Node detection. All four are fixed.

<!-- generated:start -->

**Status:** Shipped 2026-08-10 **Plan:** [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
**Type:** feature

## What shipped

- Fixed `hooks/lint-before-commit.py`: (1) baseline comparison so only new lint failures block a commit — pre-existing failures don't prevent shipping; (2) nearest-package walk instead of root-only, so monorepos find the right `package.json`/`eslint.config.*`; (3) non-Node detection via `pyproject.toml`, `go.mod`, and `Cargo.toml` — the hook skips gracefully for Python, Go, and Rust projects instead of erroring.
- Fixed `hooks/hooks.json`: added explicit `"hooks": "./hooks.json"` key; without it, the hook engine never registered the hooks module for any installed user. Timeout raised from 200 s to 480 s to accommodate slow monorepo lint runs.
- Added the `"hooks": "./hooks.json"` key to `plugin.json` for `git-agent`, `plan-agent`, and `skill-reviewer` — the same omission affected all three.
- Extended `tests/plugins/test-lint-before-commit.sh` to over 38 checks covering all four fixes plus regression cases.
- Updated `README.md` with the hooks registration note; updated `CHANGELOG.md`.
- Bumped git-agent to 4.14.0; also patched `plan-agent` and `skill-reviewer` for the `plugin.json` fix.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/hooks/lint-before-commit.py` | Four defects fixed | Modified |
| `kit/plugins/git-agent/hooks/hooks.json` | Explicit key + timeout 480 s | Modified |
| `kit/plugins/git-agent/.claude-plugin/plugin.json` | `"hooks"` key added | Modified |
| `kit/plugins/plan-agent/.claude-plugin/plugin.json` | `"hooks"` key added | Modified |
| `kit/plugins/skill-reviewer/.claude-plugin/plugin.json` | `"hooks"` key added | Modified |
| `tests/plugins/test-lint-before-commit.sh` | 38+ checks, all four fixes | Modified |
| `kit/plugins/git-agent/README.md` | Hooks registration note | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | 4.14.0 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent 4.14.0 + patches | Modified |

## How it works

**Defect 1 — hooks never registered**: The hook engine looks for a `"hooks": "<path>"` key in `plugin.json` to know which hooks module to load. Without it, the engine silently skips the plugin's hooks directory. Every plugin with a `hooks/` directory now carries the explicit key.

**Defect 2 — baseline comparison**: The hook now runs lint twice — once on the base ref (the last committed state) and once on the working tree. Only failures that appear in the working tree but not the base ref are reported as blockers. Pre-existing lint debt does not block commits.

**Defect 3 — monorepo package walk**: The hook previously used `process.cwd()` as the package root. It now walks up from each changed file's directory until it finds a `package.json` or an eslint config, so a monorepo with lint configs at multiple levels resolves the correct one per file.

**Defect 4 — non-Node projects**: The hook checks for `pyproject.toml`, `go.mod`, or `Cargo.toml` before attempting to run lint. If a non-Node marker is found and no `package.json` exists, the hook exits 0 with a "non-Node project detected, skipping" message.

## How to use it

The fixes apply automatically for anyone with git-agent installed. No reinstall needed after a marketplace update.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| — | 2026-08-10 | fix(git-agent): lint-gate defects — hooks registration, baseline comparison, monorepo walk, non-Node skip (4.14.0) (#543) |

<!-- generated:end -->

## References

- Plan: [fix-lint-gate-defects.md](plans/fix-lint-gate-defects.md)
