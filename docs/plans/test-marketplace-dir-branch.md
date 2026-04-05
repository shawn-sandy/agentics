---
status: draft
branch: refactor/marketplace-dirs
created: 2026-04-05
---

# Test Plan: Marketplace Directory Location (Branch)

## Context

Branch `refactor/marketplace-dirs` has one commit (`9eb536f`) that moves
`marketplace.json` from `.claude-plugin/` (repo root) to `kit/.claude-plugin/`.
The goal is to verify plugins are still discoverable and installable from the
remote GitHub branch with this new location.

**On main:** `.claude-plugin/marketplace.json` at repo root
**On this branch:** `kit/.claude-plugin/marketplace.json` (root `.claude-plugin/` is empty)

## Test Steps

### 1. Push branch (already done)

Branch `refactor/marketplace-dirs` is already pushed to `origin`.

### 2. Test remote marketplace registration (kit/ subtree path)

```bash
# This should find kit/.claude-plugin/marketplace.json
/plugin marketplace add shawn-sandy/agentics/kit

# Verify it appears in the marketplace list
/plugin marketplace list
```

**Expected:** Marketplace `agentics-kit` registers successfully, showing 11 plugins.

### 3. Test remote marketplace registration (repo root — should fail)

```bash
# This looks for .claude-plugin/marketplace.json at repo root — empty on this branch
/plugin marketplace add shawn-sandy/agentics
```

**Expected:** Should fail or find no plugins (root `.claude-plugin/` is empty).

> **Note:** This tests main branch by default. To test this branch specifically,
> Claude Code would need to support branch specification — verify if that's possible.

### 4. Test plugin install from marketplace

```bash
# Pick 2-3 diverse plugins to install
/plugin install code-review@agentics-kit
/plugin install plan-interview@agentics-kit
/plugin install claude-md-optimizer@agentics-kit
```

**Expected:** Each plugin installs and appears in `/plugin list`.

### 5. Test individual plugin loading (local --plugin-dir)

```bash
# Load a few plugins directly to confirm they work independently
claude --plugin-dir ~/devbox/agentics/kit/plugins/code-review \
       --plugin-dir ~/devbox/agentics/kit/plugins/plan-interview
```

**Expected:** Skills auto-activate, commands are available via `/plugin-name:command`.

### 6. Verify skill activation

In the session from step 5, trigger a skill:
- Say "review this code" → should activate `code-review:code-review-agent`
- Say "/plan-interview:plan-interview" → should invoke the command

### 7. Cleanup empty root directory

The root `.claude-plugin/` directory is empty (leftover from the move). If tests
pass with the `kit/` location, this empty directory should be deleted.

## Key Questions

1. **Branch support:** Does `/plugin marketplace add` support specifying a branch?
   If it always pulls `main`, remote testing of this branch requires merging first
   or testing locally with `/plugin marketplace add ~/devbox/agentics/kit`.
2. **Subpath support:** Does `shawn-sandy/agentics/kit` work as a marketplace
   path, or does Claude Code only support repo-root registration?
3. **Empty dir cleanup:** Should we delete the empty root `.claude-plugin/` on
   this branch to avoid confusion?

## Next Steps (out of scope)

- Merge to main if remote kit/ path works correctly
- Update CLAUDE.md marketplace registration commands if path changes
- Consider whether both root and kit/ paths should work (symlink or duplicate)
