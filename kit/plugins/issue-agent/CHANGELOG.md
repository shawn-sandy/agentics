# Changelog — issue-agent

## v0.2.3 — 2026-06-05 — Use portable plugin-dir path in README

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/issue-agent` path instead of an author-specific home directory.

---

## v0.2.1 — 2026-06-01 — Add ExitPlanMode error handling

### Fixed

- fix: add ExitPlanMode error handling — treat 'not in plan mode' error as success

## v0.2.0 — 2026-05-31

### Added

- `create-issue` skill Phase 7: after successful issue creation, automatically opens the issue in the browser with `gh issue view <number> --web` / `glab issue view <id> --web`
- `--no-open` invocation flag: pass `--no-open` to suppress browser launch and print only the URL + number (mirrors Vite/Next.js convention)
- Non-fatal browser-open error handling: a failure to open the browser (headless, CI, no display) emits a warning and still prints the issue URL
- `host-commands.md`: new "Issue view" section documenting `gh issue view --web` and `glab issue view --web` for both hosts, with issue-number extraction pattern

## v0.1.1 — README: sync usage documentation with current skill behavior

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## v0.1.0 — 2026-05-28

### Added

- `create-issue` skill: drafts and opens GitHub or GitLab issues from four context sources — selection, session, bug, feature
- Host auto-detection from `git remote get-url origin` (`gh` for GitHub, `glab` for GitLab)
- Confirmation gate before any issue is created; fallback to `--web` on CLI errors
- Reference templates: `bug-report.md`, `feature-request.md`, `general-issue.md`
- `host-commands.md`: `gh` vs `glab` command and flag equivalence table (including `--body` vs `--description` difference)
