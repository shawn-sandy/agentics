---
status: todo
branch: fix/sub-dir
created: 2026-04-05
---

# Fix: git-subdir URLs — SSH to HTTPS

## Context

Plugin installs via `git-subdir` fail with `Permission denied (publickey)` because
Claude Code resolves the `owner/repo` shorthand URL to SSH (`git@github.com:...`).
The repo is public, so HTTPS cloning requires no authentication. Switching to full
HTTPS URLs ensures any marketplace consumer can install without SSH keys.

## Steps

1. **Edit `.claude-plugin/marketplace.json`**
   - Replace all 11 occurrences of `"url": "shawn-sandy/agentics"` with
     `"url": "https://github.com/shawn-sandy/agentics.git"`
   - No other fields change

2. **Validate JSON syntax**
   - The settings.json hook auto-validates on Write/Edit
   - Manually confirm valid JSON with `python3 -m json.tool`

3. **Test plugin install**
   - Register marketplace: `/plugin marketplace add shawn-sandy/agentics`
   - Install one plugin: `/plugin install code-review@agentics-kit`
   - Verify it resolves via HTTPS (no SSH error)

4. **Commit**
   - `fix(marketplace): use HTTPS URLs for git-subdir sources`
   - Include this plan file in the commit

## Files Modified

- `.claude-plugin/marketplace.json` — 11 URL replacements (one per plugin entry)

## Verification

1. Run `python3 -m json.tool .claude-plugin/marketplace.json` — must parse without error
2. Run `/plugin marketplace add shawn-sandy/agentics` — must register successfully
3. Run `/plugin install code-review@agentics-kit` — must install without SSH error
4. Confirm installed plugin works: trigger "review this code" in a test session

## Next Steps (out of scope)

- Investigate whether Claude Code should default to HTTPS for `owner/repo` shorthand (potential upstream issue)
- Consider adding SSH key setup to CONTRIBUTING.md for contributors who prefer SSH
- Update the existing test plan (`docs/plans/test-marketplace-dir-branch.md`) to reflect HTTPS URLs
