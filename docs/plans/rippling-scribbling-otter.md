
# Plan: Create `.claude.md.local` for Machine-Specific Content

## Context

After optimizing `CLAUDE.md`, machine-specific content (canonical path, full plugin-loading commands) was removed and should live in a gitignored `.claude.md.local` file. This file is per-developer and never committed — it lets individuals add local overrides without modifying the shared `CLAUDE.md`.

## Steps

1. **Create `.claude.md.local`** at `/Users/shawnsandy/devbox/agentics/.claude.md.local`
   - Include canonical path: `~/devbox/agentics`
   - Include the full multi-plugin `claude --plugin-dir` loading command for all 5 plugins

2. **Add `.claude.md.local` to `.gitignore`**
   - Append `# Claude Code local overrides` + `.claude.md.local` to `/Users/shawnsandy/devbox/agentics/.gitignore`

3. **Fix markdownlint warnings in `CLAUDE.md`** introduced during optimization:
   - Line 10: Add blank line before numbered list
   - Line 22: Add language specifier to fenced code block (`text` or `plaintext`)
   - Line 57: Add blank line before list

4. **Commit** — include this plan file per project conventions
   - Message: `feat(claude-md): add .claude.md.local for machine-specific overrides`

## Files

| File | Action |
|------|--------|
| `.claude.md.local` | Create (new, gitignored) |
| `.gitignore` | Edit — append `.claude.md.local` entry |
| `CLAUDE.md` | Edit — fix 3 markdownlint warnings |
| `docs/plans/rippling-scribbling-otter.md` | This file |

## Verification

- `cat .claude.md.local` — confirms content is present
- `git status` — confirms `.claude.md.local` does NOT appear as a tracked file
- `git check-ignore -v .claude.md.local` — confirms it is gitignored
