# Changelog — issue-agent

## v0.1.1 — README: sync usage documentation with current skill behavior

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## v0.1.0 — 2026-05-28

### Added

- `create-issue` skill: drafts and opens GitHub or GitLab issues from four context sources — selection, session, bug, feature
- Host auto-detection from `git remote get-url origin` (`gh` for GitHub, `glab` for GitLab)
- Confirmation gate before any issue is created; fallback to `--web` on CLI errors
- Reference templates: `bug-report.md`, `feature-request.md`, `general-issue.md`
- `host-commands.md`: `gh` vs `glab` command and flag equivalence table (including `--body` vs `--description` difference)
