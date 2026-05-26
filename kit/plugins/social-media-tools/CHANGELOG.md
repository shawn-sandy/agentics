# Changelog — social-media-tools

## v0.2.0 — 2026-05-26

Added discovery and security-scrub layer upstream of the `code-share` skill.

- `scan-for-shares` skill: discovers shareable commits or codebase patterns in two modes — history mode (`git log` on current branch) and codebase mode (`--codebase <path>`); scores candidates, runs security scrub, presents multi-select review gate, writes `.claude/digests/code-digest-YYYY-MM-DD.md`
- `security-scrub` skill: standalone secret/credential scanner; detects HIGH/MEDIUM/LOW patterns across 20+ categories; masks values before reporting; emits structured `SCRUB RESULT` block for callers
- `/code-share:digest` command: interactive front-end for `scan-for-shares`
- `/code-share:digest-bg` command: fire-and-forget background variant via `agent-digest`
- `agent-digest` background agent: runs digest scan without user interaction; proactively reports output path on completion
- Scheduling note: GitHub Actions / cron / Claude routines can run `digest-bg` on a schedule; human review always required before posting

## v0.1.0 — 2026-05-26

Initial release.

- `code-share` skill: draft platform-aware copy for LinkedIn, Twitter/X, and Bluesky
- Three dark-mode HTML card templates: `diff-card`, `feature-card`, `quote-card`
- Playwright-based screenshot pipeline with automatic port selection
- Fallback message with HTML path when Playwright screenshot is unavailable
- `find_free_port.py` helper script to avoid port collisions
